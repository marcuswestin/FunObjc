//
//  NSNumber+Fun.m
//  ivyq
//
//  Created by Marcus Westin on 9/6/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "NSNumber+Fun.h"

@implementation NSNumber (Fun)

- (NSNumber *)numberByAdding:(float)amount {
    return [NSNumber numberWithFloat:self.floatValue + amount];
}

- (NSString *)suffix {
    return [NSNumber suffix:[self integerValue]];
}

+ (NSString *)suffix:(NSInteger)d {
    d = d % 10;
    if (d == 1) {
        return @"st";
    } else if (d == 2) {
        return @"nd";
    } else if (d == 3) {
        return @"rd";
    } else {
        return @"th";
    }
}

@end
