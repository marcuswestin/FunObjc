//
//  UITextView+Fun.h
//  Diary-iOS
//
//  Created by Marcus Westin on 8/25/14.
//  Copyright (c) 2014 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (Fun)
- (UITextRange*)textRangeFromRange:(NSRange)range;
- (UITextRange*)selectedTextRangeByExtendingToWordBoundaries;
- (NSRange)selectedRangeByExtendingToWordBoundaries;
@end
