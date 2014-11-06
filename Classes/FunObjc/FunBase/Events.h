//
//  Events.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/26/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^EventCallback)(id info);
typedef id EventSubscriber;

@interface ScheduledEventFire : NSObject
- (void)fire;
- (void)fire:(id)info;
@end

@interface Events : NSObject
// Pass in `self` for subscriber
+ (void)on:(NSString*)signal subscriber:(EventSubscriber)subscriber callback:(EventCallback)callback;
+ (void)once:(NSString*)signal subscriber:(EventSubscriber)subscriber callback:(EventCallback)callback;
+ (void)off:(NSString*)signal subscriber:(EventSubscriber)subscriber;
+ (void)fire:(NSString*)signal info:(id)info;
+ (void)fire:(NSString*)signal;
+ (void)syncFire:(NSString*)signal info:(id)info;
+ (void)syncFire:(NSString*)signal;
+ (ScheduledEventFire*)scheduleEventFire:(NSString*)signal;
@end
