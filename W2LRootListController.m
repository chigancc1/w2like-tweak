\
#import "W2LRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <notify.h>

@implementation W2LRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)respring {
    pid_t pid;
    const char* args[] = {"killall", "-9", "backboardd", NULL};
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
}

- (void)openPickHelp {
    NSURL *url = [NSURL URLWithString:@"file:///var/mobile/Media/W2Like/"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)prefChanged:(id)sender {
    notify_post("com.w2like.prefschanged");
}

@end
