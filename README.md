# Masterclasses

Афиша мастер-классов: бэкенд на C++ (userver), мобильное приложение на Flutter, чат-бот через Yandex GPT.

## Структура

```
src/                    C++ бэкенд (userver): хэндлеры, утилиты
src/sql/                SQL-запросы (подставляются в код через CMake)
configs/                static_config.yaml, secdist.json
scripts/                сборка, импорт данных, запуск сервисов
scripts/db/init.sql     схема БД (masterclasses, users, user_favorites)
frontend/               Flutter-приложение (Android)
agent_sidecar/          Python FastAPI — прокси к Yandex GPT с инструментом поиска
docker-compose.yml      postgres + backend + agent-sidecar
```

## Архитектура

```
Flutter app ──► Backend :80 ──► PostgreSQL :5432
     │              │
     └──► Agent :5000 ──► Yandex GPT API
               │
               └──► Backend /mclist (tool call)
```

Приложение обращается к бэкенду напрямую (REST) и к агенту (чат). Агент при необходимости вызывает `GET /mclist` на бэкенде — ищет мастер-классы по параметрам, которые определяет модель.

## Файлы вне репозитория

| Файл | Зачем | Как получить |
|------|-------|-------------|
| `data.csv` | Данные мастер-классов для импорта | У автора проекта; формат см. в `scripts/import_data.py` |
| `static/images/` | Фото мастер-классов | `./scripts/load_masterclasses_and_images.sh` |
| `agent_sidecar/.env` | Ключи Yandex AI | `cp agent_sidecar/env.example agent_sidecar/.env` |
| `frontend/android/key.properties` | Подпись APK | `cp frontend/android/key.properties.example ...` |
| `frontend/android/*.jks` | Keystore | `keytool -genkey ...` (см. `frontend/README.md`) |

## Запуск (Docker)

```bash
./scripts/run_backend.sh
```

Поднимает три контейнера: `postgres`, `backend`, `agent-sidecar`.

Порты по умолчанию:

| Сервис | Порт на хосте | Переменная в `.env` |
|--------|--------------|---------------------|
| Backend API | 80 | `MASTERCLASSES_HTTP_PORT` |
| Agent (чат) | 5000 | `AGENT_HTTP_PORT` |
| PostgreSQL | 5433 | — |
| userver monitor | 18081 | `MASTERCLASSES_MONITOR_PORT` |

Для чата нужен `agent_sidecar/.env` с ключами Yandex. Без него агент стартует, но отвечает 503.

Остановка: `docker compose down`. Сброс БД: `docker compose down -v`.

## Сборка бэкенда на хосте

Зависимости: CMake ≥ 3.20, C++20 (gcc-12+ / clang-15), userver (core + postgresql), libpq-dev.

```bash
docker compose up -d postgres                        # только БД
cmake -S . -B build && cmake --build build
./build/masterclasses-service -c configs/static_config.yaml
```

Порт 80 без root: `sudo setcap 'cap_net_bind_service=+ep' ./build/masterclasses-service` или поменять порт в `static_config.yaml`.

DSN для локального запуска — `configs/secdist.json` (по умолчанию `localhost:5433`). В Docker DSN генерируется entrypoint-скриптом из переменных окружения.

## Сборка Flutter-приложения

Через скрипт: `./scripts/build_android_apk.sh`

| Параметр | По умолчанию | Назначение |
|----------|-------------|-----------|
| `API_HOST` | debug: `10.0.2.2` (эмулятор), release: прод | Хост бэкенда |
| `API_PORT` | `80` | Порт бэкенда |
| `CHAT_HOST` | тот же, что `API_HOST` | Хост агента |
| `CHAT_PORT` | `5000` | Порт агента |

Подпись release для Google Play — см. `frontend/README.md`.

## Агент чат-бот

Без Docker:

```bash
./scripts/run_agent_sidecar.sh
```

Скрипт создаёт venv, ставит зависимости, подхватывает `agent_sidecar/.env` и запускает uvicorn на `:5000`.

Переменные окружения описаны в `agent_sidecar/env.example` и `agent_sidecar/README.md`.

## API бэкенда

Все ответы — `application/json`.

| Метод | Путь | Назначение |
|-------|------|-----------|
| GET | `/ping` | Healthcheck |
| GET | `/mclist` | Список мастер-классов с фильтрами и пагинацией |
| POST | `/mcadd` | Добавить мастер-класс |
| DELETE | `/mcdelete?id=` | Удалить мастер-класс |
| POST | `/register` | Регистрация (phone, full_name, password) |
| POST | `/login` | Авторизация (phone, password) → user_id |
| DELETE | `/userdelete?user_id=` | Удалить пользователя |
| GET | `/user/profile?user_id=` | Профиль пользователя |
| GET/POST/DELETE | `/user/favorites` | Избранное (user_id, masterclass_id) |
| GET | `/static/*` | Статические файлы (фото и др.), из in-memory кэша |

### GET /mclist — параметры фильтрации

| Параметр | Тип | Описание |
|----------|-----|---------|
| `n` | int | Количество записей (макс. 100, по умолчанию 20) |
| `offset` | int | Смещение |
| `category` | string | Токены через запятую: `cooking_baking`, `photography`, `tech_coding`, ... |
| `audience` | string | `adults`, `kids`, `families`, `teens`, `corporate`, `date_couple`, ... |
| `format` | string | `online` / `offline` |
| `company` | string | `single` / `friends` |
| `tags` | string | Доп. теги через запятую |
| `min_age` | int | Минимальный возраст |
| `min_price`, `max_price` | float | Диапазон цены |
| `min_rating` | float | Минимальный рейтинг |
| `event_date_from`, `event_date_to` | YYYY-MM-DD | Диапазон дат проведения |
| `exclude_ids` | string | ID через запятую — исключить из выдачи |
| `sort_order` | string | `date_asc` / `date_desc` |

Полный список токенов `category` и `audience` описан в системном промпте агента (`agent_sidecar/main.py`).

### API агента

| Метод | Путь | Назначение |
|-------|------|-----------|
| GET | `/health` | Статус, версия маппингов |
| POST | `/chat` | Сообщение: `{ "message": "...", "messages": [...], "shown_masterclass_ids": [...] }` |

Ответ `/chat`: `{ "reply": "...", "shown_masterclass_ids": [...], "masterclasses_preview": [...] }`.

`shown_masterclass_ids` — эхо для exclude: клиент передаёт их обратно при следующем запросе, чтобы «ещё варианты» не повторяли уже показанные.

## Дополнительная документация

- `frontend/README.md`
