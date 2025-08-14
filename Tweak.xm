\
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "W2AssetReader.h"
#import "W2PrefsManager.h"

// Shared media reader so audio & video stay in sync
static W2AssetReader *W2SharedReader(void) {
    static dispatch_once_t once;
    static W2AssetReader *S;
    dispatch_once(&once, ^{
        S = [[W2AssetReader alloc] initWithPath:[W2PrefsManager shared].videoPath];
    });
    return S;
}


// Simple logger
#define W2Log(...) NSLog(@"[W2Like] " __VA_ARGS__)

// Associated keys
static const void *kW2ProxyKey = &kW2ProxyKey;

@interface W2Proxy : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic, weak) id real;
@property(nonatomic, strong) W2AssetReader *reader;
@property(nonatomic, assign) BOOL enabled;
@property(nonatomic, assign) BOOL overlayOnly;
@end

@implementation W2Proxy

- (instancetype)initWithReal:(id)real queue:(dispatch_queue_t)q {
    if ((self = [super init])) {
        _real = real;
        _enabled = [W2PrefsManager shared].enabled;
        _overlayOnly = [W2PrefsManager shared].overlayOnly;
        NSString *path = [W2PrefsManager shared].videoPath;
        _reader = W2SharedReader();
        // Observe changes live
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_prefsChanged) name:@"com.w2like.prefschanged" object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_prefsChanged {
    self.enabled = [W2PrefsManager shared].enabled;
    self.overlayOnly = [W2PrefsManager shared].overlayOnly;
    NSString *path = [W2PrefsManager shared].videoPath;
    [self.reader updatePath:path];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!self.enabled || self.overlayOnly) {
        if ([_real respondsToSelector:_cmd]) {
            [_real captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
        return;
    }
    CMSampleBufferRef fake = [self.reader nextVideoSampleLike:sampleBuffer];
    if (fake) {
        if ([_real respondsToSelector:_cmd]) {
            [_real captureOutput:output didOutputSampleBuffer:fake fromConnection:connection];
        }
        CFRelease(fake);
        return;
    }
    // fallback to real if reader is not ready
    if ([_real respondsToSelector:_cmd]) {
        [_real captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    }
}

@end

%hook AVCaptureVideoDataOutput

- (void)setSampleBufferDelegate:(id)sampleBufferDelegate queue:(dispatch_queue_t)sampleBufferCallbackQueue {
    if (!sampleBufferDelegate) { %orig; return; }
    // Per-app allow list
    NSString *proc = [[NSProcessInfo processInfo] processName];
    if (![[W2PrefsManager shared] isAllowedForProcess:proc]) {
        %orig;
        return;
    }
    W2Proxy *proxy = objc_getAssociatedObject(self, kW2ProxyKey);
    if (!proxy) {
        proxy = [[W2Proxy alloc] initWithReal:sampleBufferDelegate queue:sampleBufferCallbackQueue];
        objc_setAssociatedObject(self, kW2ProxyKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        W2Log(@"Injected proxy into %@", proc);
    } else {
        proxy.real = sampleBufferDelegate;
    }
    %orig(proxy, sampleBufferCallbackQueue);
}

%end

// -------- Optional preview overlay for Camera app --------

@interface W2OverlayWindow : UIWindow
@end
@implementation W2OverlayWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event { return NO; } // pass touches through
@end

static W2OverlayWindow *gOverlay;
static AVPlayer *gPlayer;

static void W2_showOverlayIfNeeded() {
    if (![W2PrefsManager shared].overlayOnly) return;
    NSString *proc = [[NSProcessInfo processInfo] processName];
    if (![[@[@"Camera"] mutableCopy] containsObject:proc]) return;
    if (gOverlay) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        gOverlay = [[W2OverlayWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        gOverlay.windowLevel = UIWindowLevelStatusBar + 1000;
        gOverlay.hidden = NO;
        UIViewController *vc = [UIViewController new];
        gOverlay.rootViewController = vc;
        NSString *path = [W2PrefsManager shared].videoPath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            gPlayer = [AVPlayer playerWithURL:[NSURL fileURLWithPath:path]];
            AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:gPlayer];
            layer.frame = vc.view.bounds;
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            [vc.view.layer addSublayer:layer];
            [gPlayer play];
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *n){ [gPlayer play]; }];
        }
    });
}

%hook UIApplication
- (void)didFinishLaunching {
    %orig;
    W2_showOverlayIfNeeded();
}
%end



// ====== AUDIO INJECTION ======

@interface W2AudioProxy : NSObject<AVCaptureAudioDataOutputSampleBufferDelegate>
@property(nonatomic, weak) id real;
@property(nonatomic, strong) W2AssetReader *reader; // reuse for audio? could be separate reader
@property(nonatomic, assign) BOOL enabled;
@end

