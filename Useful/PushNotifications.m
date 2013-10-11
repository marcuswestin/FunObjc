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

#endif

@implementation PushAuthorization
@end

static PushAuthorizationCallback authorizationCallback;

@implementation PushNotifications

+ (BOOL)deviceSupportsRemoteNotifications {
    return !isSimulator;
}

+ (void)load {
    [Events on:@"Application.didRegisterForRemoteNotificationsWithDeviceToken" callback:^(NSData* deviceToken) {
        NSString* tokenAsString = [[[deviceToken description]
                                    stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                                   stringByReplacingOccurrencesOfString:@" "
                                   withString:@""];
        PushAuthorization* auth = [PushAuthorization new];
        auth.vendor = [PUSH_TYPE stringByAppendingString:PUSH_MODE]; // ios, ios-sandbox, osx, osx-sandbox
        auth.token = tokenAsString;
        authorizationCallback(nil, auth);
    }];
    [Events on:@"Application.didFailToRegisterForRemoteNotificationsWithError" callback:^(NSError* err) {
        authorizationCallback(err, nil);
        authorizationCallback = nil;
    }];
    [Events on:@"Application.didReceiveRemoteNotification" callback:^(NSDictionary* notification) {
        [Events fire:@"Notifications.notification" info:@{ @"notification":notification }];
    }];
    [Events on:@"Application.didLaunchWithNotification" callback:^(NSDictionary* notification) {
        [Events fire:@"Notifications.notification" info:@{ @"notification":notification,
                                                           @"didBringAppIntoForeground":num(1) }];
    }];
}

+ (void)authorize:(PushAuthorizationCallback)callback {
    authorizationCallback = callback;
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
