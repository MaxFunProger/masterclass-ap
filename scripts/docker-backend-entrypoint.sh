#!/bin/sh
set -e
cd /app

POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-app}"

export POSTGRES_HOST POSTGRES_PORT POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB

# userver резолвит хост из DSN своим DNS-клиентом; на части окружений это даёт
# "Could not contact DNS servers" и обрыв пула без явного password error.
# Берём IPv4 через libc/getent - в DSN попадает адрес, резолв в рантайме не нужен.
if ! printf '%s' "$POSTGRES_HOST" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
 i=0
 while [ "$i" -lt 60 ]; do
 _pg_ip=$(getent ahostsv4 "$POSTGRES_HOST" 2>/dev/null | awk 'NR==1 { print $1 }')
 if [ -n "$_pg_ip" ]; then
 POSTGRES_HOST="$_pg_ip"
 export POSTGRES_HOST
 break
 fi
 i=$((i + 1))
 sleep 1
 done
 if ! printf '%s' "$POSTGRES_HOST" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
 echo "docker-backend-entrypoint: could not resolve postgres host to IPv4" >&2
 exit 1
 fi
fi

python3 <<'PY'
import json, os
from urllib.parse import quote

h = os.environ["POSTGRES_HOST"]
port = os.environ["POSTGRES_PORT"]
u = quote(os.environ["POSTGRES_USER"], safe="")
p = quote(os.environ["POSTGRES_PASSWORD"], safe="")
db = os.environ["POSTGRES_DB"]
uri = f"postgresql://{u}:{p}@{h}:{port}/{db}?sslmode=disable"
cfg = {
 "postgresql_settings": {
 "databases": {
 "app-db": [{"shard_number": 0, "hosts": [uri]}]
 }
 }
}
with open("/app/configs/secdist.json", "w", encoding="utf-8") as f:
 json.dump(cfg, f, indent=2)
PY

exec "$@"
