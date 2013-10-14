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
@property CGFloat height;
@property CGRect frameBegin;
@property CGRect frameEnd;
@end

typedef void (^KeyboardEventCallback)(KeyboardEventInfo* info);

@interface Keyboard : NSObject
+ (void)onWillShow:(EventSubscriber)subscriber callback:(KeyboardEventCallback)callback;
+ (void)onWillHide:(EventSubscriber)subscriber callback:(KeyboardEventCallback)callback;
+ (void)offWillShow:(EventSubscriber)subscriber;
+ (void)offWillHide:(EventSubscriber)subscriber;
@end
