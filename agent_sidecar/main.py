"""Sidecar: Yandex completion API + инструмент search_masterclasses -> GET /mclist."""
from __future__ import annotations
import ast
import json
import os
import re
import logging
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from .intent_mappings import get_mappings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BACKEND_URL = os.environ.get("BACKEND_URL", "http://localhost:80").rstrip("/")
YANDEX_API_KEY = os.environ.get("YANDEX_AI_API_KEY", "")
YANDEX_FOLDER_ID = os.environ.get("YANDEX_FOLDER_ID", "")
YANDEX_MODEL_URI = os.environ.get("YANDEX_MODEL_URI", "")
YANDEX_COMPLETION_URL = os.environ.get(
    "YANDEX_COMPLETION_URL",
    "https://llm.api.cloud.yandex.net/foundationModels/v1/completion",
)
SIDECAR_PORT = int(os.environ.get("SIDECAR_PORT", "5000"))

SEARCH_MASTERCLASSES_TOOL = {
    "function": {
        "name": "search_masterclasses",
        "description": (
            "Поиск в базе мастер-классов (GET /mclist). Ты сам выбираешь параметры по правилам из системного промпта: "
            'какой category соответствует теме пользователя, какие поля опустить, если "неважно". '
            "Возвращает JSON с masterclasses (id, title, price, event_date, ...)."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "n": {"type": "integer", "description": "Сколько записей вернуть (1-10).", "default": 3},
                "offset": {"type": "integer", "description": "Смещение для пагинации.", "default": 0},
                "category": {
                    "type": "string",
                    "description": (
                        "Токен(ы) category как в data.csv / БД - см. SYSTEM_PROMPT. "
                        "Один токен или несколько через запятую (ИЛИ): cooking_baking, photography, ... "
                        'Не передавай поле, если тема не важна / "любая тема".'
                    ),
                },
                "audience": {
                    "type": "string",
                    "description": "Один из: adults, kids, families, teens, corporate, date_couple, hobbyists, professionals - только если пользователь явно про аудиторию.",
                },
                "tags": {"type": "string", "description": "Доп. теги через запятую (как в additional_tags в БД). Без городов."},
                "format": {
                    "type": "string",
                    "description": "Только если пользователь **сам** сказал online или offline. Не спрашивай про формат; иначе опусти.",
                },
                "event_date_from": {
                    "type": "string",
                    "description": "Нижняя граница даты проведения МК **включительно**, строго YYYY-MM-DD. Вместе с event_date_to задаёт период.",
                },
                "event_date_to": {
                    "type": "string",
                    "description": "Верхняя граница даты проведения МК **включительно**, строго YYYY-MM-DD. Один день = обе границы одинаковые.",
                },
                "company": {"type": "string", "description": "Тип компании, например single."},
                "min_age": {
                    "type": "integer",
                    "description": "Возраст участника (лет). Подбираются события, куда подходит этот возраст (в базе у события поле min_age - минимальный возраст входа; передай свой возраст).",
                },
                "min_price": {"type": "number", "description": "Минимальная цена (руб)."},
                "max_price": {"type": "number", "description": "Максимальная цена (руб)."},
                "min_rating": {"type": "number", "description": "Минимальный рейтинг."},
                "exclude_ids": {"type": "string", "description": "ID уже показанных мастер-классов через запятую."},
                "sort_order": {
                    "type": "string",
                    "enum": ["date_asc", "date_desc"],
                    "description": "Сортировка по дате проведения; при фильтре по датам обычно date_asc.",
                },
            },
            "required": [],
        },
    }
}

