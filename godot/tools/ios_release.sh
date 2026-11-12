#!/bin/sh
# Snuglo iOS yayın zinciri (Kikko/Orbit Keeper'dan uyarlandı). export_project_only=true:
# Godot yalnız Xcode projesini üretir; yama + kapılar + derleme buradan.
#
#   tools/ios_release.sh dev      Debug dışa aktarım → Debug derleme → "Ergun's iPhone"a kur + başlat
#                                 (konsol akar; DEVICE=<udid> ile başka cihaz, NOLAUNCH=1 yalnız kurar)
#   tools/ios_release.sh check    Debug dışa aktarım → kapılar → generic iOS Debug derleme (cihaz yok)
#   tools/ios_release.sh export   Release dışa aktarım → kapılar → arşiv → App Store ipa (yüklemez) [varsayılan]
#   tools/ios_release.sh upload   export + App Store Connect'e yükleme (kullanıcı kendisi çalıştırır)
#
# Her yeni yapıdan önce export_presets.cfg application/version (build) artmalı; onaylanmış
# sürümden sonra short_version da. Canlı SwiftUI sürümü 1.2.0 (6) → bu yeniden yazım 2.0.0 (20+).
# Gerekenler: Xcode 26+ (Xcode → Settings → Accounts'ta K858B9M275 ekibi), Godot 4.6 iOS şablonları,
# ağ (AdMob SDK'sı Swift Package olarak indirilir). Türetilmiş veri build/ios/DerivedData'da
# kalır ve iş bitince silinir (disk dar).
set -e

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/ios"
NAME="Snuglo"
TEAM="K858B9M275"
BUNDLE="com.snuglo.app"
PBX="$OUT/$NAME.xcodeproj/project.pbxproj"
PLIST="$OUT/$NAME/$NAME-Info.plist"
DD="$OUT/DerivedData"
MODE="${1:-export}"

case "$MODE" in dev|check) CFG=Debug; GEXPORT=--export-debug ;; export|upload) CFG=Release; GEXPORT=--export-release ;;
	*) echo "kullanım: $0 [dev|check|export|upload]"; exit 2 ;; esac

# --- 0. Ön kapılar (dışa aktarımdan önce, ucuz) ---
# Kikko dersi: preset'teki eklenti anahtarı .gdip DOSYA ADI değil içindeki `name` olmalı; yanlış
# anahtar eklentiyi SESSİZCE kapatır ve satın almalar cihazda bedavaya düşer.
for key in MetaSDK GodotxRevenueCat SnugloBridge; do
	grep -q "^plugins/$key=true" "$ROOT/export_presets.cfg" || { echo "DUR: export_presets.cfg'de plugins/$key=true yok"; exit 1; }
done
grep -q '^name="MetaSDK"' "$ROOT/ios/plugins/meta_sdk/meta_sdk.gdip" || { echo "DUR: meta_sdk.gdip name≠MetaSDK"; exit 1; }
grep -q '^name="GodotxRevenueCat"' "$ROOT/ios/plugins/revenue_cat/revenue_cat.gdip" || { echo "DUR: revenue_cat.gdip name≠GodotxRevenueCat"; exit 1; }
grep -q '^name="SnugloBridge"' "$ROOT/ios/plugins/snuglo_bridge/snuglo_bridge.gdip" || { echo "DUR: snuglo_bridge.gdip name≠SnugloBridge"; exit 1; }
[ -d "$ROOT/ios/plugins/revenue_cat/RevenueCat.xcframework" ] || { echo "DUR: ios/plugins/revenue_cat/RevenueCat.xcframework yok"; exit 1; }
for v in debug release; do
	[ -d "$ROOT/ios/plugins/meta_sdk/meta_sdk.$v.xcframework" ] || { echo "DUR: MetaSDK derlenmemiş (tools/build_meta_sdk.sh)"; exit 1; }
	[ -d "$ROOT/ios/plugins/snuglo_bridge/snuglo_bridge.$v.xcframework" ] || { echo "DUR: SnugloBridge derlenmemiş (tools/build_snuglo_bridge.sh)"; exit 1; }
