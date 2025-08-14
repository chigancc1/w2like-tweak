\
#import <Foundation/Foundation.h>

@interface W2PrefsManager : NSObject
@property(nonatomic, readonly) BOOL enabled;
@property(nonatomic, readonly) BOOL overlayOnly;
@property(nonatomic, readonly) NSString *videoPath;
@property(nonatomic, readonly) NSArray<NSString *> *allowedApps; // process names
+ (instancetype)shared;
- (BOOL)isAllowedForProcess:(NSString *)proc;
@end
