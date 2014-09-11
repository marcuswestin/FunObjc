//
//  UITextView+Fun.m
//  Diary-iOS
//
//  Created by Marcus Westin on 8/25/14.
//  Copyright (c) 2014 Flutterby Labs Inc. All rights reserved.
//

#import "UITextView+Fun.h"
#import "FunObjc.h"

@implementation UITextView (Fun)
- (NSRange)selectedRangeByExtendingToWordBoundaries {
    NSRange range = [self selectedRange];
    NSString* text = self.text;
    NSCharacterSet* whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    while (range.location > 0 && ![whitespace characterIsMember:[text characterAtIndex:range.location - 1]]) {
        range.location -= 1;
        range.length += 1;
    }
    while (range.location + range.length < text.length && ![whitespace characterIsMember:[text characterAtIndex:range.location + range.length]]) {
        range.length += 1;
    }
    return range;
}

- (UITextRange *)selectedTextRangeByExtendingToWordBoundaries {
    NSRange range = [self selectedRangeByExtendingToWordBoundaries];
    return [self textRangeFromRange:range];
}

- (UITextRange *)textRangeFromRange:(NSRange)range {
    UITextPosition* fromPos = [self positionFromPosition:self.beginningOfDocument offset:range.location];
    UITextPosition* toPos = [self positionFromPosition:self.beginningOfDocument offset:range.location + range.length];
    return [self textRangeFromPosition:fromPos toPosition:toPos];
}
@end
