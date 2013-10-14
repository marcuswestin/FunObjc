//
//  Notifications.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 7/13/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Events.h"
#import "FunObjc.h"

@interface PushNotification : NSObject
@property NSDictionary* data;
@property (readonly) NSString* alert;
@property (readonly) NSUInteger badge;
@property (readonly) NSString* sound;
@end
typedef void (^PushNotificationCallback)(PushNotification* info);

@interface PushAuthorization : State
@property NSString* vendor;
@property NSString* token;
@end
typedef void (^PushAuthorizationCallback)(NSError* err, PushAuthorization* auth);

@interface PushNotifications : NSObject
+ (BOOL) deviceSupportsRemoteNotifications;
+ (void) authorize:(PushAuthorizationCallback)callback;
+ (NSDictionary*) authorizationStatus;
+ (NSInteger) getBadgeNumber;
+ (void) setBadgeNumber:(NSInteger)number;
+ (void) incrementBadgeNumber:(NSInteger)incrementBy;
+ (void) decrementBadgeNumber:(NSInteger)decrementBy;
+ (void) onPushNotification:(EventSubscriber)subscriber callback:(PushNotificationCallback)callback;
+ (void) onLaunchNotification:(EventSubscriber)subscriber callback:(PushNotificationCallback)callback;
+ (void) offPushNotification:(EventSubscriber)subscriber;
+ (void) offLaunchNotification:(EventSubscriber)subscriber;
@end
