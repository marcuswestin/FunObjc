//
//  Camera.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 7/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "State.h"

@interface CameraVideo : State
@property NSString* path;
@property float duration;
@property CGSize size;
@property AVAsset* asset;
@property AVPlayerItem* playerItem;
- (UIImage*)imageAtTime:(double)time;
@end

@interface CameraPicture : State
@property UIImage* image;
@end

@interface CameraResult : State
@property CameraVideo* video;
@property CameraPicture* picture;
@end

typedef void (^CameraCaptureCallback)(NSError* err, CameraResult* result);

@interface Camera : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property UIImagePickerController* picker;
@property (strong) CameraCaptureCallback callback;
@property UIViewController* modalViewController;
@property BOOL saveToAlbum;
@property BOOL allowsEditing;

//+ (void)showModalPickerInViewController:(UIViewController*)viewController
//                             sourceType:(UIImagePickerControllerSourceType)sourceType
//                           allowEditing:(BOOL)allowEditing
//                               animated:(BOOL)animated
//                               callback:(CameraCaptureCallback)callback
//;
//
//+ (void)showModalPickerInViewController:(UIViewController*)viewController
//                             sourceType:(UIImagePickerControllerSourceType)sourceType
//                             cameraDevice:(UIImagePickerControllerCameraDevice)cameraDevice
//                           allowEditing:(BOOL)allowEditing
//                               animated:(BOOL)animated
//                               callback:(CameraCaptureCallback)callback
//;

+ (void)showForPhotoSelectionInViewController:(UIViewController*)viewController
                                 allowEditing:(BOOL)allowEditing
                                     animated:(BOOL)animated
                                     callback:(CameraCaptureCallback)callback;

+ (void)showForVideoSelectionInViewController:(UIViewController*)viewController
                                 allowEditing:(BOOL)allowEditing
                                     animated:(BOOL)animated
                                     callback:(CameraCaptureCallback)callback;

+ (void)showForPhotoCaptureInViewController:(UIViewController*)viewController
                        allowEditing:(BOOL)allowEditing
                              device:(UIImagePickerControllerCameraDevice)device
                           flashMode:(UIImagePickerControllerCameraFlashMode)flashMode
                  showCameraControls:(BOOL)showCameraControls
                         saveToAlbum:(BOOL)saveToAlbum
                            animated:(BOOL)animated
                            callback:(CameraCaptureCallback)callback
;

+ (void)showForVideoCaptureInViewController:(UIViewController*)viewController
                        allowEditing:(BOOL)allowEditing
                              device:(UIImagePickerControllerCameraDevice)device
                           flashMode:(UIImagePickerControllerCameraFlashMode)flashMode
                  showCameraControls:(BOOL)showCameraControls
                         saveToAlbum:(BOOL)saveToAlbum
                             quality:(UIImagePickerControllerQualityType)quality
                         maxDuration:(NSTimeInterval)maxDuration
                            animated:(BOOL)animated
                            callback:(CameraCaptureCallback)callback
;

+ (void)showForPhotoCaptureInView:(UIView *)inView
                    device:(UIImagePickerControllerCameraDevice)device
                 flashMode:(UIImagePickerControllerCameraFlashMode)flashMode
        showCameraControls:(BOOL)showCameraControls
               saveToAlbum:(BOOL)saveToAlbum
                  callback:(CameraCaptureCallback)callback
;

+ (void)showForVideoCaptureInView:(UIView *)inView
                    device:(UIImagePickerControllerCameraDevice)device
                 flashMode:(UIImagePickerControllerCameraFlashMode)flashMode
        showCameraControls:(BOOL)showCameraControls
               saveToAlbum:(BOOL)saveToAlbum
                   quality:(UIImagePickerControllerQualityType)quality
               maxDuration:(NSTimeInterval)maxDuration
                  callback:(CameraCaptureCallback)callback
;

+ (void)hide;
+ (void)toggleCameraDirection;
+ (void)setFlashMode:(UIImagePickerControllerCameraFlashMode)flashMode;

+ (UIImagePickerController*)picker;

+ (BOOL)isAvailable;
+ (BOOL)isAvailableInRear;
+ (BOOL)isAvailableInFront;

@end
