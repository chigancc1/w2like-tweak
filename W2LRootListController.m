// W2LRootListController.m

#import "W2LRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <notify.h>          // notify_post
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <spawn.h>           // posix_spawn / posix_spawnp
#import <sys/wait.h>        // waitpid

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

    // Launch /usr/bin/killall backboardd, then wait to avoid zombies.
    int rc = posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char * const *)argv, NULL);
    if (rc == 0) {
        (void)waitpid(pid, NULL, 0);
    }
}

- (void)openPickHelp {
    NSURL *url = [NSURL fileURLWithPath:@"/var/mobile/Media/W2Like/"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
#pragma clang diagnostic pop
}

- (void)prefChanged:(id)sender {
    notify_post("com.w2like.prefschanged");
}

@end
