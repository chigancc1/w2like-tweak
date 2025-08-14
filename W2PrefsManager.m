\
#import "W2PrefsManager.h"
#import <notify.h>

static NSString *const kDomain = @"com.w2like.prefs";
static NSString *const kEnabled = @"Enabled";
static NSString *const kOverlayOnly = @"OverlayOnly";
static NSString *const kVideoPath = @"VideoPath";
static NSString *const kAllowed = @"Allowed";

@implementation W2PrefsManager {
    NSDictionary *_cache;
}

+ (instancetype)shared {
    static W2PrefsManager *S; static dispatch_once_t once;
    dispatch_once(&once, ^{ S = [self new]; [S _reload]; });
    return S;
}

- (instancetype)init {
    if ((self = [super init])) {
        int token = 0;
        notify_register_dispatch("com.w2like.prefschanged", &token, dispatch_get_main_queue(), ^(int t){
            [self _reload];
        });
    }
    return self;
}

- (void)_reload {
    CFArrayRef keys = (__bridge CFArrayRef)@[kEnabled, kOverlayOnly, kVideoPath, kAllowed];
    CFDictionaryRef dict = CFPreferencesCopyMultiple(keys, (__bridge CFStringRef)kDomain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    _cache = CFBridgingRelease(dict) ?: @{};
}

- (BOOL)enabled { return [_cache[kEnabled] ?: @NO boolValue]; }
- (BOOL)overlayOnly { return [_cache[kOverlayOnly] ?: @NO boolValue]; }
- (NSString *)videoPath {
    NSString *p = _cache[kVideoPath]; 
    if (p.length == 0) p = @"/var/mobile/Media/W2Like/clip.mp4";
    return p;
}
- (NSArray<NSString *> *)allowedApps {
    NSArray *a = _cache[kAllowed];
    if (a.count == 0) a = @[@"Instagram", @"TikTok", @"Facebook", @"Camera"];
    return a;
}
- (BOOL)isAllowedForProcess:(NSString *)proc {
    return [[self.allowedApps valueForKey:@"lowercaseString"] containsObject:proc.lowercaseString];
}

@end