@implementation W2AudioProxy

- (instancetype)initWithReal:(id)real {
    if ((self = [super init])) {
        _real = real;
        _enabled = [W2PrefsManager shared].enabled;
        NSString *path = [W2PrefsManager shared].videoPath;
        _reader = W2SharedReader();
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_prefsChanged) name:@"com.w2like.prefschanged" object:nil];
    }
    return self;
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)_prefsChanged {
    self.enabled = [W2PrefsManager shared].enabled;
    NSString *path = [W2PrefsManager shared].videoPath;
    [self.reader updatePath:path];
}
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!self.enabled) {
        if ([_real respondsToSelector:_cmd]) {
            [_real captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
        return;
    }
    // Here we'd get the next audio sample buffer from the video's audio track (needs audio-capable reader)
    // For simplicity in this skeleton, we reuse the video reader - in production, create separate audio reader.
    CMSampleBufferRef fakeAudio = [self.reader nextAudioSampleLike:sampleBuffer]
    if (fakeAudio) {
        if ([_real respondsToSelector:_cmd]) {
            [_real captureOutput:output didOutputSampleBuffer:fakeAudio fromConnection:connection];
        }
        CFRelease(fakeAudio);
    } else {
        if ([_real respondsToSelector:_cmd]) {
            [_real captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
}

@end

%hook AVCaptureAudioDataOutput

- (void)setSampleBufferDelegate:(id)sampleBufferDelegate queue:(dispatch_queue_t)sampleBufferCallbackQueue {
    if (!sampleBufferDelegate) { %orig; return; }
    NSString *proc = [[NSProcessInfo processInfo] processName];
    if (![[W2PrefsManager shared] isAllowedForProcess:proc]) {
        %orig;
        return;
    }
    W2AudioProxy *proxy = [[W2AudioProxy alloc] initWithReal:sampleBufferDelegate];
    %orig(proxy, sampleBufferCallbackQueue);
}

%end




// ====== Volume double-tap toggle ======
#import <notify.h>
#import <dlfcn.h>

static CFAbsoluteTime lastVolTap = 0;
static int volTapCount = 0;

static void W2ToggleEnabled(void) {
    BOOL cur = [W2PrefsManager shared].enabled;
    CFPreferencesSetAppValue(CFSTR("Enabled"), (__bridge CFPropertyListRef)@(!cur), CFSTR("com.w2like.prefs"));
    CFPreferencesAppSynchronize(CFSTR("com.w2like.prefs"));
    notify_post("com.w2like.prefschanged");
    NSLog(@"[W2Like] Volume double-tap -> %@", cur ? @"DISABLED" : @"ENABLED");
}

static void volumeChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (now - lastVolTap < 0.5) {
        volTapCount++;
        if (volTapCount == 2) {
            volTapCount = 0;
            W2ToggleEnabled();
        }
    } else {
        volTapCount = 1;
    }
    lastVolTap = now;
}

static void W2InstallVolumeToggle(void) {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, volumeChanged, CFSTR("com.apple.springboard.hasBlankedScreen"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    // Above is placeholder; actual volume event: "com.apple.mediaremote.tapticVolumeUp" / "Down" not public; alternative: observe system volume change
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, volumeChanged, CFSTR("com.apple.springboard.volume.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

%ctor {
    W2InstallVolumeToggle();
}


// ====== VOLUME DOUBLE-TAP TOGGLE ======
// Observes Darwin notification for system volume changes.
// Two changes within 500ms => toggle Enable and broadcast prefs changed.

static CFAbsoluteTime W2_lastVolEvent = 0;

static void W2ToggleEnabled(void) {
    // Flip Enabled in prefs domain
    Boolean enabled = [[W2PrefsManager shared] enabled];
    CFPreferencesSetAppValue(CFSTR("Enabled"), enabled ? kCFBooleanFalse : kCFBooleanTrue, CFSTR("com.w2like.prefs"));
    CFPreferencesAppSynchronize(CFSTR("com.w2like.prefs"));
    notify_post("com.w2like.prefschanged");
    NSLog(@"[W2Like] Toggled Enabled => %d", !enabled);
}

static void W2VolumeChangedDarwin(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (now - W2_lastVolEvent < 0.5) {
        // Double-tap detected
        W2ToggleEnabled();
        W2_lastVolEvent = 0; // reset
    } else {
        W2_lastVolEvent = now;
    }
}

static void W2InstallVolumeDoubleTapToggle(void) {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    W2VolumeChangedDarwin,
                                    CFSTR("AVSystemController_SystemVolumeDidChangeNotification"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    NSLog(@"[W2Like] Volume double-tap toggle installed");
}

// Ensure observer is installed early in app lifecycle
%ctor {
    @autoreleasepool {
        W2InstallVolumeDoubleTapToggle();
    }
}
