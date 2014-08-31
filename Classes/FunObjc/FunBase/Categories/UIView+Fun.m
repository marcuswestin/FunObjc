//
//  UIView+Fun.m
//  ivyq
//
//  Created by Marcus Westin on 9/10/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "UIView+Fun.h"
#import "FunObjc.h"

// Blur effect
//////////////
@interface FunBlurView : UIView
@property UIToolbar *toolbar;
@end
@implementation FunBlurView
+ (void)inSuperview:(UIView*)superview {
    FunBlurView* blurView = [[FunBlurView alloc] initWithFrame:superview.bounds];
    blurView.toolbar = [[UIToolbar alloc] initWithFrame:superview.bounds];
    blurView.toolbar.clipsToBounds = YES;
    [superview insertSubview:blurView atIndex:0];
    [superview.layer insertSublayer:[blurView.toolbar layer] atIndex:0];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self.toolbar setFrame:[self bounds]];
}
@end

// UIView
/////////
@implementation UIView (Fun)

/* Lifecycle
 ***********/

- (void)render {}
- (void)cleanup {}
- (void)recursivelyCleanup {
    // This fires when the parent FunUIViewController didMoveToParentViewController:nil
    for (UIView* view in self.subviews) {
        [view recursivelyCleanup];
    }
    [self cleanup];
    RemoveRuntimeProperties(self);
}

/* Size
 ******/
- (CGFloat)height {
    return CGRectGetHeight(self.frame);
}
- (CGFloat)width {
    return CGRectGetWidth(self.frame);
}
- (CGSize)size {
    return self.frame.size;
}
- (void)setWidth:(CGFloat)width {
    [self setSize:CGSizeMake(width, self.height)];
}
- (void)setHeight:(CGFloat)height {
    [self setSize:CGSizeMake(self.width, height)];
}
- (void)setHeightUp:(CGFloat)height {
    CGFloat dh = self.height - height;
    self.height = height;
    self.y += dh;
}
- (void)addHeightUp:(CGFloat)addHeight {
    [self setHeightUp:self.height + addHeight];
}
- (void)setSize:(CGSize)size {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, size.width, size.height);
}
- (CGSize)aspectRatioSizeWithWidth:(CGFloat)width {
    CGSize size = self.size;
    CGFloat ratio = width / size.width;
    return CGSizeMake(width, size.height * ratio);
}
- (CGSize)aspectRatioSizeWithHeight:(CGFloat)height {
    CGSize size = self.size;
    CGFloat ratio = height / size.height;
    return CGSizeMake(size.width * ratio, height);
}

- (CGSize)aspectRatioSizeFilling:(CGSize)target {
    CGSize size = self.size;
    CGFloat wRatio = target.width / size.width;
    CGFloat hRatio = target.height / size.height;
    CGFloat targetRatio = MAX(wRatio, hRatio);
    return CGSizeMake(size.width * targetRatio, size.height * targetRatio);
}
- (CGSize)aspectRatioSizeWithin:(CGSize)target {
    CGSize size = self.size;
    CGFloat wRatio = target.width / size.width;
    CGFloat hRatio = target.height / size.height;
    CGFloat targetRatio = MIN(wRatio, hRatio);
    return CGSizeMake(size.width * targetRatio, size.height * targetRatio);
}

- (void)addSize:(CGSize)size {
    [self addWidth:size.width height:size.height];
}
- (void)addWidth:(CGFloat)width height:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height += height;
    frame.size.width += width;
    self.frame = frame;
}
- (void)containSubviews {
    [self containSubviewsHorizontally:YES vertically:YES];
}
- (void)containSubviewsHorizontally {
    [self containSubviewsHorizontally:YES vertically:NO];
}
- (void)containSubviewsVertically {
    [self containSubviewsHorizontally:NO vertically:YES];
}
- (void)containSubviewsHorizontally:(BOOL)horizontally vertically:(BOOL)vertically {
    CGRect frame = self.frame;
    if (horizontally) { frame.size.width = 0; }
    if (vertically) { frame.size.height = 0; }
    
    CGVector move = CGVectorMake(0, 0);
    for (UIView* view in self.subviews) {
        CGRect subFrame = view.frame;
        if (horizontally && subFrame.origin.x < move.dx) {
            move.dx = subFrame.origin.x;
        }
        if (vertically && subFrame.origin.y < move.dy) {
            move.dy = subFrame.origin.y;
        }
    }
    [self moveByVector:move];
    
    for (UIView* view in self.subviews) {
        [view moveByX:-move.dx y:-move.dy];
        if (horizontally && view.x2 > frame.size.width) {
            frame.size.width = view.x2;
        }
        if (vertically && view.y2 > frame.size.height) {
            frame.size.height = view.y2;
        }
    }
    
    self.frame = frame;
}
- (void)containLastViewVertically {
    self.height = self.lastSubview.y2;
}

