# Snuglo iOS integration (Godot 4.6 rewrite)

App Store ID 6772764229, bundle id `com.snuglo.app`, team K858B9M275. The live SwiftUI
version is 1.2.0 (6) (reference: `~/snuglo-main`). This rewrite ships as **2.0.0 (20)**.
Device family: iPhone only. Minimum iOS: 18.0 (same as the live app; every plugin supports it).

## Native pieces

| Piece | Where | Version | Preset key / how it's enabled | GDScript side |
|---|---|---|---|---|
| Meta App Events | `ios/plugins/meta_sdk` (.gdip, `name="MetaSDK"`) | FBSDKCoreKit, FBSDKCoreKit_Basics, FBAEMKit 18.1.1 (dynamic, **embedded**) + `meta_sdk.{debug,release}.xcframework` (static glue) | `plugins/MetaSDK=true` | none (starts by itself) |
| RevenueCat | `ios/plugins/revenue_cat` (.gdip, `name="GodotxRevenueCat"`) | GodotxRevenueCat + RevenueCat/RevenueCatUI xcframeworks (from ~/starwatch) | `plugins/GodotxRevenueCat=true` | `autoload/Purchases.gd` |
| SnugloBridge | `ios/plugins/snuglo_bridge` (.gdip, `name="SnugloBridge"`) | own ObjC++ (`src/snuglo_bridge.mm`), static, built against Godot 4.6-stable headers | `plugins/SnugloBridge=true` | `autoload/Save.gd` (legacy import), `Notify.gd`, `ads_admob.gd` (ATT) |
| AdMob + UMP | `addons/admob` (Poing 5.1.0, editor export plugin, not a .gdip) | Google Mobile Ads 13.9.0 + UMP 3.1.0 via Swift Package (`build/ios/admob_spm`) | `[editor_plugins]` in project.godot + `[admob] general/ios/app_id`; `plugins/AdMob=true` in the preset is informational (the export plugin is not gated by it) | `autoload/Ads.gd` + `autoload/ads_admob.gd` |
| Game Center | `addons/GodotApplePluginsGameCenter` + `addons/GodotApplePluginsRuntime` (GDExtension, MIT, build a6d667dd from ~/starwatch; simulator slices removed) | — | GDExtension (auto); `entitlements/game_center=true` | `autoload/GameCenter.gd` |

The preset keys must equal the `.gdip` `name` field, not the file name. A wrong key disables the
plugin silently (Kikko shipped free purchases that way). `tools/ios_release.sh` checks this.

### Meta (`meta_sdk.mm`)
* `isAutoLogAppEventsEnabled = YES`, `isAdvertiserIDCollectionEnabled = YES`, then
  `ApplicationDelegate application:didFinishLaunchingWithOptions:`.
* `fb_mobile_activate_app` (`activateApp`) runs on every `UIApplicationDidBecomeActiveNotification`,
  plus once immediately if the app is already active when the plugin starts.
* DEBUG variant (`meta_sdk.debug.xcframework`): `enableLoggingBehavior` AppEvents + NetworkRequests
  and `flush` after every activation, so the console shows `"_eventName" = "fb_mobile_activate_app"`
  and `Flush Result : Success`.
* Deep links `fb1879491072709561://` are passed to the SDK by swizzling the Godot app delegate's
  `application:openURL:options:`. The original implementation still runs after that.
