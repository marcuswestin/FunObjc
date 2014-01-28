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
- (UIImage *)imageAtTime:(double)atTime {
    AVAsset* videoAsset = self.asset;
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
static UIStatusBarStyle statusBarStyle;

+ (UIImagePickerController *)picker {
    return camera.picker;
}

// Modal Library Selection
//////////////////////////
+ (void)showForPhotoSelectionInViewController:(UIViewController *)viewController allowEditing:(BOOL)allowEditing animated:(BOOL)animated callback:(CameraCaptureCallback)callback {
    [self _setupSelectionWithMediaType:kUTTypeImage viewController:viewController allowsEditing:allowEditing animated:animated callback:callback];
}

+ (void)showForVideoSelectionInViewController:(UIViewController *)viewController allowEditing:(BOOL)allowEditing animated:(BOOL)animated callback:(CameraCaptureCallback)callback {
    [self _setupSelectionWithMediaType:kUTTypeMovie viewController:viewController allowsEditing:allowEditing animated:animated callback:callback];
}

+ (void)_setupSelectionWithMediaType:(CFStringRef)mediaType viewController:(UIViewController*)viewController allowsEditing:(BOOL)allowsEditing animated:(BOOL)animated callback:(CameraCaptureCallback)callback {
    [self _reset:callback modalViewController:viewController];
    camera.picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    camera.picker.mediaTypes = @[(__bridge NSString *) mediaType];
    camera.picker.allowsEditing = allowsEditing;
    [viewController presentViewController:camera.picker animated:animated completion:nil];
}

// Modal Capture
////////////////
+ (void)showForPhotoCaptureInViewController:(UIViewController *)viewController allowEditing:(BOOL)allowEditing device:(UIImagePickerControllerCameraDevice)device flashMode:(UIImagePickerControllerCameraFlashMode)flashMode showCameraControls:(BOOL)showCameraControls saveToAlbum:(BOOL)saveToAlbum animated:(BOOL)animated callback:(CameraCaptureCallback)callback
{
    [self _setupCaptureWithDevice:device flashMode:flashMode quality:0 maxDuration:0 showCameraControls:showCameraControls saveToAlbum:saveToAlbum callback:callback captureMode:UIImagePickerControllerCameraCaptureModePhoto viewController:viewController];
    [self _showInViewController:viewController animated:animated];
}

+ (void)showForVideoCaptureInViewController:(UIViewController *)viewController allowEditing:(BOOL)allowEditing device:(UIImagePickerControllerCameraDevice)device flashMode:(UIImagePickerControllerCameraFlashMode)flashMode showCameraControls:(BOOL)showCameraControls saveToAlbum:(BOOL)saveToAlbum quality:(UIImagePickerControllerQualityType)quality maxDuration:(NSTimeInterval)maxDuration animated:(BOOL)animated callback:(CameraCaptureCallback)callback
{
    [self _setupCaptureWithDevice:device flashMode:flashMode quality:quality maxDuration:maxDuration showCameraControls:showCameraControls saveToAlbum:saveToAlbum callback:callback captureMode:UIImagePickerControllerCameraCaptureModeVideo viewController:viewController];
    [self _showInViewController:viewController animated:animated];
}


// In-View Capture
//////////////////
+ (void)showForPhotoCaptureInView:(UIView *)inView device:(UIImagePickerControllerCameraDevice)device flashMode:(UIImagePickerControllerCameraFlashMode)flashMode showCameraControls:(BOOL)showCameraControls saveToAlbum:(BOOL)saveToAlbum callback:(CameraCaptureCallback)callback
{
    [self _setupCaptureWithDevice:device flashMode:flashMode quality:0 maxDuration:0 showCameraControls:showCameraControls saveToAlbum:saveToAlbum callback:callback captureMode:UIImagePickerControllerCameraCaptureModePhoto viewController:nil];
    [self _showInView:inView];
}

+ (void)showForVideoCaptureInView:(UIView *)inView device:(UIImagePickerControllerCameraDevice)device flashMode:(UIImagePickerControllerCameraFlashMode)flashMode showCameraControls:(BOOL)showCameraControls saveToAlbum:(BOOL)saveToAlbum quality:(UIImagePickerControllerQualityType)quality maxDuration:(NSTimeInterval)maxDuration callback:(CameraCaptureCallback)callback
{
    [self _setupCaptureWithDevice:device flashMode:flashMode quality:quality maxDuration:maxDuration showCameraControls:showCameraControls saveToAlbum:saveToAlbum callback:callback captureMode:UIImagePickerControllerCameraCaptureModeVideo viewController:nil];
    [self _showInView:inView];
}

+ (void)_setupCaptureWithDevice:(UIImagePickerControllerCameraDevice)device
                      flashMode:(UIImagePickerControllerCameraFlashMode)flashMode
                        quality:(UIImagePickerControllerQualityType)quality
                    maxDuration:(NSTimeInterval)maxDuration
             showCameraControls:(BOOL)showCameraControls
                    saveToAlbum:(BOOL)saveToAlbum
                       callback:(CameraCaptureCallback)callback
                    captureMode:(UIImagePickerControllerCameraCaptureMode)captureMode
                 viewController:(UIViewController*)viewController
{
    [Camera _reset:callback modalViewController:viewController];
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
}

+ (void)_showInViewController:(UIViewController*)viewController animated:(BOOL)animated {
    [viewController presentViewController:camera.picker animated:animated completion:nil];
}

+ (void)_showInView:(UIView*)inView {
    camera.picker.view.frame = CGRectMake(0, 0, inView.frame.size.width, inView.frame.size.height);
    [inView addSubview:camera.picker.view];
}

// API Misc
///////////

+ (BOOL)isAvailable {
    return [self isAvailableInFront] || [self isAvailableInRear];
}
+ (BOOL)isAvailableInRear {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}
+ (BOOL)isAvailableInFront {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

+ (void)hide {
    if (!camera) { return; }
    
    if (camera.modalViewController) {
        [camera.modalViewController dismissViewControllerAnimated:YES completion:nil];
        // in iOS7, I'm seeing a white (LightContent) status bar revert to black.
        // In .plist file, "View controller-based status bar appearance" is set to NO
        // and style is set using `[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];`
        [[UIApplication sharedApplication] setStatusBarStyle:statusBarStyle];
    } else {
        [camera.picker.view removeAndClean];
    }

    camera = nil;
}

+ (void)setFlashMode:(UIImagePickerControllerCameraFlashMode)flashMode {
    if (!camera) { return; }
    camera.picker.cameraFlashMode = flashMode;
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
    if (camera.modalViewController) {
        statusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    }
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
    asyncMain(^{
        _callback(nil, result);
    });
    [Camera hide];
}
@end
