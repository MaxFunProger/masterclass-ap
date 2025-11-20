# Masterclasses userver Service

## Состав

- `src/` — исходники обработчиков `/ping`, `/mclist`, `/mcadd`.
- `configs/` — статический конфиг userver, секресты и fallback'и.
- `scripts/db/` — SQL‑инициализация для двух БД (`masterclasses`, `users`).
- `docker-compose.yml` — локальный стенд из двух PostgreSQL.

## Запуск баз данных

```bash
cd /home/miximka/masterclasses
docker compose up -d
# masterclasses DB слушает :5433, users DB — :5434
```

При первом старте контейнеры применят SQL из `scripts/db/*.sql`.

## Настройка userver

DSN'ы Postgres лежат в `configs/secdist.json`. Отредактируйте логины/хосты при необходимости (например, если запускаете удалённо или в Docker Desktop).

Статический конфиг: `configs/static_config.yaml`. Там описаны все компоненты userver, путь к секдисту, TaskProcessor'ы и HTTP‑обработчики.

## Сборка и запуск сервиса локально

### Зависимости

- CMake ≥ 3.20, Ninja (или make)
- Компилятор с поддержкой C++20 (clang-15 / gcc-12+)
- `libuserver-dev`, `libpq-dev`

На Ubuntu 22.04:

```bash
sudo apt install ninja-build cmake pkg-config libpq-dev libuserver-dev
```

```bash
cd /home/miximka
cmake -S masterclasses -B masterclasses/build -G Ninja
cmake --build masterclasses/build

# при running в той же машине, где подняты БД (порт 8080 по умолчанию)
./masterclasses/build/masterclasses-service \
  --config /home/miximka/masterclasses/configs/static_config.yaml
```

### Сборка внутри docker (опционально)

1. Установите userver и зависимости внутрь образа (см. официальную документацию Yandex userver).
2. Смонтируйте исходники внутрь контейнера и выполните шаги из секции выше.

## HTTP API

Все ответы — `application/json`.

### `GET /ping`

Проверка живости сервиса.

Пример:

```bash
curl http://localhost:8080/ping
```

Ответ:

```json
{ "status": "ok", "service": "masterclasses-service", "timestamp": "2025-11-19T08:00:00Z" }
```

### `GET /mclist?n=<N>&user_id=<uuid>`

- `n` — положительное число (до 100), сколько мастер‑классов вернуть.
- `user_id` — обязательный уникальный идентификатор пользователя (строка).

Действия обработчика:

1. Берёт первые `n` мастер‑классов из таблицы `masterclasses`.
2. Увеличивает счётчик запросов пользователя в таблице `user_requests` (вставляет запись, если её не было).

Пример:

```bash
curl "http://localhost:8080/mclist?n=5&user_id=user-42"
```

Ответ:

```json
{
  "user_id": "user-42",
  "request_count": 7,
  "returned": 5,
  "masterclasses": [
    {
      "id": 1,
      "title": "Latte Art 101",
      "location": "Moscow",
      "price": 3000.0,
      "website": "https://example.com/latte",
      "image_url": "https://example.com/latte.jpg"
    }
    // ...
  ]
}
```

### `POST /mcadd`

Добавляет новую запись о мастер‑классе. Тело запроса:

```json
{
  "id": 17,
  "title": "Pottery basics",
  "location": "Saint Petersburg",
  "price": 4500.0,
  "website": "https://example.com/pottery",
  "image_url": "https://example.com/pottery.jpg"
}
```

- Если запись с таким `id` уже существует, сервис возвращает `409 Conflict` и не вносит изменений.
- В случае успеха — `201 Created`.

Пример:

```bash
curl -X POST http://localhost:8080/mcadd \
  -H 'Content-Type: application/json' \
  -d '{"id":5,"title":"Sushi","location":"Online","price":2500,"website":"https://example.com","image_url":"https://example.com/sushi.jpg"}'
```

## Тестирование

- Быстрый smoke-тест — `curl` запросы к трём эндпоинтам.
- Для интеграционных тестов можно использовать любую систему (pytest, testsuite) поверх поднятых контейнеров PostgreSQL.

## Полезные команды

```bash
# остановить БД
docker compose down

# посмотреть логи сервиса
journalctl -u masterclasses-service -f
```