SYSTEM_PROMPT = """Ты помощник по подбору мастер-классов. Общайся на "ты". Язык: по умолчанию русский; если пользователь пишет по-английски - отвечай по-английски.

=== Текст для пользователя (чат в приложении) ===
Во всех сообщениях, которые видит пользователь, пиши только обычный текст без разметки: не используй Markdown, HTML и аналоги - никаких звёздочек или подчёркиваний для жирного или курсива, обратных кавычек для кода, решёток для заголовков, зачёркивания, разметки ссылок в квадратных скобках с круглыми. Такой синтаксис в приложении отображается некорректно. Допустимы только обычные русские кавычки "ёлочки" вокруг названий мастер-классов.

Сначала уточни, что пользователь ищет: **тема**, **когда** хочет пойти (даты или период), **бюджет**, **возраст** при необходимости. Про **город** можно спросить только для контекста в тексте - в API город не фильтруется, **не** подставляй город в tags.
**Не задавай** отдельный вопрос "онлайн или офлайн"; параметр format передавай **только** если пользователь **сам** назвал формат.
Когда информации достаточно - сразу вызови инструмент search_masterclasses (не пиши "ищу" или "подожди" без вызова инструмента в том же ходе).

=== Как заполнять search_masterclasses ===
- В JSON вызова функции указывай **только значения**: числа и короткие строки. Нельзя подставлять описания полей из схемы (`type`, `description`, `default`) - только сами параметры, например `"n": 3`, `"max_price": 3000`.
- Передавай только те параметры, которые явно следуют из реплик пользователя или из диалога. Не угадывай.
- Если пользователь сказал, что ему **неважно** что-то конкретное (тема, формат, цена, возраст и т.д.) - **не передавай** соответствующее поле: это расширяет поиск.
- Если ты задал уточняющий вопрос, а пользователь **не ответил** по сути (только "давай", "покажи" без цифр/формата/темы) - **не передавай** этот параметр; ищи без него.
- **category** - один или несколько токенов из словаря ниже **через запятую** (в БД это логическое ИЛИ: подойдёт любая из тем). Пример: `cooking_baking,photography`. Если "любая тема" / нет предпочтений по теме - **не передавай category**.
- **min_age** - возраст участника в годах, если пользователь назвал или явно про возрастной допуск.
- Город в выдаче через API не фильтруется - **не пихай название города в tags**. Можно упомянуть город в тексте ответа пользователю, если он сам его назвал.

=== Словарь category (тема мастер-класса в БД) ===
Те же строки хранятся в Postgres и в импорте. Пользователь просит сразу две темы - передай **два токена через запятую**. Если смысл на стыке - можно один токен или уточнить вопрос.

- **cooking_baking** - готовка, кулинария, выпечка, кондитерка, шоколад, торты, кухня, рецепты; food styling, если про еду.
- **dance_performance** - танцы, балет, contemporary, хореография, сценическое движение (если не чистый фитнес).
- **music** - музыка, вокал, инструменты, DJ, звук, саунд.
- **drawing_painting** - рисование, живопись, иллюстрация, скетчинг, акварель, масло, художественная графика.
- **design** - дизайн интерьера/графики/продукта, брендинг, типографика (не путать с "картины маслом" - там drawing_painting).
- **craft_maker** - рукоделие, DIY, керамика, текстиль, свечи, мыло, декор своими руками.
- **tech_coding** - IT, программирование, нейросети и ИИ в творчестве, 3D, геймдев, робототехника, цифровые продукты (токен как в импорте).
- **photography** - фото, видео, монтаж, операторское, свет (токен как в импорте; не путать с синонимом photo_video - в БД именно photography).
- **wellness_sport** - йога, пилатес, медитация, здоровье, спорт, фитнес (акцент на теле/здоровье, не танец).
- **theater_cinema** - театр как искусство, актёрское мастерство, кино, сценическая речь, драма.
- **beauty_fashion** - парфюмерия, ароматы, макияж, бьюти, мода, уход (если не "свечи своими руками" - тогда craft_maker).
- **home_garden** - флористика, комнатные растения, венки из зелени, декор с растениями, "дом и сад".
- **personal_dev** - стендап и комедия как навык, ораторика, работа с голосом, софт-скилы, личностный рост (не спектакль - тогда theater_cinema).

=== Даты (event_date_from, event_date_to) ===
Бэкенд фильтрует по **дате проведения** мастер-класса (колонка event_date). Передавай границы **включительно** только как **YYYY-MM-DD**.
- В конце системного промпта указана **сегодняшняя дата** - от неё считай "завтра", "послезавтра", "в эти выходные", "на следующей неделе", "15 марта", "до конца месяца", "в апреле" и т.п.
- **Один день**: одинаковые event_date_from и event_date_to.
- **Период**: from <= to; если пользователь назвал только конец периода - from можно взять как сегодня или начало месяца по смыслу.
- Если даты **неважны**, пользователь не ответил на вопрос про сроки или сказал "любой день" - **не передавай** event_date_from / event_date_to (поиск по всем датам).
- Мастер-классы **без даты** в базе при активном фильтре по датам **не попадут** в выдачу - это нормально.
- Когда фильтруешь по датам, чаще ставь **sort_order**: **date_asc** (сначала ближайшие).

=== Другие поля ===
- **audience**: adults | kids | families | teens | corporate | date_couple | hobbyists | professionals - только если явно "для кого".
- **format**: online или offline - **только** если пользователь **сам** это сказал; **не** спрашивай формат первым.
- **max_price** / **min_price** - если обсуждали бюджет (рубли).
- **min_rating** - если просят высокий рейтинг.
- **tags** - доп. теги через запятую, как в базе; без городов.
- **n** - сколько записей запросить (разумно 3-10).

После ответа инструмента предложи 1-3 мастер-класса **только из результата инструмента** - **кратко** (название в "ёлочках", цена, дата; без длинного описания и без контактов, пока пользователь сам не попросит). Если returned=0 - скажи, что не найдено.

=== Как оформлять список в ответе пользователю (важно для приложения) ===
- Сначала можно **короткое вступление** в одну-две строки (например "Вот пара подходящих..."), затем **пустая строка** (двойной перенос).
- Каждый мастер-класс - **отдельный абзац** (между вариантами тоже **пустая строка**).
- **Первая строка каждого абзаца** - **точное название из поля title** в JSON, в **"ёлочках"**: **"..."** (как в базе, без перефразирования).
- **Дальше только кратко:** одна строка с **ценой** (из поля price), одна строка с **датой** (event_date, как в JSON или "дата уточняется", если пусто).
- **Запрещено** в таком сообщении подборки: длинное описание из **description**, "почему подходит" развёрнутым текстом, блок **"Контакты для записи"**, списки сайта/Telegram/VK/телефона/места - в приложении под абзацем уже есть фото и кнопка **"Открыть карточку"** со всеми деталями.
- Контакты и способ записи выводи **только** если пользователь **отдельно** спросил про запись, телефон, сайт, Telegram, VK (см. блок "Контакты" ниже).

Запрещено в ответе пользователю: теги вроде [search_masterclasses], любой сырой JSON целиком (в том числе массивы с фигурными скобками), пустые служебные фразы на английском в русскоязычном диалоге, а также оформление текста разметкой (см. блок "Текст для пользователя" выше). Список мастер-классов - только связным текстом на русском.
Если просят "ещё" / "другие" - снова вызови инструмент; sidecar сам добавит в exclude_ids id уже показанных в этом чате вариантов, чтобы не повторять их.

=== Контакты и запись (важно) ===
В каждой записи массива **masterclasses** в JSON ответа инструмента уже есть: **website**, **organizer**, **location**, **contact_tg**, **contact_vk**, **contact_phone** (часть полей может быть пустой строкой - тогда так и скажи по этому полю).
- Если пользователь просит **контакты**, **телефон**, **сайт**, **Telegram**, **VK**, **как записаться** - возьми значения **из последнего успешного JSON инструмента** в переписке для выбранного мастер-класса (по названию/id) и **перечисли их в ответе**.
- **Категорически запрещено** отвечать, что у тебя "нет доступа к контактам" или "не могу показать" - эти данные передаются инструментом; не выдумывай и не подменяй общими советами "поищи на сайтах".
- Если в контексте диалога уже нет текста с результатом поиска (обрезка истории) - **снова вызови search_masterclasses** с теми же смысловыми фильтрами, найди ту же запись и ответь контактами из нового JSON.
- Не обещай "помогу найти контакты позже", если можешь вывести их из полей JSON сейчас."""


def _system_prompt_with_calendar() -> str:
    from datetime import date

    today = date.today().isoformat()
    return (
        SYSTEM_PROMPT
        + f"\n\n### Календарь (обновляется на каждый запрос)\n**Сегодняшняя дата:** {today}.\n"
        "Используй её, чтобы переводить словесные даты пользователя в **event_date_from** / **event_date_to** (YYYY-MM-DD).\n"
    )


_ISO_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def _is_blank_query_value(v: Any) -> bool:
    if v is None:
        return True
    s = str(v).strip()
    if not s:
        return True
    return s.lower() in ("none", "null", "undefined")


