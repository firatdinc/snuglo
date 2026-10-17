#!/bin/sh
# ios/plugins/meta_sdk/src/meta_sdk.mm → meta_sdk.debug.xcframework + meta_sdk.release.xcframework
# (statik, yalnız iPhone ios-arm64; oyun simülatörde çalıştırılmıyor, FB çerçeveleri de yalnız cihaz dilimli).
# FB SDK çerçeveleri (FBSDKCoreKit, _Basics, FBAEMKit 18.1.1) facebook-ios-sdk sürüm sayfasındaki
# *-Dynamic_XCFramework.zip'lerden. Meta imzalıdır (ITMS-91065): KÜÇÜLTME — slim_ios_plugins.py imzayı bozar, Invalid Binary.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/ios/plugins/meta_sdk"
TMP="$(mktemp -d)"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
FLAGS=""
for fw in "$P"/FB*.xcframework/ios-arm64*/*.framework; do FLAGS="$FLAGS -F $(dirname "$fw")"; done
for cfg in debug release; do
	DEF=""
	[ "$cfg" = debug ] && DEF="-DDEBUG=1"
	mkdir -p "$TMP/$cfg"
	xcrun --sdk iphoneos clang -target arm64-apple-ios15.0 -isysroot "$SDK" -fobjc-arc -fmodules -fcxx-modules -std=c++17 -O2 $DEF \
		$FLAGS -c "$P/src/meta_sdk.mm" -o "$TMP/$cfg/meta_sdk.o"
	xcrun libtool -static -o "$TMP/$cfg/libmeta_sdk.a" "$TMP/$cfg/meta_sdk.o"
	rm -rf "${P:?}/meta_sdk.$cfg.xcframework"
	xcodebuild -create-xcframework -library "$TMP/$cfg/libmeta_sdk.a" -output "$P/meta_sdk.$cfg.xcframework" >/dev/null
done
rm -rf "${TMP:?}"
echo "tamam: $P/meta_sdk.{debug,release}.xcframework"
