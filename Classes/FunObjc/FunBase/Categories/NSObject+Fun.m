//
//  NSObject+Fun.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "NSObject+Fun.h"
#import "FunRuntimeProperties.h"
#import "FastCoder.h"

@implementation NSObject (Fun)
- (BOOL)isNull {
    return self == (id)[NSNull null];
}
- (NSString *)className {
    return NSStringFromClass(self.class);
}

static NSMutableDictionary* classPropCache;

- (NSDictionary *)classProperties {
    if (!classPropCache) {
        classPropCache = [NSMutableDictionary dictionary];
    }

    if (!classPropCache[self.className]) {
        classPropCache[self.className] = GetClassProperties(self.class);
    }
    
    return classPropCache[self.className];
}

- (NSData *)fastEncode {
    return [FastCoder encode:self];
}

@end