/* Position
 **********/
- (void)moveByX:(CGFloat)dx y:(CGFloat)dy {
    CGRect frame = self.frame;
    frame.origin.x += dx;
    frame.origin.y += dy;
    self.frame = frame;
}
- (void)moveByX:(CGFloat)x {
    [self moveByX:x y:0];
}
- (void)moveByY:(CGFloat)y {
    [self moveByX:0 y:y];
}
- (void)moveToX:(CGFloat)x y:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    self.frame = frame;
}
- (void)moveToY:(CGFloat)y {
    [self moveToX:self.frame.origin.x y:y];
}
- (void)moveToX:(CGFloat)x {
    [self moveToX:x y:self.frame.origin.y];
}
- (void)moveToPosition:(CGPoint)origin {
    [self moveToX:origin.x y:origin.y];
}
- (void)moveByVector:(CGVector)vector {
    CGPoint newOrigin = self.frame.origin;
    newOrigin.x += vector.dx;
    newOrigin.y += vector.dy;
    [self moveToPosition:newOrigin];
}
- (void)centerVertically {
    [self moveToY:CGRectGetMidY(self.superview.bounds) - self.height/2];
}
- (void)centerHorizontally {
    [self moveToX:CGRectGetMidX(self.superview.bounds) - self.width/2];
}
- (void)centerInSuperview {
    [self centerVertically];
    [self centerHorizontally];
}
- (CGPoint)topRightCorner {
    CGPoint point = self.frame.origin;
    point.x += self.width;
    return point;
}
- (CGPoint)topLeftCorner {
    return self.frame.origin;
}
- (CGPoint)bottomLeftCorner {
    CGPoint point = self.frame.origin;
    point.y += self.height;
    return point;
}
- (CGPoint)bottomRightCorner {
    CGPoint point = self.frame.origin;
    point.x += self.width;
    point.y += self.height;
    return point;
}
- (CGFloat)x {
    return CGRectGetMinX(self.frame);
}
- (CGFloat)y {
    return CGRectGetMinY(self.frame);
}
- (CGFloat)x2 {
    return CGRectGetMaxX(self.frame);
}
- (CGFloat)y2 {
    return CGRectGetMaxY(self.frame);
}
- (CGFloat)centerX {
    return self.center.x;
}
- (CGFloat)centerY {
    return self.center.y;
}
- (CGRect)centerSquare:(CGFloat)size {
    CGSize mySize = self.frame.size;
    return CGRectMake(mySize.width/2-size/2, mySize.height/2-size/2, size, size);
}
- (void)setX:(CGFloat)x {
    [self moveToX:x];
}
- (void)setY:(CGFloat)y {
    [self moveToY:y];
}
- (void)setX2:(CGFloat)x2 {
    [self moveToX:x2 - self.width];
}
- (void)setY2:(CGFloat)y2 {
    [self moveToY:y2 - self.height];
}
- (void)setCenterX:(CGFloat)x {
    CGPoint center = self.center;
    center.x = x;
    self.center = center;
}
- (void)setCenterY:(CGFloat)y {
    CGPoint center = self.center;
    center.y = y;
    self.center = center;
}
- (CGRect)frameInWindow {
    return [self frameInView:self.window];
}
- (CGRect)frameInView:(UIView*)view {
    return [self.superview convertRect:self.frame toView:view];
}

/* Borders, Shadows & Insets
 ***************************/
- (void)setBorderColor:(UIColor *)color width:(CGFloat)width {
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = width;
}

- (void)setGradientColors:(NSArray *)colors {
    CAGradientLayer* gradient = [CAGradientLayer layer];
    CALayer* layer = self.layer;
    gradient.frame = layer.bounds;
    gradient.colors = [colors map:^id(UIColor* color, NSUInteger i) {
        return (id)color.CGColor;
    }];
    //    gradient.locations = [colors map:^id(id val, NSUInteger i) {
    //        return numf(((CGFloat) i) / (colors.count - 1));
    //    }];
    gradient.cornerRadius = self.layer.cornerRadius;
    [layer insertSublayer:gradient atIndex:0];
}

