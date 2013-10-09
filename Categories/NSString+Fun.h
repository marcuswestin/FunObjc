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
- (NSArray*)splitByComma;
- (NSArray*)split:(NSString*)splitter;
- (NSData*)toData;
- (NSString*)stringByRemoving:(NSString*)needle;
- (NSString*)encodedURIComponent;
- (NSString*)stringByTrimmingWhitespace;
- (NSString*)trim;
- (BOOL)isEmpty;
- (BOOL)is:(NSString*)string;
- (NSString*)append:(NSString*)string;

@end
