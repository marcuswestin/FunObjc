//
//  Camera.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 7/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Camera.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AVFoundation/AVFoundation.h>

@implementation CameraVideo
@end
@implementation CameraPicture
@end
@implementation CameraResult
+ (instancetype) withVideoUrl:(NSURL*)videoUrl {
    AVAsset* videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:@{ AVURLAssetPreferPreciseDurationAndTimingKey:num(1) }];
    AVAssetTrack* videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:videoAsset];
    float durationInSeconds = CMTimeGetSeconds(videoAsset.duration);
    CameraResult* instance = [CameraResult new];
    CameraVideo* video = instance.video = [CameraVideo new];
    video.path = videoUrl.path;
    video.duration = durationInSeconds;
    video.size = videoTrack.naturalSize;
    video.asset = videoAsset;
    video.playerItem = playerItem;
    return instance;
}
+ (instancetype) withImage:(UIImage*)image {
    CameraResult* instance = [CameraResult new];
    CameraPicture* picture = instance.picture = [CameraPicture new];
    picture.image = image;
    return instance;
}
@end

@implementation Camera

static Camera* camera;

+ (UIImagePickerController *)picker {
    return camera.picker;
}

+ (void)showCameraForPhotoInView:(UIView *)inView
                  device:(UIImagePickerControllerCameraDevice)device
               flashMode:(UIImagePickerControllerCameraFlashMode)flashMode
      showCameraControls:(BOOL)showCameraControls
             saveToAlbum:(BOOL)saveToAlbum
                callback:(CameraCaptureCallback)callback
{
    [self _showCameraInView:inView device:device flashMode:flashMode quality:0 maxDuration:0 showCameraControls:showCameraControls saveToAlbum:saveToAlbum callback:callback captureMode:UIImagePickerControllerCameraCaptureModePhoto];
}

+ (void)showCameraForVideoInView:(UIView *)inView
                          device:(UIImagePickerControllerCameraDevice)device
                       flashMode:(UIImagePickerControllerCameraFlashMode)flashMode
                         quality:(UIImagePickerControllerQualityType)quality
                     maxDuration:(NSTimeInterval)maxDuration
              showCameraControls:(BOOL)showCameraControls
                     saveToAlbum:(BOOL)saveToAlbum
                        callback:(CameraCaptureCallback)callback
{
    [self _showCameraInView:inView device:device flashMode:flashMode quality:quality maxDuration:maxDuration showCameraControls:showCameraControls saveToAlbum:saveToAlbum callback:callback captureMode:UIImagePickerControllerCameraCaptureModeVideo];
}

+ (void)_showCameraInView:(UIView *)inView
                  device:(UIImagePickerControllerCameraDevice)device
               flashMode:(UIImagePickerControllerCameraFlashMode)flashMode
                 quality:(UIImagePickerControllerQualityType)quality
             maxDuration:(NSTimeInterval)maxDuration
      showCameraControls:(BOOL)showCameraControls
             saveToAlbum:(BOOL)saveToAlbum
                callback:(CameraCaptureCallback)callback
             captureMode:(UIImagePickerControllerCameraCaptureMode)captureMode
{
    [Camera _reset:callback modalViewController:nil];
    camera.saveToAlbum = saveToAlbum;
    
    camera.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isCameraDeviceAvailable:device]) {
        camera.picker.cameraDevice = device;
    }
    
    if (captureMode == UIImagePickerControllerCameraCaptureModeVideo) {
        camera.picker.videoQuality = quality;
        camera.picker.mediaTypes = @[(NSString*)kUTTypeMovie];
        camera.picker.videoMaximumDuration = maxDuration;
    }
    
    camera.picker.cameraCaptureMode = captureMode;
    camera.picker.cameraFlashMode = flashMode;
    camera.picker.showsCameraControls = showCameraControls;
    
    camera.picker.view.frame = CGRectMake(0, 0, inView.frame.size.width, inView.frame.size.height);
    [inView addSubview:camera.picker.view];
}


