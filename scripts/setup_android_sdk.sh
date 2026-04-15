#!/bin/bash
# Install Android SDK command-line tools only (no Android Studio).
# Then set ANDROID_SDK_ROOT and install components needed for Flutter.
set -e

SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
CMD_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
TMP_ZIP="/tmp/cmdline-tools.zip"

echo "Android SDK will be installed to: $SDK_ROOT"
mkdir -p "$SDK_ROOT"
cd "$SDK_ROOT"

if [ ! -f "cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "Downloading command-line tools..."
  curl -L -o "$TMP_ZIP" "$CMD_TOOLS_URL"
  echo "Extracting..."
  if command -v unzip &>/dev/null; then
    unzip -q -o "$TMP_ZIP"
  else
    python3 -c "
import zipfile, os
with zipfile.ZipFile('$TMP_ZIP', 'r') as z:
  z.extractall('$SDK_ROOT')
"
  fi
  # Official zip has top-level "cmdline-tools/"; we need cmdline-tools/latest/
  if [ -d "cmdline-tools" ] && [ ! -d "cmdline-tools/latest" ]; then
    mv cmdline-tools cmdline-tools-tmp
    mkdir -p cmdline-tools
    mv cmdline-tools-tmp cmdline-tools/latest
  fi
  rm -f "$TMP_ZIP"
  echo "Command-line tools installed."
else
  echo "Command-line tools already present."
fi

# Ensure scripts are executable (zip may not preserve execute bits)
chmod +x "$SDK_ROOT/cmdline-tools/latest/bin/"* 2>/dev/null || true

# Accept licenses and install components required by Flutter
echo "Installing platform-tools and build-tools..."
yes | "$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK_ROOT" \
  "platform-tools" \
  "platforms;android-34" \
  "build-tools;34.0.0"

echo ""
echo "Done. Add this to your ~/.bashrc (or run in this shell):"
echo "  export ANDROID_SDK_ROOT=\"$SDK_ROOT\""
echo "  export PATH=\"\$ANDROID_SDK_ROOT/platform-tools:\$PATH\""
echo ""
echo "Then run: flutter doctor -v"