def call_mclist(params: dict[str, Any]) -> dict[str, Any]:
    query = {k: v for k, v in params.items() if not _is_blank_query_value(v)}
    try:
        with httpx.Client(timeout=30.0) as client:
            r = client.get(f"{BACKEND_URL}/mclist", params=query)
            r.raise_for_status()
            return r.json()
    except httpx.HTTPError as e:
        logger.exception("GET /mclist failed: %s", e)
        return {"returned": 0, "masterclasses": [], "error": "backend_http_error"}
    except ValueError as e:
        logger.exception("GET /mclist invalid JSON: %s", e)
        return {"returned": 0, "masterclasses": [], "error": "invalid_response_json"}


_CITY_TAG_DROP = re.compile(
    r"(?i)москв|moscow|спб|петербург|санкт|новосиб|екатеринбург|казань|нижний",
)


def _looks_like_tool_schema_leak(val: Any) -> bool:
    if isinstance(val, dict):
        keys = {str(k).lower() for k in val}
        if "type" in keys and ("description" in keys or "enum" in keys or "default" in keys):
            return True
    if isinstance(val, str):
        s = val.strip()
        if s.startswith("{") and ("type" in s and ("description" in s or "'description'" in s)):
            return True
    return False


def _try_parse_stringified_dict(s: str) -> dict[str, Any] | None:
    s = s.strip()
    if not s.startswith("{"):
        return None
    try:
        obj = json.loads(s)
        return obj if isinstance(obj, dict) else None
    except json.JSONDecodeError:
        try:
            obj = ast.literal_eval(s)
            return obj if isinstance(obj, dict) else None
        except (ValueError, SyntaxError, TypeError):
            return None


def _extract_scalar_from_schema_leak(v: Any) -> tuple[Any, bool]:
    def _from_prop_dict(d: dict[str, Any]) -> tuple[Any, bool]:
        if "default" in d:
            inner = d.get("default")
            if inner is None:
                return v, False
            if isinstance(inner, dict) and _looks_like_tool_schema_leak(inner):
                return v, False
            return inner, True
        en = d.get("enum")
        if isinstance(en, list) and len(en) == 1:
            return en[0], True
        return v, False

    if isinstance(v, dict) and _looks_like_tool_schema_leak(v):
        return _from_prop_dict(v)
    if isinstance(v, str):
        parsed = _try_parse_stringified_dict(v)
        if isinstance(parsed, dict) and _looks_like_tool_schema_leak(parsed):
            return _from_prop_dict(parsed)
    return v, False


def _to_int(v: Any) -> int | None:
    """Coerce to int, rejecting bools, blanks, and schema leaks."""
    if isinstance(v, bool) or _looks_like_tool_schema_leak(v):
        return None
    if isinstance(v, int):
        return v
    if isinstance(v, float):
        return int(v)
    if isinstance(v, str):
        s = v.strip()
        if _is_blank_query_value(s) or s.startswith("{"):
            return None
        try:
            return int(float(s))
        except ValueError:
            return None
    return None


def _to_float(v: Any) -> float | None:
    """Coerce to float, rejecting bools, blanks, and schema leaks."""
    if isinstance(v, bool) or _looks_like_tool_schema_leak(v):
        return None
    if isinstance(v, (int, float)):
        return float(v)
    if isinstance(v, str):
        s = v.strip().replace(",", ".")
        if _is_blank_query_value(s) or s.startswith("{"):
            return None
        try:
            return float(s)
        except ValueError:
            return None
    return None


def _to_str(v: Any) -> str | None:
    """Coerce to str, rejecting dicts, lists, blanks, and schema leaks."""
    if _looks_like_tool_schema_leak(v) or isinstance(v, (dict, list)):
        return None
    s = str(v).strip()
    if _is_blank_query_value(s) or _looks_like_tool_schema_leak(s):
        return None
    return s