done
grep -q 'general/ios/app_id="ca-app-pub-8571533711927103~' "$ROOT/project.godot" || { echo "DUR: project.godot [admob] general/ios/app_id gerçek kimlik değil"; exit 1; }
grep -q 'res://addons/admob/plugin.cfg' "$ROOT/project.godot" || { echo "DUR: AdMob editör eklentisi etkin değil ([editor_plugins])"; exit 1; }

echo "== 1/5 Godot: Xcode projesi ($CFG) =="
mkdir -p "$OUT"
"$GODOT" --headless --audio-driver Dummy --path "$ROOT" $GEXPORT "iOS" "$OUT/$NAME.ipa"
[ -f "$PBX" ] || { echo "DUR: $PBX üretilmedi"; exit 1; }

# Godot 4.6'da AdMob'un SPM kancası başlıksız dışa aktarımda çalışmıyor (bkz. tools/ios_spm_patch.gd).
echo "== 2/5 AdMob SPM yaması =="
"$GODOT" --headless --path "$ROOT" --script tools/ios_spm_patch.gd

# Godot şablonu kamera/mikrofon/fotoğraf açıklamalarını BOŞ dize olarak hep ekler (Xcode uyarır,
# canlı sürümde bu anahtarlar yoktu). Boş olanları sil.
for k in NSCameraUsageDescription NSMicrophoneUsageDescription NSPhotoLibraryUsageDescription; do
	if [ "$(plutil -extract $k raw "$PLIST" 2>/dev/null)" = "" ]; then plutil -remove $k "$PLIST" 2>/dev/null || true; fi
done

# Meta SDK çerçeveleri Apple'ın imza zorunlu listesinde (ITMS-91065 → Invalid Binary). Godot kopyalarken
# Catalyst dilimindeki sembolik bağlantıları açıp mühürlü imzayı bozuyor → aslını bağlantılarıyla geri koy.
for fw in FBAEMKit FBSDKCoreKit FBSDKCoreKit_Basics; do
	dst="$OUT/$NAME/dylibs/ios/plugins/meta_sdk/$fw.xcframework"
	[ -d "$dst" ] || { echo "DUR: $dst yok"; exit 1; }
	rm -rf "$dst"
	ditto "$ROOT/ios/plugins/meta_sdk/$fw.xcframework" "$dst"
	codesign -v "$dst" || { echo "DUR: $fw.xcframework imzası geçersiz (Meta'nın resmî zip'ini kullan, küçültme)"; exit 1; }
done

echo "== 3/5 Kapılar: Info.plist + Xcode projesi =="
python3 - "$PLIST" "$PBX" <<'PYGATE'
import plistlib, sys, re
plist, pbx = sys.argv[1], sys.argv[2]
raw = open(plist, encoding='utf-8').read()
d = plistlib.loads(raw.encode())
err = []
# Aynı anahtar iki eklentiden gelirse plistlib sessizce sonuncuyu alır → ham metinde say.
for k in ('SKAdNetworkItems', 'CFBundleURLTypes', 'GADApplicationIdentifier', 'FacebookAppID'):
    n = raw.count('<key>%s</key>' % k)
    if n != 1:
        err.append('%s Info.plist\'te %d kez (1 olmalı)' % (k, n))
gad = d.get('GADApplicationIdentifier', '')
# Boş GADApplicationIdentifier her açılışta çöker (Kikko 1.0.1 (5) böyle gitti).
if not gad.startswith('ca-app-pub-8571533711927103~'):
    err.append('GADApplicationIdentifier gerçek kimlik değil: %r' % gad)
