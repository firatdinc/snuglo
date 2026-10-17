// SnugloBridge: small native helpers the Godot rewrite needs from iOS, exposed as the engine
// singleton "SnugloBridge" (Engine.get_singleton("SnugloBridge")).
//
//   legacy_defaults() -> Dictionary   NSUserDefaults of the live SwiftUI app (v1.2.0, same bundle id):
//                                     every "snuglo.*" key + the @AppStorage keys. NSData -> PackedByteArray.
//   ubiquitous_kv() -> Dictionary     NSUbiquitousKeyValueStore (CloudSync iCloud backup), same filter. Read-only.
//   request_permission()              UNUserNotificationCenter auth -> signal permission_result(granted)
//   refresh_authorization()           -> signal authorization_status(status)  (UNAuthorizationStatus raw value)
//   schedule_daily(hour, minute, title, body)   repeating calendar trigger, id "snuglo.daily.reminder"
//   schedule_in(seconds, id, title, body)       one-shot time-interval trigger
//   cancel(id) / cancel_all()
//   tracking_status() -> int          ATTrackingManager status (0 undetermined, 1 restricted, 2 denied, 3 authorized)
//   request_tracking()                ATT prompt (text = NSUserTrackingUsageDescription) -> signal tracking_result(status)
//   cloud_save(key, json) / cloud_load(key) -> String   v2 save backup in NSUbiquitousKeyValueStore
//   request_review()                  SKStoreReviewController on the foreground-active window scene
//   share(text, image_path)           UIActivityViewController (image_path: absolute path or "")
//   decode_plist(bytes) -> Variant    NSPropertyListSerialization (1.2.0 SaveTransfer codes); null if invalid
//
// Built by tools/build_snuglo_bridge.sh against Godot 4.6-stable headers into
// snuglo_bridge.{debug,release}.xcframework (debug = DEBUG_ENABLED, like the engine template).

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <unistd.h>
#import <UserNotifications/UserNotifications.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <StoreKit/StoreKit.h>

#include "core/config/engine.h"
#include "core/object/class_db.h"
#include "core/object/object.h"
#include "core/variant/array.h"
#include "core/variant/dictionary.h"
#include "core/variant/variant.h"

static NSString *const kDailyId = @"snuglo.daily.reminder";

// @AppStorage / bare UserDefaults keys of the live app (grep @AppStorage + SaveTransfer.keys).
static NSArray<NSString *> *legacy_plain_keys() {
	return @[ @"appTheme", @"blockSkin", @"boardBackground", @"coachShown", @"colorblindMode",
		@"comebackRemindersEnabled", @"dailyReminderEnabled", @"dailyReminderTime", @"hapticLevel",
		@"hapticsEnabled", @"hasOnboarded", @"hasRequestedReview", @"musicEnabled", @"musicTrack",
		@"musicVolume", @"sfxEnabled", @"sfxVolume", @"soundPack", @"zenMode" ];
}

static bool wanted_key(NSString *key) {
	return [key hasPrefix:@"snuglo."] || [legacy_plain_keys() containsObject:key];
}

static String to_gd_string(NSString *s) {
	return s ? String::utf8([s UTF8String]) : String();
}

static Variant to_variant(id v) {
	if (v == nil || v == [NSNull null]) {
		return Variant();
	}
	if ([v isKindOfClass:[NSString class]]) {
		return to_gd_string((NSString *)v);
	}
	if ([v isKindOfClass:[NSNumber class]]) {
		NSNumber *n = (NSNumber *)v;
		if (CFGetTypeID((__bridge CFTypeRef)n) == CFBooleanGetTypeID()) {
			return (bool)n.boolValue;
		}
		const char *t = n.objCType;
		if (t && (t[0] == 'd' || t[0] == 'f')) {
			return n.doubleValue;
		}
		return (int64_t)n.longLongValue;
	}
	if ([v isKindOfClass:[NSData class]]) {
		NSData *d = (NSData *)v;
		PackedByteArray out;
		out.resize((int)d.length);
		if (d.length > 0) {
			memcpy(out.ptrw(), d.bytes, d.length);
		}
		return out;
	}
	if ([v isKindOfClass:[NSDate class]]) {
		// Swift Date reference seconds (2001-01-01), same as Codable's default JSON dates.
		return ((NSDate *)v).timeIntervalSinceReferenceDate;
	}
	if ([v isKindOfClass:[NSArray class]]) {
		Array a;
		for (id e in (NSArray *)v) {
			a.push_back(to_variant(e));
		}
		return a;
	}
	if ([v isKindOfClass:[NSDictionary class]]) {
		Dictionary dict;
		NSDictionary *src = (NSDictionary *)v;
		for (id k in src) {
			dict[to_gd_string([k description])] = to_variant(src[k]);
		}
		return dict;
	}
	return to_gd_string([v description]);
}

