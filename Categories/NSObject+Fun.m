//
//  NSObject+Fun.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "NSObject+Fun.h"
#import "NSString+Fun.h"
#import "Log.h"

@implementation NSObject (Fun)
- (BOOL)isNull {
    return self == (id)[NSNull null];
}
- (NSString *)className {
    return NSStringFromClass(self.class);
}
@end
