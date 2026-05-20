#!/bin/bash
# iOS release build. Только macOS + Xcode + CocoaPods.
# Прод по умолчанию: API :80, чат :5000. Локальная сеть:
#   API_HOST=192.168.1.5 ./scripts/build_ios.sh

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
    echo "ERROR: iOS-сборка возможна только на macOS." >&2
    exit 1
fi

cd "$(dirname "$0")/.."
export PATH="${PATH:-}:${HOME}/flutter_sdk/flutter/bin:${HOME}/flutter/bin"

command -v flutter >/dev/null || { echo "ERROR: не найден flutter в PATH" >&2; exit 1; }
command -v pod >/dev/null || { echo "ERROR: CocoaPods не установлен. sudo gem install cocoapods" >&2; exit 1; }

echo "Building iOS (API ${API_HOST:-158.160.158.103}:${API_PORT:-80}, chat ${CHAT_PORT:-5000})..."
cd frontend

if [[ ! -d ios ]]; then
    echo "ERROR: frontend/ios отсутствует. Сначала: ../scripts/setup_ios_platform.sh" >&2
    exit 1
fi

if [[ ! -f assets/app_icon.png ]]; then
    echo "ERROR: frontend/assets/app_icon.png отсутствует (нужен для иконки приложения)." >&2
    exit 1
fi

flutter pub get
dart run flutter_launcher_icons

pushd ios >/dev/null
pod install
popd >/dev/null

flutter clean
defs=()
[ -n "${API_HOST:-}" ] && defs+=(--dart-define=API_HOST="$API_HOST")
[ -n "${API_PORT:-}" ] && defs+=(--dart-define=API_PORT="$API_PORT")
[ -n "${CHAT_HOST:-}" ] && defs+=(--dart-define=CHAT_HOST="$CHAT_HOST")
[ -n "${CHAT_PORT:-}" ] && defs+=(--dart-define=CHAT_PORT="$CHAT_PORT")

if [[ "${BUILD_TARGET:-ipa}" == "ipa" ]]; then
    if [[ "${#defs[@]}" -gt 0 ]]; then
        flutter build ipa --release "${defs[@]}"
    else
        flutter build ipa --release
    fi
    echo "Done. IPA: frontend/build/ios/ipa/*.ipa"
else
    if [[ "${#defs[@]}" -gt 0 ]]; then
        flutter build ios --release "${defs[@]}"
    else
        flutter build ios --release
    fi
    echo "Done. App: frontend/build/ios/iphoneos/Runner.app"
    echo "Дальше: open ios/Runner.xcworkspace → Product → Archive (для App Store) или Run на устройстве."
fi
