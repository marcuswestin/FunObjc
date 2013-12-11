//
//  Events.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/26/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Events.h"
#import "FunBase.h"

@implementation Events

static NSMutableDictionary* signals;
static const NSString* RefKey = @"Sub";
static const NSString* CbKey = @"Cb";

#pragma mark - API

+ (void)initialize {
    signals = [NSMutableDictionary dictionary];
}

+ (void)on:(NSString *)signal subscriber:(EventSubscriber)subscriber callback:(EventCallback)callback {
    if (!signals[signal]) {
        signals[signal] = [NSMutableArray array];
    }
    [signals[signal] addObject:@{RefKey:subscriber, CbKey:callback}];
}

+ (void)off:(NSString *)signal subscriber:(EventSubscriber)subscriber {
    NSMutableArray* callbacks = signals[signal];
    for (NSDictionary* obj in callbacks) {
        if (obj[RefKey] == subscriber) {
            [callbacks removeObject:obj];
            break;
        }
    }
}

+ (void)fire:(NSString *)signal {
    [Events fire:signal info:nil];
}

+ (void)fire:(NSString *)signal info:(id)info {
    NSArray* callbacks = [signals[signal] copy];
    asyncMain(^{
        [self syncFire:signal callbacks:callbacks info:info];
    });
}

+ (void)syncFire:(NSString *)signal info:(id)info {
    NSArray* callbacks = [signals[signal] copy];
    [Events syncFire:signal callbacks:callbacks info:info];
}


+ (void)syncFire:(NSString *)signal {
    [self syncFire:signal info:nil];
}
+ (void)syncFire:(NSString *)signal callbacks:(NSArray*)callbacks info:(id)info {
    if (info) {
        NSLog(@"@ Event %@, Info: %@", signal, info);
    } else {
        NSLog(@"@ Event %@", signal);
    }
    for (NSDictionary* obj in callbacks) {
        EventCallback callback = obj[CbKey];
        callback(info);
    }
}
@end
