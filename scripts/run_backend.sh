#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Сборка и запуск postgres, backend (C++) и agent-sidecar (Python) в Docker..."
docker compose up -d --build

echo "Готово."
echo " API: http://127.0.0.1:${MASTERCLASSES_HTTP_PORT:-80}/ping"
echo " Монитор: http://127.0.0.1:${MASTERCLASSES_MONITOR_PORT:-18081}"
echo " Agent чат: http://127.0.0.1:${AGENT_HTTP_PORT:-5000}/health (POST /chat)"
echo " Postgres: localhost:5433"
echo " Другие порты: MASTERCLASSES_HTTP_PORT, AGENT_HTTP_PORT, MASTERCLASSES_MONITOR_PORT"
echo " Ключи Yandex: скопируйте agent_sidecar/env.example -> agent_sidecar/.env"
