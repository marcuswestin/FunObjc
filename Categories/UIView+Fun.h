//
//  UIView+Fun.h
//  ivyq
//
//  Created by Marcus Westin on 9/10/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FunTypes.h"

@interface UIView (Fun)

/* Size
 ******/
- (CGFloat)height;
- (CGFloat)width;
- (CGSize)size;
- (void)setWidth:(CGFloat)width;
- (void)setHeight:(CGFloat)height;
- (void)setSize:(CGSize)size;
- (void)resizeByAddingWidth:(CGFloat)width height:(CGFloat)height;
- (void)resizeBySubtractingWidth:(CGFloat)width height:(CGFloat)height;
- (void)containSubviews;
- (void)containSubviewsHorizontally:(BOOL)containHorizontally vertically:(BOOL)vertically;
- (void)setHeightUp:(CGFloat)height;
- (void)addHeightUp:(CGFloat)addHeight;

/* Position
 **********/
- (void)centerView;
- (void)centerVertically;
- (void)centerHorizontally;
- (void)moveByX:(CGFloat)x y:(CGFloat)y;
- (void)moveByY:(CGFloat)y;
- (void)moveByX:(CGFloat)x;
- (void)moveToX:(CGFloat)x y:(CGFloat)y;
- (void)moveToX:(CGFloat)x;
- (void)moveToY:(CGFloat)y;
- (void)moveToPosition:(CGPoint)origin;
- (void)moveByVector:(CGVector)vector;
- (CGPoint)topRightCorner;
- (CGPoint)topLeftCorner;
- (CGPoint)bottomLeftCorner;
- (CGPoint)bottomRightCorner;
- (CGFloat)x;
- (CGFloat)y;
- (CGFloat)x2;
- (CGFloat)y2;
- (void)setX:(CGFloat)x;
- (void)setY:(CGFloat)y;
- (void)setX2:(CGFloat)x2;
- (void)setY2:(CGFloat)y2;
- (CGRect)frameInWindow;
- (CGRect)frameOnScreen;

/* Borders, Shadows & Insets
 ***************************/
- (void)setOutsetShadowColor:(UIColor*)color radius:(CGFloat)radius spread:(CGFloat)spread x:(CGFloat)offsetX y:(CGFloat)offsetY;
- (void)setInsetShadowColor:(UIColor*)color radius:(CGFloat)radius spread:(CGFloat)spread x:(CGFloat)offsetX y:(CGFloat)offsetY;
- (void)setOutsetShadowColor:(UIColor*)color radius:(CGFloat)radius;
- (void)setInsetShadowColor:(UIColor*)color radius:(CGFloat)radius;
- (void)setBorderColor:(UIColor*)color width:(CGFloat)width;
- (void)setGradientColors:(NSArray*)colors;

/* View hierarchy
 ****************/
- (void)empty;
- (void)appendTo:(UIView*)superview;
- (void)prependTo:(UIView*)superview;

/* Screenshot
 ************/
typedef void(^GhostCallback)(UIView* ghostView);
- (UIImage*)captureToImage;
- (UIImage*)captureToImageWithScale:(CGFloat)scale;
- (NSData*)captureToPngData;
- (NSData*)captureToJpgData:(CGFloat)compressionQuality;
- (UIView*)ghost;
- (void)ghostWithDuration:(NSTimeInterval)duration animation:(GhostCallback)animationCallback;
- (void)ghostWithDuration:(NSTimeInterval)duration animation:(GhostCallback)animationCallback completion:(GhostCallback)completionCallback;
- (void)ghostWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(GhostCallback)animationCallback;
- (void)ghostWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(GhostCallback)animationCallback completion:(GhostCallback)completionCallback;

/* Animations
 ************/
+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations;
@end

@interface UIView (Blur)
- (void)blur;
- (void)blur:(UIColor*)color;
- (void)blur:(UIColor*)color size:(CGSize)size;
@end

typedef BOOL (^ShouldChangeStringCallback)(NSString* fromString, NSString* toString, NSRange replacementRange, NSString* replacementString);

@interface UITextField (Fun)
- (void)bindTextTo:(NSMutableString*)str;
- (void)excludeInputsMatching:(NSString*)pattern;
- (void)limitLengthTo:(NSUInteger)maxLength;
- (void)shouldChange:(ShouldChangeStringCallback)shouldChangeStringCallback;
@end

@interface UILabel (Fun)
- (void)wrapText;
@end
