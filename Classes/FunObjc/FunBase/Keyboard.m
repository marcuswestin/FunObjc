//
//  Keyboard.m
//  ivyq
//
//  Created by Marcus Westin on 10/14/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Keyboard.h"
#import "Viewport.h"
#import "FunGlobals.h"
#import "UIView+Fun.h"

@implementation KeyboardEventInfo
- (void)animate:(void (^)(void))animations {
    [self animate:animations completion:^(BOOL finished) {}];
}
- (void)animate:(void (^)(void))animations completion:(void (^)(BOOL))completion {
    [UIView animateWithDuration:_duration delay:0 options:_curve animations:animations completion:completion];
}
@end

@interface Keyboard ()
@property BOOL isVisible;
@property UIView* overlay;
@property (copy) void (^resizeBlock)(UIView* overlay);
@end

@implementation Keyboard

static Keyboard* instance;

+ (void)initialize {
    instance = [Keyboard new];
    NSNotificationCenter* notifications = [NSNotificationCenter defaultCenter];
//    [notifications addObserver:instance selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [notifications addObserver:instance selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [notifications addObserver:instance selector:@selector(_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
//    [notifications addObserver:self selector:@selector(_keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [notifications addObserver:instance selector:@selector(_keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    currentFrame = CGRectMake(0, [Viewport height], [Viewport width], 0);
}

+ (void)onWillShow:(EventSubscriber)subscriber callback:(KeyboardEventCallback)callback {
    [Events on:@"KeyboardWillShow" subscriber:subscriber callback:callback];
}

+ (void)onWillHide:(EventSubscriber)subscriber callback:(KeyboardEventCallback)callback {
    [Events on:@"KeyboardWillHide" subscriber:subscriber callback:callback];
}

+ (void)onWillChange:(EventSubscriber)subscriber callback:(KeyboardEventCallback)callback {
    [Events on:@"KeyboardWillChange" subscriber:subscriber callback:callback];
}

+ (void)offWillShow:(EventSubscriber)subscriber {
    [Events off:@"KeyboardWillShow" subscriber:subscriber];
}

+ (void)offWillHide:(EventSubscriber)subscriber {
    [Events off:@"KeyboardWillHide" subscriber:subscriber];
}

+ (void)offWillChange:(EventSubscriber)subscriber {
    [Events off:@"KeyboardWillChange" subscriber:subscriber];
}

+ (void)off:(EventSubscriber)subscriber {
    [Keyboard offWillShow:subscriber];
    [Keyboard offWillHide:subscriber];
    [Keyboard offWillChange:subscriber];
}

