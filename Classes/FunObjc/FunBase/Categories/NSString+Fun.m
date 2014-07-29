//
//  NSString+Fun.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "NSString+Fun.h"
#import "FunBase.h"

@implementation NSString (Fun)

+ (NSString *)UUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

+ (NSString *)repeat:(NSString *)string times:(NSInteger)times {
    return [string repeatTimes:times];
}

- (NSString *)repeatTimes:(NSInteger)times {
    if (times <= 0) { return @""; }
    return [self stringByPaddingToLength:times*self.length withString:self startingAtIndex:0];
}

- (NSArray *)splitByComma {
    return [self split:@","];
}

- (NSArray *)splitByWhitespace {
    return [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSArray *)split:(NSString *)splitter {
    return [self componentsSeparatedByString:splitter];
}

- (NSData *)toData {
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)stringByRemovingString:(NSString *)needle {
    return [self stringByReplacingOccurrencesOfString:needle withString:@""];
}

- (NSString *)trim {
    return [self stringByTrimmingWhitespace];
}

- (NSString *)encodedURIComponent {
    return (__bridge NSString*) CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL,
                                                                        (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", kCFStringEncodingUTF8 );
}

- (NSString *)stringByTrimmingWhitespace {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \n\t\r"]];
}

- (BOOL)hasContent {
    return self.length != 0;
}

- (BOOL)is:(NSString *)string {
    return [self isEqualToString:string];
}

- (NSString *)append:(NSString *)string {
    return [self stringByAppendingString:string];
}

- (NSString *)stringByReplacingPattern:(NSString *)regexPattern withTemplate:(NSString *)replaceTemplate {
    NSError* err;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:&err];
    if (err) {
        NSLog(@"Error in stringByReplacingPattern:withTemplate: %@", err);
        return nil;
    }
    
    return [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:replaceTemplate];
}

- (NSString *)stringByRemovingPattern:(NSString *)regexPattern {
    return [self stringByReplacingPattern:regexPattern withTemplate:@""];
}

- (NSString *)stringByInjecting:(NSString *)injectString every:(NSUInteger)nth {
    if (self.length < nth) {
        return self;
    }
    
    NSUInteger times = (self.length-1) / nth;
    NSMutableString* result = [NSMutableString stringWithCapacity:self.length + injectString.length*times];
    for (NSUInteger i=0; i<times; i++) {
        [result appendString:[self substringWithRange:NSRangeMake(i*nth, nth)]];
        [result appendString:injectString];
    }
    
    [result appendString:[self substringWithRange:NSRangeMake(times*nth, self.length - times*nth)]];
    return result;
}

- (NSString *)stringByRemovingWhitespace {
    return [self stringByRemovingPattern:@"\\s"];
}

- (BOOL)matchesPattern:(NSString *)regexPattern {
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexPattern] evaluateWithObject:self];
}

- (BOOL)startsWith:(NSString *)string {
    return [[self substringToIndex:string.length] isEqualToString:string];
}

- (NSInteger)countOccurancesOfSubstring:(NSString*)substr {
    NSUInteger count = 0;
    NSUInteger length = [self length];
    NSRange range = NSMakeRange(0, length);
    while(range.location != NSNotFound) {
        range = [self rangeOfString:substr options:0 range:range];
        if(range.location != NSNotFound) {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
    return count;
}
@end
