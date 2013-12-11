//
//  UILabel+Fun.m
//  Dogo iOS
//
//  Created by Marcus Westin on 12/10/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "UILabel+Fun.h"

@implementation UILabel (Fun)
- (void)wrapText {
    self.numberOfLines = 0;
    self.lineBreakMode = NSLineBreakByWordWrapping;
    [self sizeToFit];
}
@end