+ (void)hide { return [self dismiss]; }
+ (void)dismiss {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

+ (UIViewAnimationOptions)animationOptions {
    return (UIViewAnimationOptions)458752;
}

+ (void)animation:(Block)animationBlock {
    [self animation:animationBlock completion:nil];
}

+ (void)animation:(Block)animationBlock completion:(void (^)(BOOL finished))completionBlock {
    [UIView animateWithDuration:[Keyboard animationDuration] delay:0 options:[Keyboard animationOptions] animations:animationBlock completion:completionBlock];
}

+ (BOOL)isVisible {
    return instance.isVisible;
}

+ (NSTimeInterval)animationDuration {
    return (NSTimeInterval)0.25;
}

+ (CGFloat)heightForNumberPad {
    return 216;
}

+ (CGFloat)heightForDefaultKeyboard {
    return 216; // TODO Detect locale
}

+ (CGFloat)heightForLargestKeyboard {
    return 252;
}

+ (BOOL)hasOverlay {
    return !!instance.overlay;
}

+ (void)renderOverlay:(void (^)(UIView *))renderBlock resizeBlock:(void (^)(UIView *))resizeBlock {
    if ([Keyboard hasOverlay]) {
        // Remove previous overlay
        [instance.overlay removeFromSuperview];
    } else {
        // Setup height change listened overlay. Removed in removeOverlay
        [Keyboard onWillChange:instance callback:^(KeyboardEventInfo *info) {
            instance.overlay.height += info.heightChange;
            instance.overlay.y -= info.heightChange;
            instance.resizeBlock(instance.overlay);
        }];
    }
    UIWindow* window = [[[UIApplication sharedApplication] windows] objectAtIndex:1];
    instance.overlay = [UIView.appendTo(window).frame(currentFrame) render];
    instance.resizeBlock = resizeBlock;
    renderBlock(instance.overlay);
}

+ (void)removeOverlay {
    [Keyboard offWillChange:instance];
    [instance.overlay removeFromSuperview];
    instance.overlay = nil;
    instance.resizeBlock = nil;
}

//- (void)_keyboardWillShow:(NSNotification*)notification {
//    KeyboardEventInfo* info = [self _keyboardInfo:notification isShowing:YES];
//    instance.isVisible = YES;
//    instance.visibleHeight = info.height;
//    [Events syncFire:@"KeyboardWillShow" info:info];
//}
//
//- (void)_keyboardWillHide:(NSNotification*)notification {
//    [Keyboard removeOverlay];
//    KeyboardEventInfo* info = [self _keyboardInfo:notification isShowing:NO];
//    instance.isVisible = NO;
//    currentFrame = CGRectMake(0, [Viewport height], [Viewport width], 0);
//    after(0, ^{
//        
//    });
//    instance.visibleHeight = info.height;
//    [Events syncFire:@"KeyboardWillHide" info:info];
//}

//- (void)_keyboardDidChangeFrame:(NSNotification*)notification {
//    
//}

- (void)_keyboardDidHide:(NSNotification*)notification {
    currentFrame = CGRectMake(0, [Viewport height], [Viewport width], 0);
    instance.isVisible = NO;
    [Keyboard removeOverlay];
}

- (void)_keyboardWillChangeFrame:(NSNotification*)notification {
    [self _scheduleFireChange:notification];
}

static CGRect currentFrame;

static NSNotification* nextNotification;
- (void)_scheduleFireChange:(NSNotification*)notification {
    if (nextNotification) { return; }
    nextNotification = notification;

    // A visible keyboard issues a "willHide" then a "willShow" (along with two "willChange")
    // "willHide" reports a -216 height change (because it would change by -216).
    // "willShow" reports a 0 height change (because the keyboard is already visible).
    // So we wait a brief moment. In case of two "willChange", we report only the second (with 0 height change).
    async(^{
        KeyboardEventInfo* info = [self _keyboardInfo:nextNotification isShowing:instance.isVisible];
        nextNotification = nil;
        [Events syncFire:@"KeyboardWillChange" info:info];
    });
}


- (KeyboardEventInfo*)_keyboardInfo:(NSNotification*)notif isShowing:(BOOL)isShowing {
    KeyboardEventInfo* info = [KeyboardEventInfo new];
    info.duration = [notif.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    info.curve = [notif.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue] << 16; // see http://stackoverflow.com/questions/18957476/ios-7-keyboard-animation
    if (!info.duration) {
        info.curve = 0; // UIView animation does not respect duration if curve is keyboard curve
    }
    CGRect frameBegin = currentFrame;
    CGRect frameEnd = [notif.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    currentFrame = frameEnd;
    
    info.frameBegin = frameBegin;
    info.frameEnd = frameEnd;
    if (frameBegin.origin.y > [Viewport height]) {
        frameBegin.origin.y = [Viewport height];
    }
    if (frameEnd.origin.y > [Viewport height]) {
        frameEnd.origin.y = [Viewport height];
    }
    info.heightChange = (frameBegin.origin.y - frameEnd.origin.y);
    return info;
}

+ (UIView *)findFirstResponder {
    return [[UIApplication sharedApplication].keyWindow findFirstResponder];
}

@end
