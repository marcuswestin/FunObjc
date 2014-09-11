//
//  NSDate+Fun.h
//  Pen and Paper iOS
//
//  Created by Marcus Westin on 9/11/14.
//  Copyright (c) 2014 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

long long secondsToMilliseconds(long long seconds);
long long minutesToMilliseconds(long long minutes);
long long millisecondsToSeconds(long long milliseconds);

@interface NSDate (Fun)

+ (NSTimeInterval) timeIntervalSince1970;
+ (long long) millisecondsSince1970;
- (long long) millisecondsSince1970;
- (NSInteger)daysSinceEpoch;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

// Names
@property (readonly) NSString* nameOfMonth;
@property (readonly) NSString* nameOfMonthShort;
@property (readonly) NSString* nameOfMonthVeryShort;
@property (readonly) NSString* nameOfDay;
@property (readonly) NSString* nameOfDayShort;
@property (readonly) NSString* nameOfDayVeryShort;
@property (readonly) NSString* nameOfDayNumeric;
@property (readonly) NSString* nameOfDayNumericSuffix;
@property (readonly) NSString* timeOfDayAmPm;

@end