- (void)setOutsetShadowColor:(UIColor *)color radius:(CGFloat)radius {
    return [self setOutsetShadowColor:color radius:radius spread:0 x:0 y:0];
}
- (void)setInsetShadowColor:(UIColor *)color radius:(CGFloat)radius {
    return [self setInsetShadowColor:color radius:radius spread:0 x:0 y:0];
}

static CGFloat STATIC = 0.5f;
- (void)setOutsetShadowColor:(UIColor *)color radius:(CGFloat)radius spread:(CGFloat)spread x:(CGFloat)offsetX y:(CGFloat)offsetY {
    if (self.clipsToBounds) { DLog(@"Warning: outset shadow put on view with clipped bounds"); }
    NSArray* colors = @[(id)color.CGColor, (id)[UIColor.clearColor CGColor]];
    
    CAGradientLayer *top = [CAGradientLayer layer];
    top.frame = CGRectMake(0 + offsetX, -radius + offsetY, self.bounds.size.width, spread + radius);
    top.colors = colors;
    top.startPoint = CGPointMake(STATIC, 1.0);
    top.endPoint = CGPointMake(STATIC, 0.0);
    [self.layer insertSublayer:top atIndex:0];
    
    CAGradientLayer *right = [CAGradientLayer layer];
    right.frame = CGRectMake(self.bounds.size.width + radius + offsetX, 0 + offsetY, spread + radius, self.bounds.size.height);
    right.colors = colors;
    right.startPoint = CGPointMake(0.0, STATIC);
    right.endPoint = CGPointMake(1.0, STATIC);
    [self.layer insertSublayer:right atIndex:0];
    
    CAGradientLayer *bottom = [CAGradientLayer layer];
    bottom.frame = CGRectMake(0 + offsetX, self.bounds.size.height + offsetY, self.bounds.size.width, spread + radius);
    bottom.colors = colors;
    bottom.startPoint = CGPointMake(STATIC, 0.0);
    bottom.endPoint = CGPointMake(STATIC, 1.0);
    [self.layer insertSublayer:bottom atIndex:0];
    
    CAGradientLayer *left = [CAGradientLayer layer];
    left.frame = CGRectMake(-radius + offsetX, 0 + offsetY, spread + radius, self.bounds.size.height);
    left.colors = colors;
    left.startPoint = CGPointMake(1.0, STATIC);
    left.endPoint = CGPointMake(0.0, STATIC);
    [self.layer insertSublayer:left atIndex:0];
}

- (void)setInsetShadowColor:(UIColor*)color radius:(CGFloat)radius spread:(CGFloat)spread x:(CGFloat)offsetX y:(CGFloat)offsetY {
    NSArray* colors = @[(id)color.CGColor, (id)[UIColor.clearColor CGColor]];
    
    CAGradientLayer *top = [CAGradientLayer layer];
    top.frame = CGRectMake(0 + offsetX, 0 + offsetY, self.bounds.size.width, spread + radius);
    top.colors = colors;
    top.startPoint = CGPointMake(STATIC, 0.0);
    top.endPoint = CGPointMake(STATIC, 1.0);
    [self.layer insertSublayer:top atIndex:0];
    
    CAGradientLayer *right = [CAGradientLayer layer];
    right.frame = CGRectMake(self.bounds.size.width - radius + offsetX, 0 + offsetY, spread + radius, self.bounds.size.height);
    right.colors = colors;
    right.startPoint = CGPointMake(1.0, STATIC);
    right.endPoint = CGPointMake(0.0, STATIC);
    [self.layer insertSublayer:right atIndex:0];
    
    CAGradientLayer *bottom = [CAGradientLayer layer];
    bottom.frame = CGRectMake(0 + offsetX, self.bounds.size.height - radius + offsetY, self.bounds.size.width, spread + radius);
    bottom.colors = colors;
    bottom.startPoint = CGPointMake(STATIC, 1.0);
    bottom.endPoint = CGPointMake(STATIC, 0.0);
    [self.layer insertSublayer:bottom atIndex:0];
    
    CAGradientLayer *left = [CAGradientLayer layer];
    left.frame = CGRectMake(0 + offsetX, 0 + offsetY, spread + radius, self.bounds.size.height);
    left.colors = colors;
    left.startPoint = CGPointMake(0.0, STATIC);
    left.endPoint = CGPointMake(1.0, STATIC);
    [self.layer insertSublayer:left atIndex:0];
}