if d.get('FacebookAppID') != '1879491072709561': err.append('FacebookAppID yanlış/boş')
if d.get('FacebookClientToken') != '0a3e119d6b1f70ade11293fd73a9de96': err.append('FacebookClientToken yanlış/boş')
if d.get('FacebookDisplayName') != 'Snuglo': err.append('FacebookDisplayName yanlış/boş')
if d.get('FacebookAutoLogAppEventsEnabled') is not True: err.append('FacebookAutoLogAppEventsEnabled true değil')
if d.get('FacebookAdvertiserIDCollectionEnabled') is not True: err.append('FacebookAdvertiserIDCollectionEnabled true değil')
schemes = [s for t in d.get('CFBundleURLTypes', []) for s in t.get('CFBundleURLSchemes', [])]
if 'fb1879491072709561' not in schemes: err.append('URL şeması fb1879491072709561 yok')
ids = [i.get('SKAdNetworkIdentifier', '') for i in d.get('SKAdNetworkItems', [])]
for m in ('v9wttpbfk9.skadnetwork', 'n38lu8286q.skadnetwork', 'cstr6suwn9.skadnetwork'):
    if m not in ids: err.append('SKAdNetworkItems içinde %s yok' % m)
if len(ids) != len(set(ids)): err.append('SKAdNetworkItems tekrar içeriyor')
if not d.get('NSUserTrackingUsageDescription'): err.append('NSUserTrackingUsageDescription yok (ATT istemi çöker)')
if d.get('CFBundleIdentifier') not in ('com.snuglo.app', '$(PRODUCT_BUNDLE_IDENTIFIER)'): err.append('bundle id: %r' % d.get('CFBundleIdentifier'))
p = open(pbx, encoding='utf-8').read()
# RevenueCat yoksa Purchases cihazda satın almayı reddeder (bedava vermez) ama mağaza tamamen kapanır.
for needle, why in (('GodotxRevenueCat', 'RevenueCat çerçevesi'), ('RevenueCat.xcframework', 'RevenueCat SDK'),
                    ('FBSDKCoreKit.xcframework', 'Meta FBSDKCoreKit'), ('FBAEMKit.xcframework', 'Meta FBAEMKit'),
                    ('meta_sdk', 'MetaSDK eklentisi'), ('snuglo_bridge', 'SnugloBridge eklentisi'),
                    ('poing-godot-admob-ads', 'AdMob eklentisi'), ('admob_spm', 'AdMob SPM paketi (yama)'),
                    ('GodotApplePluginsGameCenter', 'Game Center GDExtension')):
    if needle not in p: err.append('pbxproj: %s yok (%s)' % (needle, why))
if 'PRODUCT_BUNDLE_IDENTIFIER = com.snuglo.app;' not in p and 'PRODUCT_BUNDLE_IDENTIFIER = "com.snuglo.app";' not in p:
    err.append('pbxproj bundle id com.snuglo.app değil')
if err:
    raise SystemExit('DUR:\n  - ' + '\n  - '.join(err))
print('   GADApplicationIdentifier =', gad)
print('   FacebookAppID =', d['FacebookAppID'], '| ClientToken =', d['FacebookClientToken'], '| URL şemaları =', schemes)
print('   SKAdNetworkItems =', len(ids), 'kimlik (Meta v9wttpbfk9 + n38lu8286q dahil)')
print('   pbxproj: RevenueCat, Meta, SnugloBridge, AdMob(+SPM), GameCenter tamam')
PYGATE

# Derlenmiş .app kapısı: Meta'nın gizlilik bildirimi + yetkiler (arşivde ve Debug'da aynı).
app_gate() {
	APP="$1"
	for fw in FBSDKCoreKit FBSDKCoreKit_Basics FBAEMKit; do
		[ -f "$APP/Frameworks/$fw.framework/PrivacyInfo.xcprivacy" ] || { echo "DUR: $fw PrivacyInfo.xcprivacy .app içinde yok"; exit 1; }
	done
	[ -f "$APP/PrivacyInfo.xcprivacy" ] || echo "   uyarı: uygulamanın kendi PrivacyInfo.xcprivacy'si yok"
	ENT="$(codesign -d --entitlements :- "$APP" 2>/dev/null || true)"
	echo "$ENT" | grep -q "com.apple.developer.game-center" || { echo "DUR: game-center yetkisi imzada yok"; exit 1; }
	echo "$ENT" | grep -q "com.apple.developer.ubiquity-kvstore-identifier" || { echo "DUR: iCloud KV yetkisi imzada yok (eski kayıt göçü)"; exit 1; }
	echo "   .app: FB PrivacyInfo x3, game-center + ubiquity-kvstore yetkileri tamam"
}

