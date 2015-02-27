//
//  PhoneNumbers.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "PhoneNumbers.h"
#import "NSString+Fun.h"
#import "RMPhoneFormat.h"
#import "FunObjc.h"

@implementation PhoneNumbers

static NSString* locale;

+ (void)initialize {
    locale = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

+ (NSString *)format:(NSString *)phoneNumber {
    return [RMPhoneFormat.instance format:phoneNumber];
}

+ (BOOL)isValid:(NSString *)phoneNumber {
    return [RMPhoneFormat.instance isPhoneNumberValid:phoneNumber];
}

+ (NSString *)normalize:(NSString *)phoneNumber {
    NSString* normalized = [PhoneNumbers _normalize:phoneNumber];
    if (!normalized) { return nil; }
    return [PhoneNumbers isValid:normalized] ? normalized : nil;
}
+ (NSString *)_normalize:(NSString *)phoneNumber {
    if (!phoneNumber || !phoneNumber.length) { return nil; }

    NSString* normalized = [phoneNumber stringByRemovingPattern:@"[\\s\\-\\(\\)]"];
    
    if (normalized.length == 0) {
        return nil;
    
    } else if ([normalized characterAtIndex:0] == '+') {
        return normalized;

    } else if ([locale isEqualToString:@"US"] && [normalized characterAtIndex:0] == '1') {
        // In the US, we should handle 1-412-423-8869 like +1-412-423-8669
        return [@"+" stringByAppendingString:normalized];
        
    } else {
        return [NSString stringWithFormat:@"+%@%@", RMPhoneFormat.instance.defaultCallingCode, normalized];
    }
}

+ (BOOL)isUSPhoneNumber:(NSString *)phoneNumber {
    NSRange range = [[PhoneNumbers normalize:phoneNumber] rangeOfString:@"+1"];
    return range.location == 0;
}
@end
