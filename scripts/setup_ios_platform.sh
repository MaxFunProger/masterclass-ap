#!/bin/bash
# Одноразовая настройка iOS-платформы для frontend/. Запускать на macOS из корня репозитория.
# Идемпотентно: повторный запуск не ломает уже настроенный проект.
#
# Что делает:
#  1) flutter create --platforms=ios (если папки ios/ ещё нет)
#  2) Подкладывает в Info.plist:
#     - CFBundleDisplayName=canDo!
#     - NSAppTransportSecurity с исключением для http://158.160.158.103
#  3) Поднимает iOS deployment target до 13.0 в Podfile (требование appmetrica_plugin)
#  4) Подсказывает, как поднять минимальную версию в Xcode-проекте.

set -euo pipefail

cd "$(dirname "$0")/.."
FRONTEND_DIR="frontend"
IOS_DIR="$FRONTEND_DIR/ios"
INFO_PLIST="$IOS_DIR/Runner/Info.plist"
PODFILE="$IOS_DIR/Podfile"
PBXPROJ="$IOS_DIR/Runner.xcodeproj/project.pbxproj"
TARGET_BUNDLE_ID="${IOS_BUNDLE_ID:-com.cando.app}"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "ERROR: iOS-сборка возможна только на macOS." >&2
    echo "Скрипт можно прогнать на CI-раннере с macOS (Codemagic, GitHub macos-15, и т.п.)." >&2
    exit 1
fi

command -v flutter >/dev/null || { echo "ERROR: не найден flutter в PATH" >&2; exit 1; }
command -v /usr/libexec/PlistBuddy >/dev/null || { echo "ERROR: PlistBuddy недоступен (macOS only)" >&2; exit 1; }

cd "$FRONTEND_DIR"

if [[ ! -d ios ]]; then
    echo "==> Создаю iOS-платформу (flutter create --platforms=ios)..."
    # Итоговый PRODUCT_BUNDLE_IDENTIFIER всё равно перепишем ниже на ${TARGET_BUNDLE_ID}.
    flutter create \
        --platforms=ios \
        --org=com.cando \
        --project-name=masterclasses_app \
        .
else
    echo "==> ios/ уже существует, пропускаю flutter create."
fi

cd ..

echo "==> Устанавливаю PRODUCT_BUNDLE_IDENTIFIER = ${TARGET_BUNDLE_ID}..."
if [[ -f "$PBXPROJ" ]]; then
    # 1) Сначала переписываем RunnerTests, чтобы префикс не сломался ниже.
    sed -i.bak -E \
        "s|PRODUCT_BUNDLE_IDENTIFIER = [^;]+\.RunnerTests;|PRODUCT_BUNDLE_IDENTIFIER = ${TARGET_BUNDLE_ID}.RunnerTests;|g" \
        "$PBXPROJ"
    # 2) Остальные (Runner: Debug/Release/Profile) — на основной bundle id.
    sed -i.bak -E \
        "/RunnerTests/!s|PRODUCT_BUNDLE_IDENTIFIER = [^;]+;|PRODUCT_BUNDLE_IDENTIFIER = ${TARGET_BUNDLE_ID};|g" \
        "$PBXPROJ"
    rm -f "$PBXPROJ.bak"
else
    echo "WARN: не найден $PBXPROJ, пропускаю смену bundle id." >&2
fi

echo "==> Патчу Info.plist: CFBundleDisplayName + NSAppTransportSecurity..."
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName canDo!" "$INFO_PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string canDo!" "$INFO_PLIST"

/usr/libexec/PlistBuddy -c "Delete :NSAppTransportSecurity" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSAllowsArbitraryLoads bool false" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:158.160.158.103 dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:158.160.158.103:NSExceptionAllowsInsecureHTTPLoads bool true" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:158.160.158.103:NSIncludesSubdomains bool false" "$INFO_PLIST"

echo "==> Поднимаю iOS deployment target в Podfile до 13.0..."
if [[ -f "$PODFILE" ]]; then
    if grep -qE "^# *platform :ios" "$PODFILE"; then
        sed -i.bak 's|^# *platform :ios.*|platform :ios, '\''13.0'\''|' "$PODFILE"
    elif grep -qE "^platform :ios" "$PODFILE"; then
        sed -i.bak "s|^platform :ios.*|platform :ios, '13.0'|" "$PODFILE"
    else
        printf "platform :ios, '13.0'\n%s\n" "$(cat "$PODFILE")" > "$PODFILE.tmp" && mv "$PODFILE.tmp" "$PODFILE"
    fi
    rm -f "$PODFILE.bak"
fi

cat <<EOF

==> Готово. Bundle ID: ${TARGET_BUNDLE_ID}
    (поменять можно через IOS_BUNDLE_ID=... ./scripts/setup_ios_platform.sh, либо вручную в Xcode)

Дальше:
  cd frontend
  flutter pub get
  dart run flutter_launcher_icons
  cd ios && pod install && cd ..
  open ios/Runner.xcworkspace   # в Xcode: Signing & Capabilities → команда;
                                # General → Minimum Deployments → iOS 13.0
  ../scripts/build_ios.sh

EOF
