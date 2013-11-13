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
    d = d % 100;
    if (d >= 11 && d <= 13) {
        // 11th, 12th, 13th, 111th, 2013th, ...
        return @"th";
    }
    d = d % 10;
    if (d == 1) {
        // 1st, 21st, 101st, 4301st, ...
        return @"st";
    } else if (d == 2) {
        // 2nd, ...
        return @"nd";
    } else if (d == 3) {
        // 3rd, ...
        return @"rd";
    } else {
        // 0th, 4th, 10th, 14th, 20th, 100th, ...
        return @"th";
    }
}

@end
