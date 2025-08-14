// W2LRootListController.m

#import "W2LRootListController.h"
#import <Preferences/PSSpecifier.h>

// Add the system headers you need:
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <spawn.h>        // posix_spawn / posix_spawnp
#import <sys/wait.h>     // waitpid (optional, but recommended)

@implementation W2LRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)respring {
    pid_t pid = 0;
    const char *argv[] = { "killall", "-9", "backboardd", NULL };

    // Launch /usr/bin/killall backboardd
    int rc = posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char * const *)argv, NULL);
    if (rc == 0) {
        // Optionally wait for it to finish so the compiler/linker doesn't warn
        // about an unused pid and to avoid zombie processes.
        (void)waitpid(pid, NULL, 0);
    }
}

- (void)openPickHelp {
    NSURL *url = [NSURL URLWithString:@"file:///var/mobile/Media/W2Like/"];
    [[UIApplication sharedApplication] openURL:url
                                       options:@{}
                             completionHandler:nil];
}

- (void)prefChanged:(id)sender {
    notify_post("com.w2like.prefschanged");
}

@end
