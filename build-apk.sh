#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SRC="$REPO_ROOT/ClipCascade_Mobile/src"
KEYSTORE_DIR="$HOME/.config/clipcascade-build"

# Load STORE_PASS, KEY_PASS, KEY_ALIAS
# shellcheck disable=SC1091
source "$KEYSTORE_DIR/passwords.env"
export STORE_PASS KEY_PASS KEY_ALIAS

echo ">>> running gradle assembleRelease inside clipcascade-rn-build"
podman run --rm \
  -e STORE_PASS -e KEY_PASS -e KEY_ALIAS \
  -v "$SRC":/app:Z \
  -v "$KEYSTORE_DIR":/keystore:Z,ro \
  -w /app \
  clipcascade-rn-build \
  bash -euo pipefail -c '
    echo "--- node $(node --version), npm $(npm --version) ---"
    if [ ! -d node_modules ]; then
        npm ci --no-audit --no-fund
    else
        echo "--- node_modules present, skipping npm ci ---"
    fi
    cd android
    ./gradlew --no-daemon assembleRelease \
      -PMYAPP_UPLOAD_STORE_FILE=/keystore/release.keystore \
      -PMYAPP_UPLOAD_STORE_PASSWORD="$STORE_PASS" \
      -PMYAPP_UPLOAD_KEY_ALIAS="$KEY_ALIAS" \
      -PMYAPP_UPLOAD_KEY_PASSWORD="$KEY_PASS"
  '

APK="$SRC/android/app/build/outputs/apk/release/app-release.apk"
if [ -f "$APK" ]; then
    echo
    echo ">>> APK built: $APK"
    ls -lh "$APK"
fi
