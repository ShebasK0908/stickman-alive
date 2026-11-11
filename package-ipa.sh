#!/bin/bash
# Empaqueta una .app sin firmar en un .ipa (Payload/*.app zipeado).
# Uso: ./package-ipa.sh [ruta-a-Stickman.app] [salida.ipa]
set -euo pipefail
cd "$(dirname "$0")"

APP_PATH="${1:-build/DerivedData/Build/Products/Release-iphoneos/Stickman.app}"
OUTPUT="${2:-Stickman.ipa}"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: no existe la .app en: $APP_PATH" >&2
  exit 1
fi

# Un .ipa sin firmar no debe llevar carpeta _CodeSignature de una firma previa.
rm -rf "$APP_PATH/_CodeSignature"

case "$OUTPUT" in
  /*) ;;
  *) OUTPUT="$PWD/$OUTPUT" ;;
esac

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "$WORK_DIR/Payload"
ditto "$APP_PATH" "$WORK_DIR/Payload/$(basename "$APP_PATH")"
rm -f "$OUTPUT"
( cd "$WORK_DIR" && zip -qry "$OUTPUT" Payload )
echo "OK: $OUTPUT"
ls -lh "$OUTPUT"
