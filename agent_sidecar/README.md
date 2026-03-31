# Agent sidecar

FastAPI-сервис: диалог через Yandex Foundation Models (function calling) и инструмент `search_masterclasses` -> `GET {BACKEND_URL}/mclist`.

## Переменные окружения

| Переменная | Назначение | По умолчанию |
|------------|------------|---------------|
| `YANDEX_AI_API_KEY` | API-ключ | обязательно |
| `YANDEX_FOLDER_ID` | ID каталога (`b1g...`) | - если задан `YANDEX_MODEL_URI` |
| `YANDEX_MODEL_URI` | Полный URI, напр. `gpt://b1g.../yandexgpt/latest` | - если задан `YANDEX_FOLDER_ID` |
| `YANDEX_COMPLETION_URL` | URL completion API | `https://llm.api.cloud.yandex.net/foundationModels/v1/completion` |
| `BACKEND_URL` | Бэкенд с `/mclist` | `http://localhost:80` |
| `SIDECAR_PORT` | Порт (только локальный `uvicorn` в `main`) | `5000` |
| `QUERY_MAPPINGS_PATH` | YAML с эвристиками | `agent_sidecar/query_mappings.yaml` |

Смысл полей поиска и токены `category` - в **`SYSTEM_PROMPT`** в `main.py`. Файл **`query_mappings.yaml`** - алиасы и fallback, если модель не передала параметр.

## Запуск

**Docker** (из корня репозитория): `docker compose up -d --build` - сервис `agent-sidecar`, внутри сети `BACKEND_URL=http://backend:80`. Секреты в `agent_sidecar/.env` (шаблон `env.example`).

**Хост:** `cp agent_sidecar/env.example agent_sidecar/.env`, заполнить ключи, затем из корня:

```bash
./scripts/run_agent_sidecar.sh
```

(venv создаётся как `.venv_sidecar` в корне репозитория.)

## API

- `GET /health` - статус, сводка по `query_mappings`.
- `POST /chat` - тело: `message`, опционально `messages`, `shown_masterclass_ids` (echo с прошлого ответа для `exclude_ids`).

Ответ: `reply`, `shown_masterclass_ids`, `masterclasses_preview` (до 5 строк для UI).
