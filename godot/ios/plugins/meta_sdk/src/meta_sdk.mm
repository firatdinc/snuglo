// MetaSDK: Meta (Facebook) App Events for Snuglo, for iOS 14+ app install ads (activation +
// SKAdNetwork). No Login/Share/Graph API and no GDScript API: the plugin starts the SDK on its own.
// App ID / client token / URL scheme come from Info.plist ([plist] in meta_sdk.gdip).
// Built twice by tools/build_meta_sdk.sh: meta_sdk.debug (DEBUG=1, App Events logging) and meta_sdk.release.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
@import FBSDKCoreKit;

static IMP original_open_url = NULL;
static id active_observer = nil;

// fb<appid>:// links from Meta ads: the SDK reads campaign ids from the URL, then the existing
// delegate implementation (if any) still runs so other URL handling keeps working.
static BOOL meta_open_url(id self, SEL _cmd, UIApplication *app, NSURL *url, NSDictionary *options) {
	BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:app openURL:url options:options];
	if (original_open_url) {
		handled = reinterpret_cast<BOOL (*)(id, SEL, UIApplication *, NSURL *, NSDictionary *)>(original_open_url)(self, _cmd, app, url, options) || handled;
	}
	return handled;
}

static void hook_open_url(void) {
	Class cls = [[UIApplication sharedApplication].delegate class];
	if (cls == nil || original_open_url != NULL) {
		return;
	}
	SEL sel = @selector(application:openURL:options:);
	Method m = class_getInstanceMethod(cls, sel);
	if (m) {
		original_open_url = method_setImplementation(m, (IMP)meta_open_url);
	} else {
		class_addMethod(cls, sel, (IMP)meta_open_url, "B@:@@@");
	}
}

static CFAbsoluteTime last_activate = 0;
static id scene_observer = nil;

// Godot 4.6 is scene-based (SwiftUI): the app-level didBecomeActive can fire before this plugin
// registers, so scene activation is observed too, plus a delayed safety call. A 2 s guard keeps
// the overlapping signals to one activate per foreground.
static void activate(void) {
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	if (now - last_activate < 2.0) {
		return;
	}
	last_activate = now;
	NSLog(@"MetaSDK: activateApp");
	[[FBSDKAppEvents shared] activateApp];
#ifdef DEBUG
	[[FBSDKAppEvents shared] flush];
#endif
}

void initialize_meta_sdk_module() {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIApplication *app = [UIApplication sharedApplication];
		FBSDKSettings *settings = [FBSDKSettings sharedSettings];
		settings.isAutoLogAppEventsEnabled = YES;
		settings.isAdvertiserIDCollectionEnabled = YES;
#ifdef DEBUG
		[settings enableLoggingBehavior:FBSDKLoggingBehaviorAppEvents];
		[settings enableLoggingBehavior:FBSDKLoggingBehaviorNetworkRequests];
#endif
		[[FBSDKApplicationDelegate sharedInstance] application:app didFinishLaunchingWithOptions:nil];
		hook_open_url();
		// Events Manager only sees the app once fb_mobile_activate_app arrives: log it on every
		// foreground, and once now because the first didBecomeActive may already have fired.
		active_observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
				object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *) { activate(); }];
		scene_observer = [[NSNotificationCenter defaultCenter] addObserverForName:UISceneDidActivateNotification
				object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *) { activate(); }];
		if (app.applicationState == UIApplicationStateActive) {
			activate();
		}
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && last_activate == 0) {
				activate();
			}
		});
	});
}

void uninitialize_meta_sdk_module() {
	if (active_observer) {
		[[NSNotificationCenter defaultCenter] removeObserver:active_observer];
		active_observer = nil;
	}
	if (scene_observer) {
		[[NSNotificationCenter defaultCenter] removeObserver:scene_observer];
		scene_observer = nil;
	}
}