+ (void)showModalPickerInViewController:(UIViewController*)viewController
                             sourceType:(UIImagePickerControllerSourceType)sourceType
                           allowEditing:(BOOL)allowEditing
                               animated:(BOOL)animated
                               callback:(CameraCaptureCallback)callback
{
    return [Camera showModalPickerInViewController:viewController sourceType:sourceType cameraDevice:0 allowEditing:allowEditing animated:animated callback:callback];
}
+ (void)showModalPickerInViewController:(UIViewController *)viewController
                             sourceType:(UIImagePickerControllerSourceType)sourceType
                           cameraDevice:(UIImagePickerControllerCameraDevice)cameraDevice
                           allowEditing:(BOOL)allowEditing
                               animated:(BOOL)animated
                               callback:(CameraCaptureCallback)callback {
    [Camera _reset:callback modalViewController:viewController];
    
    camera.picker.sourceType = sourceType;
    camera.picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    camera.picker.allowsEditing = allowEditing;
    if ([UIImagePickerController isCameraDeviceAvailable:cameraDevice]) {
        camera.picker.cameraDevice = cameraDevice;
    }
    
    [viewController presentViewController:camera.picker animated:animated completion:nil];
}

+ (void)hide {
    if (!camera) { return; }
    
    if (camera.modalViewController) {
        [camera.modalViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [camera.picker.view removeFromSuperview];
    }

    camera = nil;
}

+ (void)toggleCameraDirection {
    if (!camera) { return; }
    UIImagePickerControllerCameraDevice currentDevice = camera.picker.cameraDevice;
    UIImagePickerControllerCameraDevice newDevice = (currentDevice == UIImagePickerControllerCameraDeviceFront
                                                      ? UIImagePickerControllerCameraDeviceRear
                                                      : UIImagePickerControllerCameraDeviceFront);
    if ([UIImagePickerController isCameraDeviceAvailable:newDevice]) {
        camera.picker.cameraDevice = newDevice;
    }
}

/* Internal
 **********/
+ (void) _reset:(CameraCaptureCallback)callback modalViewController:(UIViewController*)modalViewController {
    if (camera) { [Camera hide]; }
    
    camera = [[Camera alloc] init];
    camera.picker = [[UIImagePickerController alloc] init];
    camera.picker.delegate = camera;
    camera.callback = callback;
    camera.modalViewController = modalViewController;
}

/* Delegate
 **********/
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if ([info[UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeMovie]) {
        [self _handleCapturedVideo:info];
    } else {
        [self _handleCapturedPicture:info];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self _finishWith:nil];
}

- (void) _handleCapturedVideo:(NSDictionary*)info {
    NSURL* videoUrl = info[UIImagePickerControllerMediaURL];
    if (self.saveToAlbum) {
        UISaveVideoAtPathToSavedPhotosAlbum(videoUrl.path, nil, nil, nil);
    }
    [self _finishWith:[CameraResult withVideoUrl:videoUrl]];
}

- (void)_handleCapturedPicture:(NSDictionary*)info {
    if (self.saveToAlbum) {
        UIImageWriteToSavedPhotosAlbum(info[UIImagePickerControllerOriginalImage], nil, nil, nil);
    }
    UIImage* image = info[(self.picker.allowsEditing ? UIImagePickerControllerEditedImage : UIImagePickerControllerOriginalImage)];
    [self _finishWith:[CameraResult withImage:image]];
}

- (void)_finishWith:(CameraResult*)result {
    _callback(nil, result);
    [Camera hide];
}

+ (UIImage*)thumbnailForVideoResult:(CameraVideo*)videoResult atTime:(double)atTime {
    AVAsset* videoAsset = videoResult.asset;
    CMTime cmTime = CMTimeMakeWithSeconds(atTime, videoAsset.duration.timescale);
    
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:videoAsset];
    imageGenerator.appliesPreferredTrackTransform = YES;

    NSError *error = nil;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:cmTime actualTime:NULL error:&error];
    if (error) {
        NSLog(@"Error generating thumbnail for video result: %@", error);
        return nil;
    }
    
    UIImage *thumbImage = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return thumbImage;
}

@end
