\
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface W2AssetReader : NSObject
- (instancetype)initWithPath:(NSString *)path;
- (void)updatePath:(NSString *)path;

// Video
- (CMSampleBufferRef)nextVideoSampleLike:(CMSampleBufferRef)like; // retained

// Audio
- (void)configureAudioFormatFromLike:(CMSampleBufferRef)like;
- (CMSampleBufferRef)nextAudioSampleLike:(CMSampleBufferRef)like; // retained
@end
