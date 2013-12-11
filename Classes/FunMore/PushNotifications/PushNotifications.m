//
//  Notifications.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 7/13/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "PushNotifications.h"

#if defined PLATFORM_OSX
#define NotificationTypes (UIRemoteNotificationTypeBadge)
#define PUSH_TYPE @"osx"
#define UIRemoteNotificationTypeAlert NSRemoteNotificationTypeAlert

#elif defined PLATFORM_IOS
#define NotificationTypes (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)
#define PUSH_TYPE @"ios"
#endif

#if defined DEBUG
#define PUSH_MODE @"_sandbox"
#else
#define PUSH_MODE @""
#endif

@implementation NotificationInfo
- (NSString *)alert {
    return _data[@"aps"][@"alert"];
}
- (NSUInteger)badge {
    return (_data[@"aps"][@"badge"] ? [_data[@"aps"][@"badge"] unsignedIntegerValue] : 0);
}
- (NSString *)sound {
    return _data[@"aps"][@"sound"];
}
- (id)objectForKeyedSubscript:(id)key {
    return _data[key];
}
@end

@implementation PushAuthorization
@end

static PushAuthorizationCallback authorizationCallback;

@implementation PushNotifications

+ (void)onPushNotification:(EventSubscriber)subscriber callback:(PushNotificationCallback)callback {
    [Events on:@"Application.didReceiveRemoteNotification" subscriber:subscriber callback:^(id info) {
        callback([self _pushNotificationInfo:info]);
    }];
}

+ (void)onLaunchNotification:(EventSubscriber)subscriber callback:(PushNotificationCallback)callback {
    [Events on:@"Application.didLaunchWithNotification" subscriber:subscriber callback:^(id info) {
        callback([self _pushNotificationInfo:info]);
    }];
}

+ (void)offPushNotification:(EventSubscriber)subscriber {
    [Events off:@"Application.didReceiveRemoteNotification" subscriber:subscriber];
}

+ (void)offLaunchNotification:(EventSubscriber)subscriber {
    [Events off:@"Application.didLaunchWithNotification" subscriber:subscriber];
}

+ (NotificationInfo*)_pushNotificationInfo:(NSDictionary*)notificationData {
    NotificationInfo* info = [NotificationInfo new];
    info.data = notificationData;
    return info;
}

+ (BOOL)deviceSupportsRemoteNotifications {
    return !isSimulator;
}

+ (void)initialize {
    [Events on:@"Application.didRegisterForRemoteNotificationsWithDeviceToken" subscriber:self callback:^(NSData* deviceToken) {
        NSLog(@"PushNotifications: Authorized");
        PushAuthorization* auth = [PushAuthorization new];
        auth.vendor = [PUSH_TYPE stringByAppendingString:PUSH_MODE]; // ios, ios-sandbox, osx, osx-sandbox
        auth.token = [PushNotifications tokenString:deviceToken];
        authorizationCallback(nil, auth);
    }];
    
    [Events on:@"Application.didFailToRegisterForRemoteNotificationsWithError" subscriber:self callback:^(NSError* err) {
        NSLog(@"PushNotifications: Failed Auth");
        authorizationCallback(err, nil);
    }];
    
    [PushNotifications onPushNotification:self callback:^(NotificationInfo *info) {
        [PushNotifications setBadgeNumber:info.badge];
    }];
}

+ (NSString*)tokenString:(NSData*)deviceToken {
    return [[[deviceToken description]
             stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
            stringByReplacingOccurrencesOfString:@" "
            withString:@""];
}

+ (void)authorize:(PushAuthorizationCallback)callback {
    authorizationCallback = ^(NSError *err, PushAuthorization *auth) {
        callback(err, auth);
        authorizationCallback = nil;
    };
    NSLog(@"PushNotifications: Authorize");
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:NotificationTypes];
}

+ (NSDictionary*)authorizationStatus {
    UIRemoteNotificationType types = [UIApplication.sharedApplication enabledRemoteNotificationTypes];
    if (types == UIRemoteNotificationTypeNone) { return nil; }
    
    NSMutableDictionary* res = [NSMutableDictionary dictionary];
    if (types | UIRemoteNotificationTypeAlert) { res[@"alert"] = [NSNumber numberWithBool:YES]; }
    if (types | UIRemoteNotificationTypeBadge) { res[@"badge"] = [NSNumber numberWithBool:YES]; }
    if (types | UIRemoteNotificationTypeSound) { res[@"sound"] = [NSNumber numberWithBool:YES]; }
    return res;
}

+ (void)incrementBadgeNumber:(NSInteger)incrementBy {
    [self setBadgeNumber:[self getBadgeNumber] + incrementBy];
}

+ (void)decrementBadgeNumber:(NSInteger)decrementBy {
    [self setBadgeNumber:[self getBadgeNumber] - decrementBy];
}

/* Platform specific OSX
 ***********************/
#if defined PLATFORM_OSX
+ (NSInteger) getBadgeNumber { return 0; }
+ (void) setBadgeNumber:(NSInteger)number {}
//- (void) handleDidReceiveRemoteNotification:(NSNotification*)notification {
//    [self handlePushNotification:notification.userInfo[@"notification"] didBringAppToForeground:NO];
//}

/* Platform specific iOS
 ***********************/
#elif defined PLATFORM_IOS
+ (NSInteger) getBadgeNumber {
    return [[UIApplication sharedApplication] applicationIconBadgeNumber];
}
+ (void) setBadgeNumber:(NSInteger)number {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:number];
}
//- (void) handleDidReceiveRemoteNotification:(NSNotification*)notification {
//    [self handlePushNotification:notification.userInfo[@"notification"] didBringAppToForeground:([UIApplication sharedApplication].applicationState != UIApplicationStateActive)];
//}
#endif

@end
