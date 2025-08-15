// W2LRootListController.m

#import "W2LRootListController.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/wait.h>
#import <notify.h>
#import <unistd.h>

static NSString * const kPrefsPath   = @"/var/mobile/Library/Preferences/com.w2like.prefs.plist";
static NSString * const kPrefsDomain = @"com.w2like.prefs";
static NSString * const kMediaDir    = @"/var/mobile/Media/W2Like";
static NSString * const kNotifyName  = @"com.w2like.prefschanged";

@implementation W2LRootListController

#pragma mark - Specifiers

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Ensure /var/mobile/Media/W2Like exists
    [[NSFileManager defaultManager] createDirectoryAtPath:kMediaDir
                              withIntermediateDirectories:YES
                                               attributes:@{NSFilePosixPermissions: @0755}
                                                    error:nil];

    // Seed a default VideoPath if missing
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPath] ?: [NSMutableDictionary new];
    if (!prefs[@"VideoPath"]) {
        prefs[@"VideoPath"] = [kMediaDir stringByAppendingPathComponent:@"sample.mp4"];
        [prefs writeToFile:kPrefsPath atomically:YES];
    }
}

#pragma mark - Preference IO (domain: com.w2like.prefs)

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    id val = prefs[specifier.properties[@"key"]];
    if (val == nil) {
        val = specifier.properties[@"default"];
    }
    return val;
}

- (void)setPreferenceValue:(id)value forSpecifier:(PSSpecifier *)specifier {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:kPrefsPath] ?: [NSMutableDictionary new];
    NSString *key = specifier.properties[@"key"];
    if (key) {
        prefs[key] = value ?: [NSNull null];
        [prefs writeToFile:kPrefsPath atomically:YES];
        notify_post(kNotifyName.UTF8String);
    }
}

#pragma mark - Actions (wired in Root.plist)

- (void)respring {
    // Prefer sbreload if present (cleaner on iOS 12+)
    if (access("/usr/bin/sbreload", X_OK) == 0) {
        pid_t pid = 0;
        const char *argv[] = { "sbreload", NULL };
        if (posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char * const *)argv, NULL) == 0) {
            (void)waitpid(pid, NULL, 0);
            return;
        }
    }

    // Fallback to killing backboardd
    pid_t pid = 0;
    const char *argv[] = { "killall", "-9", "backboardd", NULL };
    if (posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char * const *)argv, NULL) == 0) {
        (void)waitpid(pid, NULL, 0);
    }
}

- (void)openPickHelp {
    // Try Filza first (most common on JB devices)
    NSString *filzaURLString = [@"filza://" stringByAppendingString:kMediaDir];
    NSURL *filzaURL = [NSURL URLWithString:filzaURLString];

    UIApplication *app = [UIApplication sharedApplication];
    if ([app canOpenURL:filzaURL]) {
        [app openURL:filzaURL options:@{} completionHandler:nil];
        return;
    }

    // Fallback: copy the path to clipboard & show a note
    [UIPasteboard generalPasteboard].string = kMediaDir;

    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"W2Like folder"
                                        message:[NSString stringWithFormat:
                                                 @"Path copied to clipboard:\n%@", kMediaDir]
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Manual notify (if you wire a “Save”/“Apply” button)

- (void)prefChanged:(id)sender {
    notify_post(kNotifyName.UTF8String);
}

@end
