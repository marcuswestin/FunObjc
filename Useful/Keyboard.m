//
//  Keyboard.m
//  ivyq
//
//  Created by Marcus Westin on 10/14/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Keyboard.h"

@implementation KeyboardEventInfo
@end

@implementation Keyboard

static Keyboard* instance;

+ (void)initialize {
    instance = [Keyboard new];
    NSNotificationCenter* notifications = [NSNotificationCenter defaultCenter];
    [notifications addObserver:instance selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [notifications addObserver:instance selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

+ (void)onWillShow:(EventSubscriber)subscriber callback:(KeyboardEventCallback)callback {
    [Events on:@"KeyboardWillShow" subscriber:subscriber callback:callback];
}

+ (void)onWillHide:(EventSubscriber)subscriber callback:(KeyboardEventCallback)callback {
    [Events on:@"KeyboardWillHide" subscriber:subscriber callback:callback];
}

+ (void)offWillShow:(EventSubscriber)subscriber {
    [Events off:@"KeyboardWillShow" subscriber:subscriber];
}

+ (void)offWillHide:(EventSubscriber)subscriber {
    [Events off:@"KeyboardWillHide" subscriber:subscriber];
}

+ (void)dismiss {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

+ (UIViewAnimationOptions)animationOptions {
    return (UIViewAnimationOptions)458752;
}

+ (NSTimeInterval)animationDuration {
    return (NSTimeInterval)0.25;
}

- (void)_keyboardWillShow:(NSNotification*)notification {
    [Events syncFire:@"KeyboardWillShow" info:[self _keyboardInfo:notification isShowing:YES]];
}

- (void)_keyboardWillHide:(NSNotification*)notification {
    [Events syncFire:@"KeyboardWillHide" info:[self _keyboardInfo:notification isShowing:NO]];
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
    info.heightChange = (info.frameEnd.origin.y - info.frameBegin.origin.y);
    return info;
}

@end
