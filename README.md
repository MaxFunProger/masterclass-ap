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

Контейнеры применят SQL из `scripts/db/*.sql` при первом старте.  
Остановить Postgres можно командой `docker compose down`.
Данные баз сохраняются в Docker volumes (`masterclasses-data`, `users-data`), поэтому
после остановки контейнеров информация не теряется. Чтобы очистить базы и
переинициализировать их из SQL-скриптов, используйте `docker compose down -v`.

## Настройка userver

DSN'ы Postgres лежат в `configs/secdist.json`. Отредактируйте логины/хосты при необходимости (например, если запускаете удалённо или в Docker Desktop).

Статический конфиг: `configs/static_config.yaml`. Там описаны все компоненты userver, путь к секдисту, TaskProcessor'ы и HTTP‑обработчики.

## Сборка и запуск сервиса локально

### Зависимости

- CMake ≥ 3.20
- Компилятор с поддержкой C++20 (clang-15 / gcc-12+)
- `libuserver-dev`, `libpq-dev`, `pkg-config`

На Ubuntu 22.04:

```bash
sudo apt install cmake pkg-config libpq-dev libuserver-dev
```

### Быстрый старт

1. **Поднимите Postgres**  
   ```bash
   cd /home/miximka/masterclasses
   docker compose up -d
   ```

2. **Проверьте DSN**  
   В `configs/secdist.json` уже прописаны локальные DSN (`localhost:5433/5434`). Отредактируйте при необходимости.

3. **Соберите бинарник**  
   ```bash
   cd /home/miximka/masterclasses
   cmake -S . -B build
   cmake --build build
   ```
   > При желании можно указать другой генератор, например `-G Ninja`.

4. **Запустите сервис**  
   ```bash
   ./build/masterclasses-service \
     --config /home/miximka/masterclasses/configs/static_config.yaml
   ```

5. **Проверьте эндпоинты** (см. раздел «HTTP API» ниже).  
   Для остановки сервиса нажмите `Ctrl+C`, для остановки БД — `docker compose down`.

### Сборка внутри docker (опционально)

1. Установите userver и зависимости внутрь образа (см. официальную документацию Yandex userver).
2. Смонтируйте исходники внутрь контейнера и выполните шаги из блока «Быстрый старт».

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
- `user_id` — идентификатор пользователя. Если указан, пользователь должен существовать в `users-db`
  (создаётся через `/useradd`), иначе будет `404 Not Found`. Если параметр опущен, список мастер‑классов
  вернётся без привязки к пользователю (без `user_id` и `request_count` в ответе).

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

### `POST /mcadd/bulk`

Добавляет несколько мастер-классов за один запрос. Тело — массив объектов
в формате, идентичном `/mcadd`.

```json
[
  {
    "id": 11,
    "title": "Latte Art 101",
    "location": "Moscow",
    "price": 3000.0,
    "website": "https://example.com/latte",
    "image_url": "https://example.com/latte.jpg"
  },
  {
    "id": 12,
    "title": "Pottery basics",
    "location": "Saint Petersburg",
    "price": 4500.0,
    "website": "https://example.com/pottery",
    "image_url": "https://example.com/pottery.jpg"
  }
]
```

Ответ содержит количество созданных записей и статус по каждому элементу.
Если хотя бы одна запись добавлена, HTTP-статус будет `201 Created` (либо
`207 Multi-Status` при частичном успехе), иначе `409 Conflict`.

```bash
curl -X POST http://localhost:8080/mcadd/bulk \
  -H 'Content-Type: application/json' \
  -d '[{"id":11,"title":"Latte","location":"Moscow","price":3000,"website":"https://example.com/latte","image_url":"https://example.com/latte.jpg"}]'
```

### `DELETE /mcdelete?id=<id>`

Удаляет мастер‑класс по идентификатору. Обязательный query-параметр `id`.

Ответы:

- `200 OK` — запись удалена, `{"id":42,"status":"deleted"}`
- `404 Not Found` — такой записи нет, `{"id":42,"status":"not_found"}`
- `400 Bad Request` — неверный или отсутствующий параметр `id`.

Пример:

```bash
curl -X DELETE "http://localhost:8080/mcdelete?id=42"
```

### `POST /useradd`

Добавляет нового пользователя в `users-db`. Тело запроса:

```json
{
  "user_id": "user-42",
  "phone": "+7-999-000-00-00",
  "full_name": "Ivan Ivanov",
  "telegram_nick": "@ivan",
  "request_count": 0
}
```

Поле `request_count` опционально (по умолчанию `0`).  
Ответы:

- `201 Created` — пользователь создан;
- `409 Conflict` — пользователь уже существует.

```bash
curl -X POST http://localhost:8080/useradd \
  -H 'Content-Type: application/json' \
  -d '{"user_id":"user-42","phone":"+7-999-000-00-00","full_name":"Ivan Ivanov","telegram_nick":"@ivan"}'
```

### `DELETE /userdelete?user_id=<id>`

Удаляет пользователя из `users-db`. Возвращает:

- `200 OK` — `{"user_id":"user-42","status":"deleted"}`
- `404 Not Found` — пользователь отсутствует.

```bash
curl -X DELETE "http://localhost:8080/userdelete?user_id=user-42"
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

