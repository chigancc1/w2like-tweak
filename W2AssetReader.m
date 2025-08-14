\
#import "W2AssetReader.h"
#import <AVFoundation/AVFoundation.h>

@interface W2AssetReader ()
@property(nonatomic, strong) AVAsset *asset;
@property(nonatomic, strong) AVAssetReader *reader;
@property(nonatomic, strong) AVAssetReaderTrackOutput *videoOut;
@property(nonatomic, strong) AVAssetReaderTrackOutput *audioOut;
@property(nonatomic, strong) NSDictionary *audioSettings;
@property(nonatomic, assign) CFAbsoluteTime startWall;
@end

@implementation W2AssetReader

- (instancetype)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        [self updatePath:path];
    }
    return self;
}

- (void)updatePath:(NSString *)path {
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        self.asset = nil; self.reader = nil; self.videoOut = nil; self.audioOut = nil;
        return;
    }
    self.asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@YES}];
    [self _setupReader];
}

- (void)_setupReader {
    if (!self.asset) return;
    NSError *err = nil;
    self.reader = [AVAssetReader assetReaderWithAsset:self.asset error:&err];
    if (err) { self.reader = nil; return; }

    // Video output
    AVAssetTrack *vtrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (vtrack) {
        NSDictionary *pix = @{ (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) };
        self.videoOut = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:vtrack outputSettings:pix];
        self.videoOut.alwaysCopiesSampleData = NO;
        if ([self.reader canAddOutput:self.videoOut]) [self.reader addOutput:self.videoOut];
    } else {
        self.videoOut = nil;
    }

    // Audio output (may be configured after we see a 'like' buffer to match mic format)
    AVAssetTrack *atrack = [[self.asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (atrack) {
        NSDictionary *settings = self.audioSettings;
        if (!settings) {
            // Default: 44.1kHz, stereo, 32-bit float PCM
            settings = @{
                AVFormatIDKey: @(kAudioFormatLinearPCM),
                AVSampleRateKey: @(44100),
                AVNumberOfChannelsKey: @(2),
                AVLinearPCMBitDepthKey: @(32),
                AVLinearPCMIsFloatKey: @YES,
                AVLinearPCMIsNonInterleaved: @NO
            };
        }
        self.audioOut = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:atrack outputSettings:settings];
        self.audioOut.alwaysCopiesSampleData = NO;
        if ([self.reader canAddOutput:self.audioOut]) [self.reader addOutput:self.audioOut];
    } else {
        self.audioOut = nil;
    }

    [self.reader startReading];
    self.startWall = CFAbsoluteTimeGetCurrent();
}

- (void)_restartLoop {
    if (!self.asset) return;
    [self.reader cancelReading];
    [self _setupReader];
}

#pragma mark - Video

- (CMSampleBufferRef)nextVideoSampleLike:(CMSampleBufferRef)like {
    if (!self.reader || self.reader.status != AVAssetReaderStatusReading) {
        [self _setupReader];
        if (!self.reader) return nil;
    }
    CMSampleBufferRef next = [self.videoOut copyNextSampleBuffer];
    if (!next) {
        [self _restartLoop];
        next = [self.videoOut copyNextSampleBuffer];
        if (!next) return nil;
    }
    // Adjust PTS to wall clock (keeps A/V in sync)
    CMSampleTimingInfo timing;
    CMItemCount count = 0;
    CMSampleBufferGetSampleTimingInfoArray(next, 1, &timing, &count);
    CFAbsoluteTime elapsed = CFAbsoluteTimeGetCurrent() - self.startWall;
    timing.presentationTimeStamp = CMTimeMakeWithSeconds(elapsed, 90000);
    CMSampleBufferRef adjusted = NULL;
    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, next, 1, &timing, &adjusted);
    CFRelease(next);
    return adjusted;
}

#pragma mark - Audio

- (void)configureAudioFormatFromLike:(CMSampleBufferRef)like {
    // Try to match the mic format (sample rate & channel count)
    if (!like) return;
    CMAudioFormatDescriptionRef fmt = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(like);
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    if (!asbd) return;

    NSNumber *sr = @(asbd->mSampleRate > 0 ? asbd->mSampleRate : 44100);
    NSNumber *ch = @(asbd->mChannelsPerFrame > 0 ? asbd->mChannelsPerFrame : 1);

    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatLinearPCM),
        AVSampleRateKey: sr,
        AVNumberOfChannelsKey: ch,
        AVLinearPCMBitDepthKey: @(32),
        AVLinearPCMIsFloatKey: @YES,
        AVLinearPCMIsNonInterleaved: @NO
    };
    // Only rebuild if different
    if (![settings isEqual:self.audioSettings]) {
        self.audioSettings = settings;
        [self _setupReader]; // rebuild reader with new audio settings
    }
}

- (CMSampleBufferRef)nextAudioSampleLike:(CMSampleBufferRef)like {
    if (!self.reader || self.reader.status != AVAssetReaderStatusReading) {
        [self _setupReader];
        if (!self.reader) return nil;
    }

    if (like && !self.audioSettings) {
        [self configureAudioFormatFromLike:like];
    }

    CMSampleBufferRef next = [self.audioOut copyNextSampleBuffer];
    if (!next) {
        [self _restartLoop];
        next = [self.audioOut copyNextSampleBuffer];
        if (!next) return nil;
    }

    // Adjust timing to wall clock (sync with video mapping)
    CMSampleTimingInfo timing;
    CMItemCount count = 0;
    CMSampleBufferGetSampleTimingInfoArray(next, 1, &timing, &count);
    CFAbsoluteTime elapsed = CFAbsoluteTimeGetCurrent() - self.startWall;
    // Use the like buffer's timescale if available; else 44100
    CMTimeScale scale = 44100;
    if (like) {
        CMSampleTimingInfo lt;
        CMItemCount lc = 0;
        if (CMSampleBufferGetSampleTimingInfoArray(like, 1, &lt, &lc) == noErr && lc > 0 && lt.duration.timescale > 0) {
            scale = lt.duration.timescale;
        }
    }
    timing.presentationTimeStamp = CMTimeMakeWithSeconds(elapsed, scale);
    CMSampleBufferRef adjusted = NULL;
    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, next, 1, &timing, &adjusted);
    CFRelease(next);
    return adjusted;
}

@end
