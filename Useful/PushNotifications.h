//
//  Notifications.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 7/13/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunBase.h"
#import "Events.h"

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
@end
