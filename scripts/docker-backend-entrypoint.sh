#!/bin/sh
set -e
cd /app

POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-app}"

cat > /app/configs/secdist.json <<EOF
{
  "postgresql_settings": {
    "databases": {
      "app-db": [
        {
          "shard_number": 0,
          "hosts": [
            "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=disable"
          ]
        }
      ]
    }
  }
}
EOF

exec "$@"
