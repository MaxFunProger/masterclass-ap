#!/bin/bash
set -e

# Build Flutter app for Android. Прод по умолчанию: API :80, чат :5000 (как docker-compose).
# Локальная сеть: API_HOST=192.168.1.5 ./scripts/build_android_apk.sh (порт 80)

cd "$(dirname "$0")/.."
# Flutter / Dart (подставьте свой путь к SDK при необходимости)
export PATH="${PATH:-}:${HOME}/flutter_sdk/flutter/bin:${HOME}/flutter/bin:/snap/bin"

echo "Building Android APK (API ${API_HOST:-158.160.151.247}:${API_PORT:-80}, chat ${CHAT_PORT:-5000})..."
cd frontend

if [ ! -f assets/app_icon.png ]; then
 echo "ERROR: frontend/assets/app_icon.png отсутствует (нужен для иконки лаунчера)."
 echo "Создайте из SVG, например: venv/bin/pip install cairosvg && venv/bin/python -c \"import cairosvg; cairosvg.svg2png(url='frontend/assets/app_icon.svg', write_to='frontend/assets/app_icon.png', output_width=1024, output_height=1024)\""
 exit 1
fi

flutter pub get
# Без этого в android/app/src/main/res нет mipmap/ic_launcher* - иконка в лаунчере не подхватится
dart run flutter_launcher_icons
# Сброс промежуточных ресурсов (иначе mergeReleaseResources может падать на notification_template_*.xml)
flutter clean
defs=()
[ -n "${API_HOST:-}" ] && defs+=(--dart-define=API_HOST="$API_HOST")
[ -n "${API_PORT:-}" ] && defs+=(--dart-define=API_PORT="$API_PORT")
[ -n "${CHAT_HOST:-}" ] && defs+=(--dart-define=CHAT_HOST="$CHAT_HOST")
[ -n "${CHAT_PORT:-}" ] && defs+=(--dart-define=CHAT_PORT="$CHAT_PORT")
if [ "${#defs[@]}" -gt 0 ]; then
 flutter build apk "${defs[@]}"
else
 flutter build apk
fi

echo "Done. APK: frontend/build/app/outputs/flutter-apk/app-release.apk"
