//
//  UITextField+Fun.h
//  Dogo iOS
//
//  Created by Marcus Westin on 12/10/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL (^ShouldChangeStringCallback)(NSString* fromString, NSString* toString, NSRange replacementRange, NSString* replacementString);

@interface UITextField (Fun)
- (void)bindTextTo:(NSMutableString*)str;
- (void)excludeInputsMatching:(NSString*)pattern;
- (void)limitLengthTo:(NSUInteger)maxLength;
- (void)shouldChange:(ShouldChangeStringCallback)shouldChangeStringCallback;
- (void)setSelectedRange:(NSRange)range;
@end
