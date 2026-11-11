#!/bin/bash
# Compila Stickman.app SIN firma y genera Stickman.ipa sin firmar.
# Pensado para GitHub Actions (macos-latest) o un Mac local con Xcode.
set -euo pipefail
cd "$(dirname "$0")"

xcodebuild \
  -project Stickman.xcodeproj \
  -scheme Stickman \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

bash ./package-ipa.sh \
  "build/DerivedData/Build/Products/Release-iphoneos/Stickman.app" \
  "Stickman.ipa"