clean_dd() { rm -rf "$DD"; }

if [ "$MODE" = check ] || [ "$MODE" = dev ]; then
	if [ "$MODE" = dev ]; then
		if [ -z "$DEVICE" ]; then
			DEVICE="$(xcrun devicectl list devices 2>/dev/null | grep -E "[Ee]rgun.*iPhone" | grep -E "connected|available" | grep -oE "[0-9A-F]{8}-[0-9A-F]{16}" | head -1)"
		fi
		[ -n "$DEVICE" ] || { echo "DUR: Ergun's iPhone bağlı değil (xcrun devicectl list devices); DEVICE=<udid> ver"; exit 1; }
		DEST="id=$DEVICE"
	else
		DEST="generic/platform=iOS"
	fi
	echo "== 4/5 xcodebuild $CFG ($DEST) =="
	xcodebuild -project "$OUT/$NAME.xcodeproj" -scheme "$NAME" -configuration "$CFG" \
		-destination "$DEST" -derivedDataPath "$DD" -allowProvisioningUpdates \
		DEVELOPMENT_TEAM="$TEAM" build 2>&1 | tee "$OUT/xcodebuild.log" | grep -E "error:|warning: .*(snuglo|meta_sdk|SnugloBridge)|\*\* BUILD" || true
	grep -q "\*\* BUILD SUCCEEDED \*\*" "$OUT/xcodebuild.log" || { echo "DUR: derleme başarısız ($OUT/xcodebuild.log)"; exit 1; }
	APP="$(ls -d "$DD/Build/Products/$CFG-iphoneos/"*.app | head -1)"
	app_gate "$APP"
	if [ "$MODE" = dev ]; then
		echo "== 5/5 Kurulum + başlatma ($DEVICE) =="
		xcrun devicectl device install app --device "$DEVICE" "$APP"
		if [ -z "$NOLAUNCH" ]; then
			echo "   konsol (Ctrl-C ile çık; Meta: \"_eventName\" = \"fb_mobile_activate_app\", Flush Result : Success)"
			xcrun devicectl device process launch --console --terminate-existing --device "$DEVICE" "$BUNDLE" || true
		fi
	fi
	[ -n "$KEEP_DD" ] || clean_dd
	exit 0
fi

echo "== 4/5 Arşiv (Release) =="
rm -rf "$OUT/$NAME.xcarchive"
xcodebuild -project "$OUT/$NAME.xcodeproj" -scheme "$NAME" -configuration Release \
	-destination 'generic/platform=iOS' -derivedDataPath "$DD" \
	-archivePath "$OUT/$NAME.xcarchive" -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" archive
app_gate "$OUT/$NAME.xcarchive/Products/Applications/$NAME.app"
clean_dd

[ "$MODE" = upload ] && DESTN="upload" || DESTN="export"
echo "== 5/5 App Store dışa aktarımı ($DESTN) =="
cat > "$OUT/exportopts.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>teamID</key><string>$TEAM</string>
	<key>signingStyle</key><string>automatic</string>
	<key>uploadSymbols</key><true/>
	<key>destination</key><string>$DESTN</string>
</dict>
</plist>
PLIST
rm -rf "$OUT/export"
xcodebuild -exportArchive -archivePath "$OUT/$NAME.xcarchive" \
	-exportOptionsPlist "$OUT/exportopts.plist" -exportPath "$OUT/export" -allowProvisioningUpdates
if [ "$DESTN" = export ]; then
	cp "$OUT/export/$NAME.ipa" "$OUT/$NAME.ipa"
	echo "hazır: $OUT/$NAME.ipa  (yükleme: tools/ios_release.sh upload ya da Transporter)"
else
	echo "App Store Connect'e yüklendi; işlenmesi birkaç dakika sürer"
fi
