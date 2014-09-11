//
//  NSString+Fun.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Fun)

+ (NSString*)UUID;
+ (NSString*)repeat:(NSString*)string times:(NSInteger)times;
- (NSString*)repeatTimes:(NSInteger)times;
- (NSArray*)splitByComma;
- (NSArray*)splitByWhitespace;
- (NSArray*)split:(NSString*)splitter;
- (NSData*)toData;
- (NSString*)stringByRemovingString:(NSString*)needle;
- (NSString*)stringByRemovingWhitespace;
- (NSString*)encodedURIComponent;
- (NSString*)stringByTrimmingWhitespace;
- (NSString*)trim;
- (BOOL)hasContent;
- (BOOL)is:(NSString*)string;
- (NSString*)append:(NSString*)string;
- (NSString*)stringByReplacingPattern:(NSString*)regexPattern withTemplate:(NSString*)replaceTemplate;
- (NSString*)stringByReplacingPattern:(NSString*)regexPattern withTemplate:(NSString*)replaceTemplate options:(NSRegularExpressionOptions)options;
- (NSString*)stringByRemovingPattern:(NSString*)regexPattern;
- (NSString*)stringByInjecting:(NSString*)string every:(NSUInteger)nth;
- (NSString*)stringByPrependingString:(NSString*)string;
- (BOOL)matchesPattern:(NSString*)regexPattern;
- (BOOL)startsWith:(NSString*)string;
- (NSInteger)countOccurancesOfSubstring:(NSString*)substring;
@end
