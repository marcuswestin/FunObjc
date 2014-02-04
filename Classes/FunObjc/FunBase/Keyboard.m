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

@implementation KeyboardEventInfo
- (void)animate:(void (^)(void))animations {
    [UIView animateWithDuration:_duration delay:0 options:_curve animations:animations completion:^(BOOL finished) {}];
}
@end

@implementation Keyboard

static Keyboard* instance;

+ (void)initialize {
    instance = [Keyboard new];
    NSNotificationCenter* notifications = [NSNotificationCenter defaultCenter];
    [notifications addObserver:instance selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [notifications addObserver:instance selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [notifications addObserver:instance selector:@selector(_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
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

+ (void)dismiss {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

+ (UIViewAnimationOptions)animationOptions {
    return (UIViewAnimationOptions)458752;
}

+ (BOOL)isVisible {
    return instance.isVisible;
}

+ (CGFloat)visibleHeight {
    return instance.visibleHeight;
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

- (void)_keyboardWillShow:(NSNotification*)notification {
    KeyboardEventInfo* info = [self _keyboardInfo:notification isShowing:YES];
    instance.isVisible = YES;
    instance.visibleHeight = info.height;
    [Events syncFire:@"KeyboardWillShow" info:info];
}

- (void)_keyboardWillHide:(NSNotification*)notification {
    KeyboardEventInfo* info = [self _keyboardInfo:notification isShowing:NO];
    instance.isVisible = NO;
    instance.visibleHeight = info.height;
    [Events syncFire:@"KeyboardWillHide" info:info];
}

- (void)_keyboardWillChangeFrame:(NSNotification*)notification {
    [self _scheduleFireChange:notification];
    
}

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
    info.frameBegin = [notif.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    info.frameEnd = [notif.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    info.heightChange = (info.frameBegin.origin.y - info.frameEnd.origin.y);
    info.height = ([Viewport height] - info.frameEnd.origin.y);
    return info;
}


@end