static Dictionary filtered(NSDictionary *src) {
	Dictionary out;
	for (NSString *key in src) {
		if ([key isKindOfClass:[NSString class]] && wanted_key(key)) {
			out[to_gd_string(key)] = to_variant(src[key]);
		}
	}
	return out;
}

@interface SnugloNotificationDelegate : NSObject <UNUserNotificationCenterDelegate>
@end

@implementation SnugloNotificationDelegate
// Same as the live NotificationService: show the banner even while the game is open.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
		willPresentNotification:(UNNotification *)notification
		  withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
	completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}
@end

class SnugloBridge : public Object {
	GDCLASS(SnugloBridge, Object);

	static SnugloBridge *singleton;

protected:
	static void _bind_methods() {
		ClassDB::bind_method(D_METHOD("legacy_defaults"), &SnugloBridge::legacy_defaults);
		ClassDB::bind_method(D_METHOD("ubiquitous_kv"), &SnugloBridge::ubiquitous_kv);
		ClassDB::bind_method(D_METHOD("request_permission"), &SnugloBridge::request_permission);
		ClassDB::bind_method(D_METHOD("refresh_authorization"), &SnugloBridge::refresh_authorization);
		ClassDB::bind_method(D_METHOD("schedule_daily", "hour", "minute", "title", "body"), &SnugloBridge::schedule_daily);
		ClassDB::bind_method(D_METHOD("schedule_in", "seconds", "id", "title", "body"), &SnugloBridge::schedule_in);
		ClassDB::bind_method(D_METHOD("cancel", "id"), &SnugloBridge::cancel);
		ClassDB::bind_method(D_METHOD("cancel_all"), &SnugloBridge::cancel_all);
		ClassDB::bind_method(D_METHOD("tracking_status"), &SnugloBridge::tracking_status);
		ClassDB::bind_method(D_METHOD("request_tracking"), &SnugloBridge::request_tracking);
		ClassDB::bind_method(D_METHOD("haptic", "kind"), &SnugloBridge::haptic);
		ClassDB::bind_method(D_METHOD("cloud_save", "key", "json"), &SnugloBridge::cloud_save);
		ClassDB::bind_method(D_METHOD("cloud_load", "key"), &SnugloBridge::cloud_load);
		ClassDB::bind_method(D_METHOD("request_review"), &SnugloBridge::request_review);
		ClassDB::bind_method(D_METHOD("share", "text", "image_path"), &SnugloBridge::share);
		ClassDB::bind_method(D_METHOD("decode_plist", "bytes"), &SnugloBridge::decode_plist);
		ADD_SIGNAL(MethodInfo("permission_result", PropertyInfo(Variant::BOOL, "granted")));
		ADD_SIGNAL(MethodInfo("authorization_status", PropertyInfo(Variant::INT, "status")));
		ADD_SIGNAL(MethodInfo("tracking_result", PropertyInfo(Variant::INT, "status")));
	}

public:
	static SnugloBridge *get_singleton() { return singleton; }

	// Godot's vibrate_handheld fails on device ("Could not vibrate using haptic engine"),
	// so the game uses UIKit feedback generators like the live SwiftUI HapticService.
	// kind: tick | light | medium | heavy | success | error
	void haptic(String kind) {
		NSString *k = [NSString stringWithUTF8String:kind.utf8().get_data()];
		dispatch_async(dispatch_get_main_queue(), ^{
			if ([k isEqualToString:@"tick"]) {
				static UISelectionFeedbackGenerator *sel = [UISelectionFeedbackGenerator new];
				[sel selectionChanged];
				[sel prepare];
			} else if ([k isEqualToString:@"success"] || [k isEqualToString:@"error"]) {
				static UINotificationFeedbackGenerator *note = [UINotificationFeedbackGenerator new];
				[note notificationOccurred:[k isEqualToString:@"success"] ? UINotificationFeedbackTypeSuccess : UINotificationFeedbackTypeError];
			} else {
				static UIImpactFeedbackGenerator *light = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
				static UIImpactFeedbackGenerator *medium = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
				static UIImpactFeedbackGenerator *heavy = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
				UIImpactFeedbackGenerator *g = [k isEqualToString:@"heavy"] ? heavy : ([k isEqualToString:@"medium"] ? medium : light);
				[g impactOccurred];
				[g prepare];
			}
		});
	}