def _sanitize_search_masterclasses_args(args: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(args, dict):
        return {}

    # First pass: recover scalars from schema-leaked dicts (Yandex GPT bug).
    work: dict[str, Any] = {}
    for k, v in args.items():
        u, did = _extract_scalar_from_schema_leak(v)
        if did:
            logger.info("search_masterclasses: recovered scalar for %s from schema-like value", k)
        work[k] = u

    out: dict[str, Any] = {}

    # Integers with bounds.
    for key, lo in [("n", 1), ("offset", 0), ("min_age", 0)]:
        val = _to_int(work.get(key))
        if val is not None and val >= lo and (key != "n" or val <= 100):
            out[key] = val

    # Floats (non-negative).
    for key in ("min_price", "max_price", "min_rating"):
        val = _to_float(work.get(key))
        if val is not None and val >= 0:
            out[key] = val

    # Strings.
    for key in ("category", "audience", "tags", "format", "company", "exclude_ids"):
        val = _to_str(work.get(key))
        if val is not None:
            out[key] = val

    # ISO dates.
    for key in ("event_date_from", "event_date_to"):
        val = _to_str(work.get(key))
        if val is not None and _ISO_DATE_RE.match(val):
            out[key] = val

    # Swap reversed dates.
    df, dt = out.get("event_date_from"), out.get("event_date_to")
    if isinstance(df, str) and isinstance(dt, str) and df > dt:
        out["event_date_from"], out["event_date_to"] = dt, df

    # Sort order (enum).
    so = _to_str(work.get("sort_order"))
    if so in ("date_asc", "date_desc"):
        out["sort_order"] = so

    return out


def _recent_user_text(messages: list[dict], max_chunks: int = 5) -> str:
    chunks: list[str] = []
    for m in messages:
        if m.get("role") != "user":
            continue
        t = (m.get("content") or m.get("text") or "").strip()
        if t:
            chunks.append(t)
    return "\n".join(chunks[-max_chunks:])


def _last_user_message(messages: list[dict]) -> str:
    """Most recent user message only (for broad-search / no-preference detection)."""
    for m in reversed(messages):
        if m.get("role") == "user":
            return (m.get("content") or m.get("text") or "").strip()
    return ""


def _prior_assistant_text(messages: list[dict]) -> str:
    """Assistant message immediately before the last user message (the clarifying question)."""
    last_user_idx: int | None = None
    for i in range(len(messages) - 1, -1, -1):
        if messages[i].get("role") == "user":
            last_user_idx = i
            break
    if last_user_idx is None:
        return ""
    for j in range(last_user_idx - 1, -1, -1):
        if messages[j].get("role") == "assistant":
            return (messages[j].get("content") or messages[j].get("text") or "").strip()
    return ""


def _user_blob_has_price(blob: str) -> bool:
    if re.search(r"\d{3,5}", blob):
        return True
    return bool(
        re.search(r"(?i)(тысяч|сотен|руб|рубл|rub|usd|\$|pounds?)", blob)
    )


def _user_blob_has_age(blob: str) -> bool:
    return bool(
        re.search(r"(?i)\b(?:[1-9]\d?|100)\s*(?:лет|год|года|years?\s+old)\b", blob)
        or re.search(r"(?i)(?:мне|мне\s+)\s*(?:[1-9]\d?|100)\b", blob)
        or re.search(r"(?i)\b(?:i\s*am|i'?m)\s*(?:[1-9]\d?|100)\b", blob)
        or re.search(r"(?i)\bage\s*[:is]?\s*(?:[1-9]\d?|100)\b", blob)
    )


def _user_blob_has_cuisine_theme(blob: str) -> bool:
    return bool(
        re.search(
            r"(?i)(кулинар|кухн|выпечк|рецепт|готов|печь|десерт|итальян|азиат|еда\b|"
            r"cooking|baking|kitchen|recipe|cuisine|food\b)",
            blob,
        )
    )


def _user_blob_has_date_preference(blob: str) -> bool:
    """User gave something we can treat as a date signal (ISO, numeric date, or common RU phrases)."""
    if re.search(r"\b20\d{2}-\d{2}-\d{2}\b", blob):
        return True
    if re.search(r"\b\d{1,2}[./]\d{1,2}[./]\d{2,4}\b", blob):
        return True
    return bool(
        re.search(
            r"(?i)(завтра|послезавтра|сегодня|на\s+выходных|в\s+суббот|в\s+воскресен|"
            r"следующ(ей|ую|ие)\s+недел|в\s+(?:понедельник|вторник|среду|четверг|пятниц)|"
            r"январ|феврал|март|апрел|ма[ей]|июн|июл|август|сентябр|октябр|ноябр|декабр|"
            r"tomorrow|next\s+week|weekend|this\s+weekend)",
            blob,
        )
    )


_CLARIFICATION_RULES: list[tuple[str, Any, list[str]]] = [
    # (regex on assistant question, user-answer detector, keys to drop)
    (
        r"(?i)(бюджет|сколько\s+готов|цен|стоим|лимит|до\s+скольки|сколько\s+денег|"
        r"budget|price\s+range|how\s+much)",
        _user_blob_has_price,
        ["max_price", "min_price"],
    ),
    (
        r"(?i)(возраст|сколько\s+тебе\s+лет|лет\s+тебе|сколько\s+лет|"
        r"\bage\b|how\s+old|years?\s+old)",
        _user_blob_has_age,
        ["min_age"],
    ),
    (
        r"(?i)(когда\s+(?:ты\s+)?(?:хотел|хочешь|планир|удобн)|"
        r"желаем(ые)?\s+дат|в\s+как(ие|ой)\s+дн|на\s+как(ую|ие)\s+дат|"
        r"как(ой|ие)\s+дат|в\s+какой\s+период|за\s+как(ие|ой)\s+срок|"
        r"when\s+do\s+you\s+want|preferred\s+date|which\s+date)",
        _user_blob_has_date_preference,
        ["event_date_from", "event_date_to"],
    ),
    (
        r"(?i)(кухн|кулинар|блюд|выпечк|рецепт|тип\s+ед|предпочтен.*кухн|"
        r"cuisine|dishes?|cooking|baking|food\s+preference)",
        _user_blob_has_cuisine_theme,
        ["category"],
    ),
]


def _apply_unanswered_clarification_filters(full_messages: list[dict], args: dict[str, Any]) -> dict[str, Any]:
    """Drop filters the bot asked about but the user never answered."""
    out = dict(args)
    prior_a = _prior_assistant_text(full_messages)
    if not prior_a:
        return out

    last_u = _last_user_message(full_messages)
    blob = _recent_user_text(full_messages, max_chunks=10)

    for question_re, user_answered_fn, keys in _CLARIFICATION_RULES:
        if not re.search(question_re, prior_a):
            continue
        if user_answered_fn(blob) or user_answered_fn(last_u):
            continue
        dropped = [k for k in keys if out.pop(k, None) is not None]
        if dropped:
            logger.info("Dropped %s: user did not answer clarification", dropped)

    return out


def _merge_query_hints_from_user(args: dict[str, Any], user_blob: str) -> dict[str, Any]:
    """Optional YAML fallback: intent_mappings + aliases when the model omitted params."""
    return get_mappings().infer_from_user_text(user_blob, args)


def _parse_mclist_json_from_tool_content(content: str) -> dict[str, Any] | None:
    """Extract GET /mclist JSON object from a tool message (prefix text + json.dumps)."""
    if not content or not isinstance(content, str):
        return None
    pos = content.find('"returned"')
    if pos == -1:
        pos = content.find('"masterclasses"')
    if pos == -1:
        return None
    start = content.rfind("{", 0, pos)
    if start == -1:
        return None
    blob = content[start:].strip()
    try:
        return json.loads(blob)
    except json.JSONDecodeError:
        return None


def _parse_last_tool_mclist_json(messages: list[dict]) -> dict[str, Any] | None:
    """Last successful GET /mclist JSON from a prior tool message (same chat)."""
    for m in reversed(messages):
        if m.get("role") != "tool":
            continue
        raw = m.get("content") or m.get("text") or ""
        if not isinstance(raw, str):
            continue
        data = _parse_mclist_json_from_tool_content(raw)
        if not isinstance(data, dict) or data.get("error"):
            continue
        if int(data.get("returned") or 0) <= 0:
            continue
        mcs = data.get("masterclasses") or []
        if isinstance(mcs, list) and mcs:
            return data
    return None


def _user_asks_contacts_or_selection(phrase: str) -> bool:
    if not phrase or not str(phrase).strip():
        return False
    pl = phrase.lower()
    if re.search(
        r"контакт|телефон|тел\.|позвонить|написать\s+в|сайт|записаться|запись|запиш|"
        r"telegram|телеграм|^tg\b|\btg:|вконтакт|в\s+vk|@",
        pl,
    ):
        return True
    if re.search(
        r"выбираю|беру|возьму|хочу\s+этот|этот\s+вариант|остановлюсь\s+на|нравится\s+этот|"
        r"дай\s+контакт|покажи\s+контакт",
        pl,
    ):
        return True
    return False


def _filter_masterclasses_by_user_hint(mcs: list[Any], phrase: str) -> list[Any]:
    """Narrow list when user names a variant (e.g. "Название" or distinctive words in title)."""
    if not phrase.strip() or not mcs:
        return []
    m = re.search(r'\u00ab([^\u00bb]{3,80})\u00bb', phrase)
    if m:
        needle = m.group(1).strip().lower()
        hit = [
            x
            for x in mcs
            if isinstance(x, dict) and needle in (x.get("title") or "").lower()
        ]
        if hit:
            return hit
    words = re.findall(r"[а-яёa-z]{4,}", phrase.lower())
    skip = {
        "мастер", "класс", "классы", "мастер-класс", "мастер класс",
        "хочу", "этот", "вариант", "контакт", "контакты", "телефон",
        "покажи", "скинь", "дай", "записаться", "запись", "нужны",
        "мне", "выбираю", "беру", "возьму",
    }
    words = [w for w in words if w not in skip]
    if len(words) < 1:
        return []
    hit: list[Any] = []
    for x in mcs:
        if not isinstance(x, dict):
            continue
        t = (x.get("title") or "").lower()
        if any(w in t for w in words):
            hit.append(x)
    return hit


def _reuse_previous_tool_results_if_contact_followup(
    full_messages: list[dict],
    last_user_message: str,
    result_data: dict[str, Any],
) -> dict[str, Any]:
    """
    If a new search returns 0 rows but the user clearly asks for contacts or picks a variant
    after we already showed masterclasses, reuse the last non-empty tool JSON from this chat.
    """
    if not isinstance(result_data, dict) or result_data.get("error"):
        return result_data
    if int(result_data.get("returned") or 0) > 0:
        return result_data
    if not _user_asks_contacts_or_selection(last_user_message):
        return result_data
    prev = _parse_last_tool_mclist_json(full_messages)
    if not prev:
        return result_data
    mcs = list(prev.get("masterclasses") or [])
    if not mcs:
        return result_data
    narrowed = _filter_masterclasses_by_user_hint(mcs, last_user_message)
    use = narrowed if narrowed else mcs[:10]
    out: dict[str, Any] = {
        "returned": len(use),
        "masterclasses": use,
        "reuse_from_previous_search_in_chat": True,
    }
    logger.info(
        "Contact/selection follow-up: empty new search; reusing %s row(s) from last tool JSON",
        len(use),
    )
    return out


def _collect_shown_masterclass_ids(messages: list[dict]) -> list[int]:
    """All masterclass ids returned in previous search_masterclasses tool rounds (this chat)."""
    seen: set[int] = set()
    for m in messages:
        if m.get("role") != "tool":
            continue
        raw = m.get("content") or m.get("text") or ""
        data = _parse_mclist_json_from_tool_content(raw if isinstance(raw, str) else "")
        if not isinstance(data, dict):
            continue
        for row in data.get("masterclasses") or []:
            if not isinstance(row, dict):
                continue
            mid = row.get("id")
            if mid is None:
                continue
            try:
                seen.add(int(mid))
            except (TypeError, ValueError):
                continue
    return sorted(seen)


def _apply_exclude_ids_from_history(
    args: dict[str, Any],
    messages: list[dict],
    client_shown_ids: list[int] | None = None,
) -> None:
    """Union exclude_ids: model + ids from tool JSON in this request + client echo (cross-request)."""
    shown = set(_collect_shown_masterclass_ids(messages))
    if client_shown_ids:
        for x in client_shown_ids:
            try:
                shown.add(int(x))
            except (TypeError, ValueError):
                pass
    if not shown:
        return
    existing: set[int] = set()
    ex = args.get("exclude_ids")
    if isinstance(ex, str) and ex.strip():
        for part in ex.split(","):
            p = part.strip()
            if p.isdigit():
                existing.add(int(p))
    elif isinstance(ex, (list, tuple)):
        for x in ex:
            try:
                existing.add(int(x))
            except (TypeError, ValueError):
                pass
    merged = existing | shown
    args["exclude_ids"] = ",".join(str(i) for i in sorted(merged))
    logger.info(
        "exclude_ids: merged %d ids from history+client (total excluded: %d)",
        len(shown),
        len(merged),
    )


def _cumulative_shown_ids(
    client_shown_ids: list[int] | None,
    full_messages: list[dict],
) -> list[int]:
    """All masterclass ids to remember for the next request (client echo + tool JSON in this turn)."""
    from_tools = set(_collect_shown_masterclass_ids(full_messages))
    base = set(client_shown_ids or []) | from_tools
    return sorted(base)


def _with_shown(
    reply: str,
    full_messages: list[dict],
    client_shown_ids: list[int] | None,
    masterclasses_preview: list[dict[str, Any]] | None = None,
) -> tuple[str, list[dict], list[int], list[dict[str, Any]]]:
    """Also returns up to 5 full /mclist rows for the client (images + open card)."""
    prev: list[dict[str, Any]] = []
    for x in masterclasses_preview or []:
        if isinstance(x, dict):
            prev.append(dict(x))
    return reply, full_messages, _cumulative_shown_ids(client_shown_ids, full_messages), prev


def _had_tool_result_recently(messages: list[dict], lookback: int = 24) -> bool:
    for m in messages[-lookback:]:
        if m.get("role") == "tool":
            return True
    return False


def _looks_like_mc_recommendations_without_tool(text: str) -> bool:
    """Concrete listings with RUB prices - must only appear after a tool JSON result."""
    if not text or len(text) < 35:
        return False
    has_price = bool(re.search(r"\d{3,5}\s*(руб|₽)|₽\s*\d{3,5}", text, re.I))
    has_mc = bool(
        re.search(r"(?i)мастер[-\s]?класс|вариант|masterclass|master\s+class", text)
    )
    return has_price and has_mc


_CATEGORY_LEGACY_EXPANSIONS: dict[str, str] = {
    "photography": "photography,photo_video",
    "tech_coding": "tech_coding,tech_digital",
}


def _normalize_category_query_value(cat: str) -> str:
    segments = [p.strip() for p in cat.split(",") if p.strip()]
    if not segments:
        return cat.strip()
    maps = get_mappings()
    expanded: list[str] = []
    for seg in segments:
        norm = maps.normalize_category(seg)
        exp = _CATEGORY_LEGACY_EXPANSIONS.get(norm, norm)
        expanded.append(exp)
    return ",".join(expanded)


def _normalize_mclist_params(params: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = dict(params)
    cat = out.get("category")
    if isinstance(cat, str) and cat.strip():
        out["category"] = _normalize_category_query_value(cat)
    tags = out.get("tags")
    if isinstance(tags, str) and tags.strip():
        parts = [p.strip() for p in tags.split(",") if p.strip()]
        parts = [p for p in parts if not _CITY_TAG_DROP.search(p)]
        if parts:
            out["tags"] = ",".join(parts)
        else:
            out.pop("tags", None)
    return out


def call_mclist_with_fallback(
    params: dict[str, Any],
    last_user_message: str | None = None,
) -> dict[str, Any]:
    """Normalize params; if no rows, retry once without tags (category kept).

    If still empty and the user said they have no theme preference (broad_search_markers),
    retry **without category** so price/age/date filters still apply - avoids false
    "nothing found" when the model kept category=cooking from an earlier question.
    """
    base = _normalize_mclist_params(params)
    data = call_mclist(base)
    if isinstance(data, dict) and data.get("error"):
        return data
    n = int(data.get("returned") or 0)
    if n > 0:
        return data

    relaxed = dict(base)
    if "tags" in relaxed:
        relaxed.pop("tags", None)
        data2 = call_mclist(relaxed)
        if int(data2.get("returned") or 0) > 0:
            logger.info("mclist: retry without tags OK (category preserved)")
            return data2

    maps = get_mappings()
    if (
        last_user_message
        and base.get("category")
        and maps.matches_broad_search_marker(last_user_message)
    ):
        broad = {k: v for k, v in base.items() if k != "category"}
        broad.pop("tags", None)
        data3 = call_mclist(broad)
        if int(data3.get("returned") or 0) > 0:
            logger.info("mclist: retry without category (user declined theme - broad_search_marker)")
            return data3

    logger.info(
        "mclist: no rows for params %s",
        {
            k: base.get(k)
            for k in (
                "category",
                "audience",
                "format",
                "max_price",
                "min_age",
                "event_date_from",
                "event_date_to",
            )
        },
    )
    return data


def _is_stall_without_results(text: str) -> bool:
    """Model promised to search but did not call the tool - only filler phrases."""
    if not text or len(text) > 800:
        return False
    if re.search(r'(мастер[- ]класс|"\u0410-\u042f\u0401\u0430-\u044f\u0451)', text) and re.search(r"\d{3,5}", text):
        return False
    return bool(
        re.search(
            r"(?i)(ищу\s+для|ищу\s+тебе|подберу|подбираю|сейчас\s+подберу|немного\s+подожди|"
            r"wait\s+a|let\s+me\s+find|give\s+me\s+a\s+(sec|moment)|one\s+moment|"
            r"i('?ll| will)\s+(search|look|find))",
            text,
        )
    )


def _build_messages_for_api(full_messages: list[dict]) -> list[dict]:
    """Convert to Yandex API format: list of { role, text }. Skip tool role if API does not accept it."""
    out = []
    for m in full_messages:
        role = m.get("role")
        if role == "tool":
            out.append({"role": "user", "text": m.get("content", "")})
            continue
        text = m.get("content") or m.get("text", "")
        if not text and role == "assistant":
            continue
        out.append({"role": role, "text": text})
    return out


def _get_tool_calls(msg: dict, alt: dict) -> list[dict]:
    """Read tool calls from Yandex completion response (field names may vary)."""
    for key in ("toolCalls", "tool_call_list", "tool_calls"):
        v = msg.get(key) if isinstance(msg, dict) else None
        if not v and isinstance(alt, dict):
            v = alt.get(key)
        if v:
            return v if isinstance(v, list) else [v]
    return []


def _try_parse_search_args_from_text(text: str) -> dict[str, Any] | None:
    """Recover JSON args when the model prints a fake tool call / JSON in plain text."""
    if not text:
        return None
    low = text.lower()
    if not (
        "search_masterclasses" in low
        or re.search(r'"category"\s*:', text, re.I)
        or re.search(r"max_price", text, re.I)
    ):
        return None
    start = text.find("{")
    while start >= 0:
        depth = 0
        for i in range(start, len(text)):
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
                if depth == 0:
                    chunk = text[start : i + 1]
                    for attempt in (chunk, chunk.replace("'", '"')):
                        try:
                            obj = json.loads(attempt)
                            if isinstance(obj, dict) and any(
                                k in obj
                                for k in (
                                    "category",
                                    "max_price",
                                    "audience",
                                    "n",
                                    "format",
                                    "min_age",
                                    "tags",
                                    "event_date_from",
                                    "event_date_to",
                                )
                            ):
                                return obj
                        except json.JSONDecodeError:
                            continue
                    break
        start = text.find("{", start + 1)
    loose: dict[str, Any] = {}
    m = re.search(r"max_price[\"']?\s*[:=]\s*([0-9]+)", text, re.I)
    if m:
        loose["max_price"] = float(m.group(1))
    m = re.search(r"min_age[\"']?\s*[:=]\s*([0-9]+)", text, re.I)
    if m:
        loose["min_age"] = int(m.group(1))
    m = re.search(r'"category"\s*:\s*"([^"]+)"', text)
    if m:
        cat = m.group(1).replace(" ", "").strip()
        if cat:
            loose["category"] = cat
    m = re.search(r'"audience"\s*:\s*"([^"]+)"', text, re.I)
    if m:
        loose["audience"] = m.group(1).strip()
    m = re.search(r'"format"\s*:\s*"([^"]+)"', text, re.I)
    if m:
        loose["format"] = m.group(1).strip().lower()
    m = re.search(r'"event_date_from"\s*:\s*"([^"]+)"', text, re.I)
    if m and _ISO_DATE_RE.match(m.group(1).strip()):
        loose["event_date_from"] = m.group(1).strip()
    m = re.search(r'"event_date_to"\s*:\s*"([^"]+)"', text, re.I)
    if m and _ISO_DATE_RE.match(m.group(1).strip()):
        loose["event_date_to"] = m.group(1).strip()
    if loose:
        loose.setdefault("n", 5)
        return loose
    return None


def _is_raw_json_masterclass_list(text: str) -> bool:
    """Model sometimes returns a JSON array of fake MCs (name/description/price) instead of prose."""
    t = text.strip()
    if len(t) < 10 or not t.startswith("["):
        return False
    try:
        data = json.loads(t)
    except json.JSONDecodeError:
        return False
    if not isinstance(data, list) or len(data) == 0:
        return False
    for item in data[:8]:
        if not isinstance(item, dict):
            return False
        keys = {str(k).lower() for k in item}
        if "name" in keys and "price" in keys:
            return True
        if "name" in keys and "description" in keys:
            return True
        mc_keys = keys & {"title", "name", "price", "date", "event_date", "description", "website"}
        if len(mc_keys) >= 3 and "price" in keys:
            return True
    return False


def _sanitize_user_visible_reply(text: str) -> str:
    """Remove leaked [search_masterclasses] + JSON from model text; keep the human reply."""
    if not text:
        return text
    if _is_raw_json_masterclass_list(text):
        return ""
    out = text
    for _ in range(4):
        m = re.search(r"(?i)\[?\s*search_masterclasses\s*\]?", out)
        if not m:
            break
        tail = out[m.end():].lstrip()
        if tail.startswith("{"):
            depth = 0
            cut = None
            for i, ch in enumerate(tail):
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        cut = i + 1
                        break
            if cut is not None:
                out = (out[: m.start()] + tail[cut:]).strip()
            else:
                out = out[: m.start()].strip()
        else:
            out = out[: m.start()].strip()
    out = re.sub(r"(?is)^\s*Got it[!.\s]*\s*", "", out)
    out = out.strip()
    if out.startswith("{") and '"category"' in out:
        return ""
    if _is_raw_json_masterclass_list(out):
        return ""
    return out


_TOOL_PAYLOAD_ERROR = (
    "Связь с базой мастер-классов временно недоступна (ошибка сервера). "
    "Скажи пользователю по-русски попробовать позже, не выдумывай список.\n"
)
_TOOL_PAYLOAD_EMPTY = (
    "В базе по этим фильтрам ничего не найдено (returned=0, masterclasses пустой). "
    "Скажи пользователю по-русски, что подходящих мастер-классов нет; "
    "не придумывай названия, цены и даты.\n"
)
_TOOL_PAYLOAD_REUSE_NOTE = (
    "Внимание: повторный поиск вернул 0 строк (часто из\u2011за exclude_ids), но пользователь просит контакты "
    "или выбирает вариант после уже показанного списка. Ниже masterclasses из предыдущего успешного "
    "ответа инструмента в этом чате - обязательно перечисли контакты из полей website, organizer, "
    "location, contact_tg, contact_vk, contact_phone; не говори, что мастер-классов нет или нет доступа.\n"
)
_TOOL_PAYLOAD_OK = (
    "Результат поиска (JSON ниже). Поля website, contact_tg, contact_vk, contact_phone и т.д. - только если в следующем "
    "сообщении пользователь спросит про запись/контакты; в обычной выдаче подборки их не перечисляй.\n"
    "Ответь по-русски: 1-3 мастер-класса. Формат: короткое вступление, пустая строка, затем каждый вариант - отдельный абзац "
    "(пустая строка между абзацами). В абзаце: строка 1 - title в русских кавычках \u00abёлочки\u00bb точно как в JSON; строка 2 - цена; строка 3 - дата. "
    "Без текста из description, без \"почему подходит\", без контактов и ссылок - приложение покажет фото и \"Открыть карточку\". "
    "Не используй Markdown (звёздочки, подчёркивания для жирного/курсива) в ответе пользователю. "
    "Только записи из masterclasses. Не выводи сырой JSON, не пиши [search_masterclasses].\n"
)

# Rejection prompts when the model misbehaves (keyed for readability).
_REJECT_RAW_JSON = (
    "Нельзя отвечать массивом JSON с полями вроде name/description/price. "
    "Вызови search_masterclasses с нужными фильтрами (для фотографии - category с токенами из промпта), "
    "затем опиши 1-3 варианта **обычным русским текстом**: название, цена, дата, без JSON и без квадратных скобок."
)
_REJECT_STALL = (
    "Немедленно вызови search_masterclasses: category=cooking_baking для кулинарии, "
    "max_price и min_age из переписки; event_date_from/event_date_to в YYYY-MM-DD, если пользователь "
    "назвал сроки (иначе опусти). sort_order=date_asc по желанию. "
    "Перечисли 1-3 найденных мастер-класса с ценой - без фраз \"ищу\" и \"подожди\"."
)
_REJECT_FAKE_LISTINGS = (
    "Запрещено перечислять мастер-классы с ценами без вызова search_masterclasses. "
    "Сейчас вызови search_masterclasses с нужными параметрами "
    "(для еды и готовки - category=cooking_baking). Ответь пользователю только "
    "по полю masterclasses из JSON ответа инструмента."
)


def run_chat_with_tools(
    messages: list[dict],
    api_key: str,
    model_uri: str,
    client_shown_ids: list[int] | None = None,
) -> tuple[str, list[dict], list[int], list[dict[str, Any]]]:
    """Call Yandex completion API with tools; on tool_calls execute and loop until text reply.

    client_shown_ids: ids from previous POST /chat responses (Flutter echoes shown_masterclass_ids);
    merged into exclude_ids so "ещё" does not repeat rows.
    """
    headers = {"Authorization": f"Api-Key {api_key}", "Content-Type": "application/json"}
    full_messages: list[dict] = [{"role": "system", "content": _system_prompt_with_calendar()}] + list(messages)
    for m in full_messages:
        if "content" not in m and "text" in m:
            m["content"] = m["text"]
        elif "text" not in m and "content" in m:
            m["text"] = m["content"]

    max_rounds = 20
    pending_mc_preview: list[dict[str, Any]] = []
    for round_idx in range(max_rounds):
        api_messages = _build_messages_for_api(full_messages)
        body = {
            "modelUri": model_uri,
            "messages": api_messages,
            "completionOptions": {"temperature": 0.2, "maxTokens": 2000},
            "tools": [SEARCH_MASTERCLASSES_TOOL],
        }
        try:
            with httpx.Client(timeout=60.0) as client:
                r = client.post(YANDEX_COMPLETION_URL, headers=headers, json=body)
                r.raise_for_status()
                data = r.json()
        except httpx.HTTPStatusError as e:
            err_text = (e.response.text or "")[:500]
            logger.exception("Yandex API error %s: %s", e.response.status_code, err_text)
            return _with_shown(
                f"Сервис временно недоступен (Yandex API {e.response.status_code}). "
                f"Проверьте YANDEX_AI_API_KEY и YANDEX_FOLDER_ID. Детали: {err_text}",
                full_messages,
                client_shown_ids,
                [],
            )
        except Exception as e:
            logger.exception("Yandex API request failed: %s", e)
            return _with_shown(f"Ошибка связи с сервисом: {e!s}", full_messages, client_shown_ids, [])

        result = data.get("result", {})
        alternatives = result.get("alternatives", [])
        if not alternatives:
            return _with_shown("Не удалось получить ответ модели.", full_messages, client_shown_ids, [])
        alt = alternatives[0]
        msg = alt.get("message", alt) if isinstance(alt, dict) else {}
        if not isinstance(msg, dict):
            msg = {}
        text = (msg.get("text") or alt.get("text", "")).strip()
        tool_calls = _get_tool_calls(msg, alt if isinstance(alt, dict) else {})

        if not tool_calls and text:
            parsed = _try_parse_search_args_from_text(text)
            if parsed:
                tool_calls = [
                    {"function": {"name": "search_masterclasses", "arguments": json.dumps(parsed)}}
                ]
                text = ""

        if not tool_calls and text:
            # Reject bad model outputs and re-steer.
            rejection = None
            if _is_raw_json_masterclass_list(text):
                rejection = _REJECT_RAW_JSON
            elif _is_stall_without_results(text):
                rejection = _REJECT_STALL
            elif _looks_like_mc_recommendations_without_tool(text) and not _had_tool_result_recently(full_messages):
                rejection = _REJECT_FAKE_LISTINGS

            if rejection:
                logger.warning("Rejecting model output, re-steering")
                full_messages.append({"role": "user", "content": rejection})
                continue

            cleaned = _sanitize_user_visible_reply(text)
            if cleaned:
                return _with_shown(cleaned, full_messages, client_shown_ids, pending_mc_preview)
            continue

        if not tool_calls and not text:
            logger.warning("Empty model response (round %s)", round_idx)
            full_messages.append({
                "role": "user",
                "content": "Кратко ответь пользователю на русском по смыслу переписки.",
            })
            continue

        if not tool_calls:
            continue

        full_messages.append({"role": "assistant", "content": text, "tool_calls": tool_calls})
        executed = False
        for tc in tool_calls:
            fn = tc.get("function", {})
            name = fn.get("name", "")
            args_str = fn.get("arguments", "{}")
            if name != "search_masterclasses":
                logger.info("Skipping unknown tool: %s", name)
                continue
            try:
                args = json.loads(args_str) if isinstance(args_str, str) else (args_str or {})
            except json.JSONDecodeError:
                args = {}
            args = _sanitize_search_masterclasses_args(args)
            recent_blob = _recent_user_text(full_messages)
            args = _merge_query_hints_from_user(args, recent_blob)
            last_u = _last_user_message(full_messages)
            args = _apply_unanswered_clarification_filters(full_messages, args)
            args = get_mappings().apply_optional_decline_override(last_u, args)
            args = get_mappings().apply_broad_search_override(last_u, args)
            _apply_exclude_ids_from_history(args, full_messages, client_shown_ids)
            result_data = call_mclist_with_fallback(args, last_user_message=last_u)
            result_data = _reuse_previous_tool_results_if_contact_followup(
                full_messages, last_u, result_data
            )
            executed = True
            nret = int(result_data.get("returned") or 0)
            result_json = json.dumps(result_data, ensure_ascii=False)

            if result_data.get("error"):
                pending_mc_preview = []
                tool_payload = _TOOL_PAYLOAD_ERROR + result_json
            elif nret == 0:
                pending_mc_preview = []
                tool_payload = _TOOL_PAYLOAD_EMPTY + result_json
            else:
                reuse_note = _TOOL_PAYLOAD_REUSE_NOTE if result_data.get("reuse_from_previous_search_in_chat") else ""
                tool_payload = reuse_note + _TOOL_PAYLOAD_OK + result_json
                mcs = result_data.get("masterclasses") or []
                pending_mc_preview = [r for r in mcs if isinstance(r, dict)][:5]
            full_messages.append({
                "role": "tool",
                "tool_call_id": str(tc.get("id", "")),
                "content": tool_payload,
            })

        if not executed:
            full_messages.append({
                "role": "user",
                "content": "Для поиска используй только инструмент search_masterclasses.",
            })

    return _with_shown(
        "Не удалось завершить подбор за несколько шагов. Уточни запрос или напиши короче. "
        "/ Could not finish in time - try a shorter message or repeat your filters.",
        full_messages,
        client_shown_ids,
        [],
    )


def run_chat(
    messages: list[dict], api_key: str, client_shown_ids: list[int] | None = None
) -> tuple[str, list[int], list[dict[str, Any]]]:
    if YANDEX_MODEL_URI:
        model_uri = YANDEX_MODEL_URI
    elif YANDEX_FOLDER_ID:
        model_uri = f"gpt://{YANDEX_FOLDER_ID}/yandexgpt/latest"
    else:
        return (
            "Настройте Yandex: задайте YANDEX_FOLDER_ID (ID каталога из консоли Yandex Cloud) "
            "или полный YANDEX_MODEL_URI (например gpt://b1g.../yandexgpt/latest).",
            list(client_shown_ids or []),
            [],
        )
    reply, _fm, shown, previews = run_chat_with_tools(messages, api_key, model_uri, client_shown_ids)
    return reply, shown, previews


app = FastAPI(title="Masterclasses Chat Sidecar", version="0.1.0")


class ChatRequest(BaseModel):
    message: str
    messages: list[dict] = Field(default_factory=list)
    shown_masterclass_ids: list[int] = Field(default_factory=list)


class ChatResponse(BaseModel):
    reply: str
    shown_masterclass_ids: list[int] = Field(default_factory=list)
    masterclasses_preview: list[dict[str, Any]] = Field(default_factory=list)


@app.get("/health")
def health():
    m = get_mappings()
    return {
        "status": "ok",
        "backend": BACKEND_URL,
        "query_mappings": m.summary(),
    }


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    if not YANDEX_API_KEY:
        raise HTTPException(status_code=503, detail="YANDEX_AI_API_KEY not set")
    messages = list(req.messages)
    messages.append({"role": "user", "content": req.message})
    try:
        reply, shown, previews = run_chat(messages, YANDEX_API_KEY, req.shown_masterclass_ids)
    except Exception:
        logger.exception("POST /chat failed")
        reply = (
            "Сервис чата временно недоступен. Попробуйте ещё раз. "
            "/ Chat service error. Please try again."
        )
        return ChatResponse(
            reply=reply,
            shown_masterclass_ids=list(req.shown_masterclass_ids),
            masterclasses_preview=[],
        )
    return ChatResponse(
        reply=reply,
        shown_masterclass_ids=shown,
        masterclasses_preview=previews,
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=SIDECAR_PORT)