* Purchases are **not** logged to Meta by hand. Auto-logging covers StoreKit purchases.
* No new ATT prompt is added for Meta. The app uses the live app's ATT prompt
  (`NSUserTrackingUsageDescription` = "To deliver personalized ads. You can opt out anytime in
  Settings."), which runs after the UMP consent form (`ads_admob.gd`).

### Where the Info.plist keys come from
* `FacebookAppID`, `FacebookClientToken`, `FacebookDisplayName`, `FacebookAutoLogAppEventsEnabled`,
  `FacebookAdvertiserIDCollectionEnabled`, `CFBundleURLTypes` (fb1879491072709561) come from the
  `[plist]` section of `meta_sdk.gdip`. CFBundleURLTypes is set only there.
* **SKAdNetworkItems**: there is ONE merged list (53 ids). It combines Google's AdMob list, the live
  app's list (`~/snuglo-main/SnugloApp/Info.plist`) and Meta's `v9wttpbfk9` + `n38lu8286q`, with
  duplicates removed. It lives in `addons/admob/ios/bin/ads/poing_godot_admob_ads.gd`
  `get_plist_content()`. `meta_sdk.gdip` must not contain it, because a second key would duplicate
  the entry. If you update the AdMob addon, put the merge back.
* `GADApplicationIdentifier` comes from project.godot `[admob] general/ios/app_id`. If it is empty,
  the app crashes on every launch, so the release script stops when it is wrong.
* `NSUserTrackingUsageDescription` and `ITSAppUsesNonExemptEncryption=false` come from the preset's
  `application/additional_plist_content`.
* The iCloud KV entitlement (`com.apple.developer.ubiquity-kvstore-identifier =
  K858B9M275.com.snuglo.app`, same as live) comes from `entitlements/additional`. It is needed so
  `SnugloBridge.ubiquitous_kv()` can still read the live app's CloudSync backup.

### SnugloBridge API (singleton `SnugloBridge`)
`legacy_defaults()`, `ubiquitous_kv()` (Dictionary of every `snuglo.*` key + the live @AppStorage
keys; NSData → PackedByteArray, NSDate → reference seconds), `request_permission()` → signal
`permission_result(granted)`, `refresh_authorization()` → `authorization_status(status)`,
`schedule_daily(hour, minute, title, body)` (id `snuglo.daily.reminder`),
`schedule_in(seconds, id, title, body)`, `cancel(id)`, `cancel_all()`, `tracking_status()`,
`request_tracking()` → `tracking_result(status)`. It also sets a UNUserNotificationCenter delegate
so banners show in the foreground, like the live app.

On the first launch on iOS, `Save` merges UserDefaults with iCloud KV using the live app's CloudSync
rule (the source with the higher `snuglo.cloud.rev` wins). It then calls `import_legacy()` once. If
the old app had premium, remove-ads or purchased flags, `Purchases` runs one silent RevenueCat
restore. Until that finishes, a "no entitlement" answer from RC does not remove the imported
entitlement. RevenueCat reuses the live app's anonymous app user id, which RC keeps in the same
NSUserDefaults.

### Purchases safety
Free "debug" grants happen only in a **desktop** debug build. On iOS/Android, a missing store
singleton makes every purchase fail with an error, in both debug and release builds.

## Rebuilding the native plugins
```
tools/build_meta_sdk.sh        # meta_sdk.mm → meta_sdk.{debug,release}.xcframework
tools/build_snuglo_bridge.sh   # snuglo_bridge.mm → snuglo_bridge.{debug,release}.xcframework
python3 tools/slim_ios_plugins.py <dir>   # strip non-ios-arm64 slices from new SDK drops
```
`build_snuglo_bridge.sh` downloads Godot 4.6-stable source to `~/.cache/godot-src` on first use and
generates the three `*.gen.h` headers with SCons in a venv there. When the engine/export templates
are upgraded, rebuild with a matching `GODOT_TAG`, because the Object layout must match the template.

## Release chain (`tools/ios_release.sh`, export_project_only=true)
```
tools/ios_release.sh check    # debug export → SPM patch → gates → generic-iOS Debug build
tools/ios_release.sh dev      # same, then install + launch on "Ergun's iPhone" with console (DEVICE=<udid> overrides)
tools/ios_release.sh export   # release export → gates → archive → App Store ipa in build/ios/Snuglo.ipa
tools/ios_release.sh upload   # export + upload to App Store Connect (run it yourself)
```
Gates that run before the archive step: the preset plugin keys match the .gdip names; plugin
binaries are present; the AdMob app id is real. In the generated Info.plist: exactly one each of
SKAdNetworkItems, CFBundleURLTypes, GADApplicationIdentifier and FacebookAppID; correct Facebook
keys and URL scheme; Meta SKAdNetwork ids present; ATT text present. In the pbxproj: RevenueCat,
FBSDK, meta_sdk, snuglo_bridge, AdMob + `admob_spm`, GameCenter. Gates on the built `.app`:
FBSDKCoreKit/_Basics/FBAEMKit `PrivacyInfo.xcprivacy` present, and the signature contains the
game-center + ubiquity-kvstore entitlements. The empty camera/microphone/photo usage strings that
Godot always adds are removed. DerivedData (`build/ios/DerivedData`, ~750 MB) is deleted after each
run (`KEEP_DD=1` keeps it).

Before every upload, bump `application/version` in `export_presets.cfg`.

## App Store Connect → App Privacy (changes for Meta)
The live app already ships AdMob (with the ATT prompt) and RevenueCat. Adding the Meta SDK with
App Events auto-logging and advertiser-ID collection turned on means these entries must be declared
or confirmed, based on Meta's "Apple App Store Privacy Details" guidance for the Facebook SDK:

* **Identifiers → Device ID**: purposes **Third-Party Advertising** and **Analytics**.
  * Linked to the user: **No**. The app has no Facebook Login and no account, and Meta's guidance
    for App Events without Login is "not linked".
  * Used for tracking: **Yes**. The IDFA is sent to Meta for ad attribution, but only when the user
    allowed ATT. Apple's form has no "only if allowed" answer: if the data can be used for
    tracking when permission is given, the answer is Yes. It was already Yes for AdMob.
* **Usage Data → Product Interaction**: app launches/activations and auto-logged events. Purposes
  **Analytics** and **Third-Party Advertising**. Linked: No. Tracking: Yes (Meta uses it for ad
  measurement/optimization).
* **Purchases → Purchase History**: auto-logged in-app purchase events. Purposes **Analytics** and
  **Third-Party Advertising**. Linked: No. Tracking: Yes. Remove it only if you turn off
  auto-logging of purchases in the Meta dashboard (App Events → automatic in-app purchase logging).
* Keep whatever AdMob/RevenueCat entries are already there: Advertising Data, Device ID, Product
  Interaction, Purchase History, Crash/Performance data as currently declared.

Check the current declarations in ASC (App Privacy page). They are not in this repo, so add only
what is missing. The SDK's own `PrivacyInfo.xcprivacy` files are embedded in the app, and Apple
cross-checks them against these answers.