- (void)blur {
    [FunBlurView inSuperview:self];
}

/* View hierarchy
 ****************/
- (instancetype)empty {
    [[self subviews] makeObjectsPerformSelector:@selector(removeAndClean)];
    return self;
}
- (UIView*)appendTo:(UIView *)superview {
    [superview addSubview:self];
    return self;
}
- (void)prependTo:(UIView *)superview {
    [superview insertSubview:self atIndex:0];
}
- (UIView *)firstSubview {
    return self.subviews.firstObject;
}
- (UIView *)lastSubview {
    return self.subviews.lastObject;
}
- (void)removeAndClean {
    [self removeFromSuperview];
    [self recursivelyCleanup];
}
- (UIView *)viewDescendantAtPoint:(CGPoint)point {
    if (!CGRectContainsPoint(self.bounds, point)) {
        return nil;
    }
    NSArray* subviews = self.subviews;
    for (NSInteger i=subviews.count-1; i>=0; i--) { // Loop in reverse to make top-most subview be hit first
        UIView* subview = subviews[i];
        CGPoint subviewPoint = [self convertPoint:point toView:subview];
        if ([subview pointInside:subviewPoint withEvent:nil]) {
            return [subview viewDescendantAtPoint:subviewPoint];
        }
    }
    return self;
}
- (NSInteger)indexInSuperview {
    return [self.superview.subviews indexOfObject:self];
}
- (UIView *)nextSiblingView {
    NSInteger index = self.indexInSuperview;
    if (index + 1 == self.superview.subviews.count) {
        return nil;
    }
    return self.superview.subviews[index + 1];
}
- (UIView *)previousSiblingView {
    NSInteger index = self.indexInSuperview;
    if (index == 0) {
        return nil;
    }
    return self.superview.subviews[index - 1];
}


/* Screenshot
 ************/
- (UIImage *)captureToImage {
    return [self captureToImageWithScale:0.0];
}
- (UIImage *)captureToImageWithScale:(CGFloat)scale {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, scale);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
- (NSData *)captureToJpgData:(CGFloat)compressionQuality {
    return UIImageJPEGRepresentation([self captureToImage], compressionQuality);
}
- (NSData *)captureToPngData {
    return UIImagePNGRepresentation([self captureToImage]);
}
- (UIView*)ghost {
    UIImage* ghostImage = [self captureToImage];
    UIImageView* ghostView = [UIImageView.appendTo(self.window).frame([self frameInWindow]) render];
    ghostView.image = ghostImage;
    return ghostView;
}
- (void)ghostWithDuration:(NSTimeInterval)duration animation:(GhostCallback)animationCallback {
    [self ghostWithDuration:duration options:0 animations:animationCallback];
}
- (void)ghostWithDuration:(NSTimeInterval)duration animation:(GhostCallback)animationCallback completion:(GhostCallback)completionCallback {
    [self ghostWithDuration:duration options:0 animations:animationCallback completion:completionCallback];
}
- (void)ghostWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(GhostCallback)animationCallback {
    [self ghostWithDuration:duration options:options animations:animationCallback completion:^(UIView *ghostView) {
        [ghostView removeAndClean];
    }];
}
- (void)ghostWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(GhostCallback)animationCallback completion:(GhostCallback)completionCallback {
    UIView* ghostView = self.ghost;
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        animationCallback(ghostView);
    } completion:^(BOOL finished) {
        completionCallback(ghostView);
    }];
}

/* Animations
 ************/
+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations {
    return [UIView animateWithDuration:duration delay:delay options:options animations:animations completion:nil];
}
- (void)rotate:(NSTimeInterval)duration {
    [self stopRotating];
    CABasicAnimation *rotation;
    rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = num(0);
    rotation.toValue = numf(2*M_PI);
    rotation.duration = duration;
    rotation.repeatCount = HUGE_VALF;
    [self.layer addAnimation:rotation forKey:@"FunRotateAnimation"];
}
- (void)stopRotating {
    [self.layer removeAnimationForKey:@"FunRotateAnimation"];
}
@end
