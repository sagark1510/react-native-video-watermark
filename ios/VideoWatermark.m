#import "VideoWatermark.h"
#import <AVFoundation/AVFoundation.h>

@implementation VideoWatermark

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(convert:(NSString *)videoUri imageUri:(nonnull NSString *)imageUri callback:(RCTResponseSenderBlock)callback)
{
    [self watermarkVideoWithImage:videoUri imageUri:imageUri callback:callback];
}


-(void)watermarkVideoWithImage:(NSString *)videoUri imageUri:(NSString *)imageUri callback:(RCTResponseSenderBlock)callback
{


    
    NSURL *url = [[NSURL alloc] initWithString:videoUri];

    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:url options:nil];

    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];

    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];

    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
        
    CGSize sizeOfVideo = CGSizeApplyAffineTransform(clipVideoTrack.naturalSize, clipVideoTrack.preferredTransform);


    sizeOfVideo.width = fabs(sizeOfVideo.width);
    NSString *path = [[NSBundle mainBundle] pathForResource:imageUri ofType:@"png"];
    

    
    UIImage *myImage=[UIImage imageWithContentsOfFile:path];
    
    UIGraphicsBeginImageContext(sizeOfVideo);

    CGFloat widthDiference = fabs(sizeOfVideo.width - myImage.size.width);
    CGFloat heightDiference = fabs(sizeOfVideo.height - myImage.size.height);

    CGFloat newWidthImage= myImage.size.width+ (widthDiference * 0.6);
    CGFloat newHeightImage= myImage.size.height+ (widthDiference * 0.25);

    [myImage drawInRect:CGRectMake(  (sizeOfVideo.width - newWidthImage) /2  , (sizeOfVideo.height - newHeightImage), newWidthImage, newHeightImage)];
        

    
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    myImage = destImage;
    
    
    CALayer *layerCa = [CALayer layer];
    layerCa.contents = (id)myImage.CGImage;
    layerCa.frame = CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    layerCa.opacity = 0.7;
    
    CALayer *parentLayer=[CALayer layer];
    CALayer *videoLayer=[CALayer layer];
    parentLayer.frame=CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    videoLayer.frame=CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:layerCa];
    
    AVMutableVideoComposition *videoComposition=[AVMutableVideoComposition videoComposition] ;
    videoComposition.frameDuration=CMTimeMake(1, 30);
    videoComposition.renderSize=sizeOfVideo;
    videoComposition.animationTool=[AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    

    CGAffineTransform transform = clipVideoTrack.preferredTransform;
    CGRect rect = {{0, 0}, clipVideoTrack.naturalSize};
    CGRect transformedRect = CGRectApplyAffineTransform(rect, transform);
    transform.tx -= transformedRect.origin.x;
    transform.ty -= transformedRect.origin.y;


    CGAffineTransform assetScaleFactor = CGAffineTransformMakeScale(1.0, 1.0);
    [layerInstruction setTransform:CGAffineTransformConcat(transform, assetScaleFactor) atTime:kCMTimeZero];
    
    
    
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/output_%@.mp4", [dateFormatter stringFromDate:[NSDate date]]];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exportSession.videoComposition=videoComposition;
    
    exportSession.outputURL = [NSURL fileURLWithPath:destinationPath];
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status)
        {
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"Export OK");
                callback(@[destinationPath]);
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportSession.error);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export Cancelled");
                break;
        }
    }];
}

@end