	void cloud_save(String key, String json) {
		NSUbiquitousKeyValueStore *kv = [NSUbiquitousKeyValueStore defaultStore];
		[kv setString:ns(json) forKey:ns(key)];
		[kv synchronize];
	}

	String cloud_load(String key) {
		NSUbiquitousKeyValueStore *kv = [NSUbiquitousKeyValueStore defaultStore];
		[kv synchronize];
		return to_gd_string([kv stringForKey:ns(key)]);
	}

	void request_review() {
		dispatch_async(dispatch_get_main_queue(), ^{
			UIWindowScene *scene = active_scene();
			if (scene) {
				[SKStoreReviewController requestReviewInScene:scene];
			}
		});
	}

	void share(String text, String image_path) {
		NSString *t = ns(text);
		NSString *path = ns(image_path);
		dispatch_async(dispatch_get_main_queue(), ^{
			NSMutableArray *items = [NSMutableArray array];
			if (path.length > 0) {
				UIImage *img = [UIImage imageWithContentsOfFile:path];
				if (img) {
					[items addObject:img];
				}
			}
			if (t.length > 0) {
				[items addObject:t];
			}
			UIViewController *top = top_controller();
			if (items.count == 0 || top == nil) {
				return;
			}
			UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
			UIPopoverPresentationController *pop = vc.popoverPresentationController;
			if (pop) {
				pop.sourceView = top.view;
				pop.sourceRect = CGRectMake(CGRectGetMidX(top.view.bounds), CGRectGetMidY(top.view.bounds), 1, 1);
				pop.permittedArrowDirections = 0;
			}
			[top presentViewController:vc animated:YES completion:nil];
		});
	}

