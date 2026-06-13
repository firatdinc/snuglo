#!/usr/bin/env bash
# Snuglo release automation: archive → export → upload to App Store Connect.
# Headless signing via the ASC API key (no Xcode account needed) +
# -allowProvisioningUpdates so the distribution profile is fetched/created.
# Version + build number come from project.yml (manageAppVersionAndBuildNumber=false).
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP="SnugloApp"
PROJ="$APP/$APP.xcodeproj"
SCHEME="$APP"
TEAM="K858B9M275"

# ASC API key (from secrets/.env.local)
KEY_ID="$(grep APP_STORE_KEY_ID secrets/.env.local | cut -d= -f2-)"
ISSUER="$(grep APP_STORE_ISSUER_ID secrets/.env.local | cut -d= -f2-)"
KEY_PATH="$ROOT/$(grep APP_STORE_KEY_PATH secrets/.env.local | cut -d= -f2-)"

BUILD_DIR="$ROOT/build"
ARCHIVE="$BUILD_DIR/Snuglo.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
OPTS="$BUILD_DIR/ExportOptions.plist"

rm -rf "$BUILD_DIR"; mkdir -p "$BUILD_DIR"
( cd "$APP" && xcodegen generate >/dev/null )

cat > "$OPTS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$TEAM</string>
  <key>signingStyle</key><string>automatic</string>
  <key>destination</key><string>export</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST

AUTH=(-allowProvisioningUpdates
      -authenticationKeyPath "$KEY_PATH"
      -authenticationKeyID "$KEY_ID"
      -authenticationKeyIssuerID "$ISSUER")

echo "▸ Archiving…"
xcodebuild archive \
  -project "$PROJ" -scheme "$SCHEME" -configuration Release \
  -archivePath "$ARCHIVE" -destination 'generic/platform=iOS' \
  "${AUTH[@]}" DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic

echo "▸ Exporting…"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" -exportPath "$EXPORT_DIR" -exportOptionsPlist "$OPTS" \
  "${AUTH[@]}"

IPA="$(ls "$EXPORT_DIR"/*.ipa | head -1)"
echo "> Uploading ${IPA}"
xcrun altool --upload-app -f "${IPA}" -t ios --apiKey "$KEY_ID" --apiIssuer "$ISSUER"
echo "Uploaded to App Store Connect."
