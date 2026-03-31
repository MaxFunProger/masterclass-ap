#!/bin/bash
set -e

# Сборка Android App Bundle (.aab) для Google Play.
# Те же переменные, что и для APK: API_HOST, API_PORT, CHAT_HOST, CHAT_PORT (см. build_android_apk.sh).

cd "$(dirname "$0")/.."
export PATH="${PATH:-}:${HOME}/flutter_sdk/flutter/bin:${HOME}/flutter/bin:/snap/bin"

echo "Building Android App Bundle (API ${API_HOST:-158.160.151.247}:${API_PORT:-80}, chat ${CHAT_PORT:-5000})..."
cd frontend

if [ ! -f assets/app_icon.png ]; then
  echo "ERROR: frontend/assets/app_icon.png отсутствует (нужен для иконки лаунчера)."
  exit 1
fi

flutter pub get
dart run flutter_launcher_icons
flutter clean
defs=()
[ -n "${API_HOST:-}" ] && defs+=(--dart-define=API_HOST="$API_HOST")
[ -n "${API_PORT:-}" ] && defs+=(--dart-define=API_PORT="$API_PORT")
[ -n "${CHAT_HOST:-}" ] && defs+=(--dart-define=CHAT_HOST="$CHAT_HOST")
[ -n "${CHAT_PORT:-}" ] && defs+=(--dart-define=CHAT_PORT="$CHAT_PORT")
if [ "${#defs[@]}" -gt 0 ]; then
  flutter build appbundle "${defs[@]}"
else
  flutter build appbundle
fi

echo "Done. AAB: frontend/build/app/outputs/bundle/release/app-release.aab"
