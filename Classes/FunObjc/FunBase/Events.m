//
//  Events.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/26/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Events.h"
#import "FunBase.h"

@interface Subscription : NSObject
@property (weak) EventSubscriber subscriber;
@property (copy) EventCallback callback;
+ (instancetype)withSubscriber:(EventSubscriber)subscriber callback:(EventCallback)callback;
@end
@implementation Subscription
+ (instancetype)withSubscriber:(EventSubscriber)subscriber callback:(EventCallback)callback {
    Subscription* subscription = [Subscription new];
    subscription.subscriber = subscriber;
    subscription.callback = callback;
    return subscription;
}
@end

@interface ScheduledEventFire ()
@property NSArray* subscribers;
@end
@implementation ScheduledEventFire
- (void)fire {
    [self fire:nil];
}
- (void)fire:(id)info {
    for (Subscription* subscription in _subscribers) {
        subscription.callback(info);
    }
    _subscribers = nil;
}

@end

@implementation Events
static NSMutableDictionary* signals;
#pragma mark - API
+ (void)initialize {
    signals = [NSMutableDictionary dictionary];
}

+ (void)on:(NSString *)signal subscriber:(EventSubscriber)subscriber callback:(EventCallback)callback {
    if (!signals[signal]) {
        signals[signal] = [NSMutableSet set];
    }
    [signals[signal] addObject:[Subscription withSubscriber:subscriber callback:callback]];
}

+ (void)once:(NSString *)signal subscriber:(EventSubscriber)subscriber callback:(EventCallback)callback {
    [Events on:signal subscriber:subscriber callback:^(id info) {
        callback(info);
        [Events off:signal subscriber:subscriber];
    }];
}

+ (void)off:(NSString *)signal subscriber:(EventSubscriber)subscriber {
    NSMutableSet* callbacks = signals[signal];
    for (Subscription* subscription in callbacks) {
        if (subscription.subscriber == subscriber) {
            [callbacks removeObject:subscription];
            break;
        }
    }
}

+ (void)fire:(NSString *)signal {
    [Events fire:signal info:nil];
}

+ (void)fire:(NSString *)signal info:(id)info {
    NSSet* callbacks = [signals[signal] copy];
    asyncMain(^{
        [self syncFire:signal callbacks:callbacks info:info];
    });
}

+ (void)syncFire:(NSString *)signal info:(id)info {
    NSSet* callbacks = [signals[signal] copy];
    [Events syncFire:signal callbacks:callbacks info:info];
}


+ (void)syncFire:(NSString *)signal {
    [self syncFire:signal info:nil];
}
+ (void)syncFire:(NSString *)signal callbacks:(NSSet*)callbacks info:(id)info {
    if (info) {
        DLog(@"@ Event %@, Info: %@", signal, info);
    } else {
        DLog(@"@ Event %@", signal);
    }
    for (Subscription* subscription in callbacks) {
        subscription.callback(info);
    }
}
+ (ScheduledEventFire *)scheduleEventFire:(NSString *)signal {
    ScheduledEventFire* scheduledEventFire = [ScheduledEventFire new];
    scheduledEventFire.subscribers = [signals[signal] copy];
    return scheduledEventFire;
}
@end
