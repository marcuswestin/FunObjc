//
//  NSString+Fun.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "NSString+Fun.h"

@implementation NSString (Fun)

+ (NSString *)UUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

- (NSArray *)splitByComma {
    return [self split:@","];
}

- (NSArray *)split:(NSString *)splitter {
    return [self componentsSeparatedByString:splitter];
}

- (NSData *)toData {
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)stringByRemoving:(NSString *)needle {
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

- (BOOL)isEmpty {
    return self.length == 0;
}

- (BOOL)is:(NSString *)string {
    return [self isEqualToString:string];
}

- (NSString *)append:(NSString *)string {
    return [self stringByAppendingString:string];
}

@end