	Variant decode_plist(PackedByteArray bytes) {
		if (bytes.is_empty()) {
			return Variant();
		}
		NSData *data = [NSData dataWithBytes:bytes.ptr() length:bytes.size()];
		NSError *err = nil;
		id obj = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&err];
		if (obj == nil || err) {
			return Variant();
		}
		return to_variant(obj);
	}

	Dictionary legacy_defaults() {
		return filtered([[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
	}

	Dictionary ubiquitous_kv() {
		NSUbiquitousKeyValueStore *kv = [NSUbiquitousKeyValueStore defaultStore];
		[kv synchronize];
		return filtered([kv dictionaryRepresentation]);
	}

	// Mirrors DailyReminderService.requestAuthorization: denied -> false without a prompt,
	// already allowed -> true, otherwise ask.
	void request_permission() {
		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
		[center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
			UNAuthorizationStatus st = settings.authorizationStatus;
			if (st == UNAuthorizationStatusDenied) {
				emit_main("permission_result", false);
			} else if (st == UNAuthorizationStatusAuthorized || st == UNAuthorizationStatusProvisional || st == UNAuthorizationStatusEphemeral) {
				emit_main("permission_result", true);
			} else {
				[center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
									  completionHandler:^(BOOL granted, NSError *error) {
										  emit_main("permission_result", (bool)granted);
									  }];
			}
		}];
	}

	void refresh_authorization() {
		[[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
			emit_main("authorization_status", (int64_t)settings.authorizationStatus);
		}];
	}

	void schedule_daily(int hour, int minute, String title, String body) {
		NSDateComponents *comps = [[NSDateComponents alloc] init];
		comps.hour = hour;
		comps.minute = minute;
		UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:comps repeats:YES];
		add_request(kDailyId, title, body, trigger);
	}

	void schedule_in(double seconds, String id, String title, String body) {
		UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:MAX(1.0, seconds) repeats:NO];
		add_request(ns(id), title, body, trigger);
	}

	void cancel(String id) {
		[[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:@[ ns(id) ]];
	}

	void cancel_all() {
		[[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
	}

	int tracking_status() {
		if (@available(iOS 14, *)) {
			return (int)[ATTrackingManager trackingAuthorizationStatus];
		}
		return 3;
	}

	void request_tracking() {
		if (@available(iOS 14, *)) {
			// The system only shows the prompt while the app is active; callers ask after launch.
			[ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
				emit_main("tracking_result", (int64_t)status);
			}];
		} else {
			emit_main("tracking_result", (int64_t)3);
		}
	}

	SnugloBridge() { singleton = this; }
	~SnugloBridge() {
		if (singleton == this) {
			singleton = nullptr;
		}
	}

private:
	static UIWindowScene *active_scene() {
		UIWindowScene *fallback = nil;
		for (UIScene *sc in [UIApplication sharedApplication].connectedScenes) {
			if (![sc isKindOfClass:[UIWindowScene class]]) {
				continue;
			}
			if (sc.activationState == UISceneActivationStateForegroundActive) {
				return (UIWindowScene *)sc;
			}
			fallback = (UIWindowScene *)sc;
		}
		return fallback;
	}

	static UIViewController *top_controller() {
		UIWindowScene *scene = active_scene();
		UIWindow *win = nil;
		for (UIWindow *w in scene.windows) {
			if (w.isKeyWindow) {
				win = w;
				break;
			}
		}
		if (win == nil) {
			win = scene.windows.firstObject;
		}
		UIViewController *vc = win.rootViewController;
		while (vc.presentedViewController && !vc.presentedViewController.isBeingDismissed) {
			vc = vc.presentedViewController;
		}
		return vc;
	}

	static NSString *ns(const String &s) {
		return [NSString stringWithUTF8String:s.utf8().get_data()];
	}

	static void add_request(NSString *rid, const String &title, const String &body, UNNotificationTrigger *trigger) {
		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
		[center removePendingNotificationRequestsWithIdentifiers:@[ rid ]];
		UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
		content.title = ns(title);
		content.body = ns(body);
		content.sound = [UNNotificationSound defaultSound];
		UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:rid content:content trigger:trigger];
		[center addNotificationRequest:req withCompletionHandler:^(NSError *error) {
			if (error) {
				NSLog(@"[SnugloBridge] schedule %@ failed: %@", rid, error);
			}
		}];
	}

	// UN/ATT completion handlers run on background queues; signals must fire on the main (engine) thread.
	template <typename T>
	static void emit_main(const char *sig, T value) {
		Variant v = value;
		StringName name = sig;
		dispatch_async(dispatch_get_main_queue(), ^{
			if (singleton) {
				singleton->emit_signal(name, v);
			}
		});
	}
};

SnugloBridge *SnugloBridge::singleton = nullptr;

static SnugloBridge *bridge = nullptr;
static SnugloNotificationDelegate *notification_delegate = nil;

// Godot 4.6 crashes on force-quit: applicationWillTerminate -> Main::cleanup -> GDScript::clear
// destroys lambda Callables whose recursive_mutex is already gone ("recursive_mutex lock failed",
// SIGABRT, crash report on every swipe-kill). The save is already flushed when the app is paused
// (Save.gd on NOTIFICATION_APPLICATION_PAUSED / FOCUS_OUT), so on terminate we skip the engine
// teardown and exit cleanly. UIKit observers of
// UIApplicationWillTerminateNotification (e.g. SDKs) still get the notification before exit.
static void snuglo_will_terminate(id self, SEL _cmd, UIApplication *app) {
	[[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:app];
	[[NSUserDefaults standardUserDefaults] synchronize];
	_exit(0);
}

static void hook_terminate(void) {
	Class cls = [[UIApplication sharedApplication].delegate class];
	if (cls == nil) {
		return;
	}
	SEL sel = @selector(applicationWillTerminate:);
	Method m = class_getInstanceMethod(cls, sel);
	if (m) {
		method_setImplementation(m, (IMP)snuglo_will_terminate);
	} else {
		class_addMethod(cls, sel, (IMP)snuglo_will_terminate, "v@:@");
	}
}

void initialize_snuglo_bridge_module() {
	dispatch_async(dispatch_get_main_queue(), ^{ hook_terminate(); });
	bridge = memnew(SnugloBridge);
	Engine::get_singleton()->add_singleton(Engine::Singleton("SnugloBridge", bridge));
	notification_delegate = [[SnugloNotificationDelegate alloc] init];
	[UNUserNotificationCenter currentNotificationCenter].delegate = notification_delegate;
}

void uninitialize_snuglo_bridge_module() {
	if (bridge) {
		memdelete(bridge);
		bridge = nullptr;
	}
	notification_delegate = nil;
}
