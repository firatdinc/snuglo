#!/bin/sh
# ios/plugins/snuglo_bridge/src/snuglo_bridge.mm -> snuglo_bridge.{debug,release}.xcframework
# (static, iPhone ios-arm64 only, same as build_meta_sdk.sh).
#
# The bridge uses the engine C++ API (Object/ClassDB/Engine), so it compiles against the Godot
# 4.6-stable source headers. They are not in the repo: on first run the script downloads the
# 4.6-stable source to $GODOT_SRC (default ~/.cache/godot-src/godot-4.6-stable) and generates the
# three *.gen.h headers with SCons (in a local venv). The headers MUST match the engine version of
# the export templates (4.6.stable.official); bump GODOT_TAG together with the templates.
#
# Debug variant defines DEBUG_ENABLED (template_debug), release defines NDEBUG (template_release):
# Object's layout differs between the two, so the matching variant must be linked (the .gdip
# binary name "snuglo_bridge.xcframework" makes Godot pick .debug/.release automatically).
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/ios/plugins/snuglo_bridge"
GODOT_TAG="${GODOT_TAG:-4.6-stable}"
CACHE="${GODOT_CACHE:-$HOME/.cache/godot-src}"
GODOT_SRC="${GODOT_SRC:-$CACHE/godot-$GODOT_TAG}"

if [ ! -f "$GODOT_SRC/core/object/class_db.h" ]; then
	echo "Godot $GODOT_TAG kaynağı indiriliyor -> $GODOT_SRC"
	mkdir -p "$CACHE"
	curl -sL "https://github.com/godotengine/godot/archive/refs/tags/$GODOT_TAG.tar.gz" | tar xz -C "$CACHE"
fi
if [ ! -f "$GODOT_SRC/core/extension/gdextension_interface.gen.h" ]; then
	[ -x "$CACHE/venv/bin/scons" ] || { python3 -m venv "$CACHE/venv" && "$CACHE/venv/bin/pip" -q install scons; }
	(cd "$GODOT_SRC" && "$CACHE/venv/bin/scons" platform=ios target=template_release \
		core/extension/gdextension_interface.gen.h core/version_generated.gen.h core/disabled_classes.gen.h)
fi

TMP="$(mktemp -d)"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
for cfg in debug release; do
	if [ "$cfg" = debug ]; then DEF="-DDEBUG_ENABLED"; else DEF="-DNDEBUG"; fi
	mkdir -p "$TMP/$cfg"
	xcrun --sdk iphoneos clang++ -target arm64-apple-ios15.0 -isysroot "$SDK" -fobjc-arc -std=gnu++17 -O2 \
		-fno-exceptions -Wno-deprecated-declarations \
		-DIOS_ENABLED -DAPPLE_EMBEDDED_ENABLED -DUNIX_ENABLED -DCOREAUDIO_ENABLED -DTHREADS_ENABLED $DEF \
		-I"$GODOT_SRC" -I"$GODOT_SRC/platform/ios" \
		-c "$P/src/snuglo_bridge.mm" -o "$TMP/$cfg/snuglo_bridge.o"
	xcrun libtool -static -o "$TMP/$cfg/libsnuglo_bridge.a" "$TMP/$cfg/snuglo_bridge.o"
	rm -rf "${P:?}/snuglo_bridge.$cfg.xcframework"
	xcodebuild -create-xcframework -library "$TMP/$cfg/libsnuglo_bridge.a" -output "$P/snuglo_bridge.$cfg.xcframework" >/dev/null
done
rm -rf "${TMP:?}"
echo "tamam: $P/snuglo_bridge.{debug,release}.xcframework"
