#!/usr/bin/env bash
# Импорт мастер-классов из data.csv в Postgres через API, загрузка фото с Google Drive,
# обновление image_url в БД. Запуск с хоста, где крутится docker compose (backend :80, postgres).
#
# ./scripts/load_masterclasses_and_images.sh
#
# Переменные окружения:
# CLEAR_DB=1 - очистить masterclasses (и избранное) перед импортом
# API_BASE_URL - по умолчанию http://127.0.0.1:80
# BASE_URL - публичный URL для ссылок на /static/images/ (по умолчанию http://158.160.151.247)
# CSV_PATH - путь к CSV (по умолчанию ./data.csv в корне репозитория)
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:80}"
export BASE_URL="${BASE_URL:-http://158.160.151.247}"
export CSV_PATH="${CSV_PATH:-$ROOT/data.csv}"

if [[ ! -f "$CSV_PATH" ]]; then
 echo "Нет файла CSV: $CSV_PATH" >&2
 exit 1
fi

python3 -c "import requests" 2>/dev/null || {
 echo "Установите: pip install requests" >&2
 exit 1
}

if [[ "${CLEAR_DB:-0}" == "1" ]]; then
 echo "Очистка таблиц masterclasses / user_favorites..."
 docker compose exec -T postgres psql -U postgres -d app -v ON_ERROR_STOP=1 <<'SQL'
DELETE FROM user_favorites;
DELETE FROM masterclasses;
SQL
fi

echo "Импорт строк через POST /mcadd..."
python3 "$ROOT/scripts/import_data.py"

echo "Скачивание изображений и генерация scripts/update_images.sql..."
python3 "$ROOT/scripts/download_images.py"

if [[ ! -s "$ROOT/scripts/update_images.sql" ]]; then
 echo "Предупреждение: scripts/update_images.sql пустой (нет успешных загрузок с Drive?)." >&2
else
 echo "Применение обновлений image_url в БД..."
 docker compose exec -T postgres psql -U postgres -d app -v ON_ERROR_STOP=1 <"$ROOT/scripts/update_images.sql"
fi

echo "Готово. Перезапуск backend не нужен при volume ./static:/app/static в compose."
echo "Проверка: curl -s \"${API_BASE_URL%/}/mclist\" | head -c 200"
