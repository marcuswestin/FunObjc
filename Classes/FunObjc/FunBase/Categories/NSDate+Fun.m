//
//  NSDate+Fun.m
//  Pen and Paper iOS
//
//  Created by Marcus Westin on 9/11/14.
//  Copyright (c) 2014 Flutterby Labs Inc. All rights reserved.
//

#import "NSDate+Fun.h"
#import "NSNumber+Fun.h"
#import "NSDate+Utilities.h"

long long minutesToMilliseconds(long long minutes) {
    return secondsToMilliseconds(minutes * 60);
}
long long secondsToMilliseconds(long long seconds) {
    return seconds * 1000;
}
long long millisecondsToSeconds(long long milliseconds) {
    return milliseconds / 1000;
}

@implementation NSDate (Fun)

+ (NSTimeInterval)timeIntervalSince1970 {
    return [[NSDate new] timeIntervalSince1970];
}
+ (long long)millisecondsSince1970 {
    return [[NSDate new] millisecondsSince1970];
}
- (long long)millisecondsSince1970 {
    return secondsToMilliseconds([self timeIntervalSince1970]);
}

+ (NSDate *)epoch {
    static NSDate* epoch;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        epoch = [NSDate dateWithTimeIntervalSince1970:0];
    });
    return epoch;
}

- (NSInteger)daysSinceEpoch {
    return [NSDate daysBetweenDate:[NSDate epoch] andDate:self];
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime {
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

// Names
- (NSString *)nameOfMonth {
    return [[NSDateFormatter new] monthSymbols][self.month - 1];
}
- (NSString *)nameOfMonthShort {
    return [[NSDateFormatter new] shortMonthSymbols][self.month - 1];
}
- (NSString *)nameOfMonthVeryShort {
    return [[NSDateFormatter new] veryShortMonthSymbols][self.month - 1];
}
- (NSString *)nameOfDay {
    return [[NSDateFormatter new] weekdaySymbols][self.weekday - 1];
}
- (NSString *)nameOfDayShort {
    return [[NSDateFormatter new] shortWeekdaySymbols][self.weekday - 1];
}
- (NSString *)nameOfDayVeryShort {
    return [[NSDateFormatter new] veryShortWeekdaySymbols][self.weekday - 1];
}
- (NSString *)nameOfDayNumeric {
    return [NSString stringWithFormat:@"%ld", (long)self.day];
}
- (NSString*)nameOfDayNumericSuffix {
    return [NSNumber suffix:self.day+1];
}
- (NSString *)timeOfDayAmPm {
    NSDateFormatter* formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"h:mm a"]; // "3:19 PM"
    [formatter setLocale:[NSLocale currentLocale]];
    return [formatter stringFromDate:self];
    //    return [NSString stringWithFormat:@"%.2d:%.2d%@", (date.hour+1)%13, date.minute]
}

@end
