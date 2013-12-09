//
//  Keyboard.h
//  ivyq
//
//  Created by Marcus Westin on 10/14/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Events.h"

@interface KeyboardEventInfo : NSObject
@property NSTimeInterval duration;
@property UIViewAnimationOptions curve;
@property CGRect frameBegin;
@property CGRect frameEnd;
@property CGFloat heightChange;
@property CGFloat height;
- (void) animate:(void (^)(void))animations;
@end

typedef void (^KeyboardEventCallback)(KeyboardEventInfo* info);

@interface Keyboard : NSObject
@property BOOL isVisible;
@property CGFloat visibleHeight;
+ (void)onWillShow:(EventSubscriber)subscriber callback:(KeyboardEventCallback)callback;
+ (void)onWillHide:(EventSubscriber)subscriber callback:(KeyboardEventCallback)callback;
+ (void)offWillShow:(EventSubscriber)subscriber;
+ (void)offWillHide:(EventSubscriber)subscriber;
+ (UIViewAnimationOptions)animationOptions;
+ (NSTimeInterval)animationDuration;
+ (void)dismiss;

+ (CGFloat)heightForNumberPad;
+ (CGFloat)heightForDefaultKeyboard;
+ (CGFloat)heightForLargestKeyboard;

+ (BOOL)isVisible;
+ (CGFloat)visibleHeight;

@end
