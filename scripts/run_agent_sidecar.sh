#!/usr/bin/env bash
# Start the chat agent (Python sidecar). No need to export vars in the shell:
# put secrets in agent_sidecar/.env (see agent_sidecar/env.example), then run:
# ./scripts/run_agent_sidecar.sh

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

ENV_FILE="${ROOT}/agent_sidecar/.env"
if [[ -f "$ENV_FILE" ]]; then
 set -a
 # shellcheck disable=SC1090
 source "$ENV_FILE"
 set +a
else
 echo "Missing ${ENV_FILE}" >&2
 echo "Copy the template and fill in your keys:" >&2
 echo " cp agent_sidecar/env.example agent_sidecar/.env" >&2
 echo " nano agent_sidecar/.env # or any editor" >&2
 exit 1
fi

if [[ -z "${YANDEX_AI_API_KEY:-}" ]]; then
 echo "Set YANDEX_AI_API_KEY in ${ENV_FILE}" >&2
 exit 1
fi
if [[ -z "${YANDEX_FOLDER_ID:-}" && -z "${YANDEX_MODEL_URI:-}" ]]; then
 echo "Set either YANDEX_FOLDER_ID or YANDEX_MODEL_URI in ${ENV_FILE}" >&2
 echo "(If you only have a model URI like gpt://b1g.../yandexgpt/latest - put it in YANDEX_MODEL_URI.)" >&2
 exit 1
fi

export BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:80}"

VENV="${ROOT}/.venv_sidecar"
if [[ ! -d "$VENV" ]]; then
 python3 -m venv "$VENV"
 "$VENV/bin/pip" install -q -r "${ROOT}/agent_sidecar/requirements.txt"
fi

exec "$VENV/bin/uvicorn" agent_sidecar.main:app --host 0.0.0.0 --port "${SIDECAR_PORT:-5000}"
