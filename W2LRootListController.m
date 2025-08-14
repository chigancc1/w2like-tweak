// W2LRootListController.m
#import "W2LRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/wait.h>
#import <notify.h>

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
    if (posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char * const *)argv, NULL) == 0) {
        (void)waitpid(pid, NULL, 0);
    }
}

- (void)openPickHelp {
    NSURL *url = [NSURL URLWithString:@"file:///var/mobile/Media/W2Like/"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)prefChanged:(id)sender {
    notify_post("com.w2like.prefschanged");
}

@end
