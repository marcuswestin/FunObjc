//
//  UIScrollView+Fun.m
//  ivyq
//
//  Created by Marcus Westin on 10/14/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "UIScrollView+Fun.h"

@implementation UIScrollView (Fun)

- (void)addContentInset:(UIEdgeInsets)add {
    UIEdgeInsets insets = self.contentInset;
    insets.top += add.top;
    insets.bottom += add.bottom;
    insets.left += add.left;
    insets.right += add.right;
    self.contentInset = insets;
}

- (void)addContentInsetTop:(CGFloat)insetTop {
    [self addContentInset:UIEdgeInsetsMake(insetTop, 0, 0, 0)];
}

- (void)addContentInsetBottom:(CGFloat)insetBottom {
    [self addContentInset:UIEdgeInsetsMake(0, 0, insetBottom, 0)];
}

- (void)addContentHeight:(CGFloat)addHeight {
    CGSize contentSize = self.contentSize;
    contentSize.height += addHeight;
    self.contentSize = contentSize;
}
- (void)addContentWidth:(CGFloat)addWidth {
    CGSize contentSize = self.contentSize;
    contentSize.width += addWidth;
    self.contentSize = contentSize;
}
- (void)addContentSize:(CGSize)addSize {
    CGSize contentSize = self.contentSize;
    contentSize.width += addSize.width;
    contentSize.height += addSize.height;
    self.contentSize = contentSize;
}

- (void)addContentOffsetY:(CGFloat)addY {
    return [self addContentOffsetY:addY animated:NO];
}
- (void)addContentOffsetY:(CGFloat)addY animated:(BOOL)animated {
    CGPoint offset = self.contentOffset;
    offset.y += addY;
    [self setContentOffset:offset animated:animated];
}

- (void)addContentOffsetX:(CGFloat)addX {
    return [self addContentOffsetX:addX animated:NO];
}
- (void)addContentOffsetX:(CGFloat)addX animated:(BOOL)animated {
    CGPoint offset = self.contentOffset;
    offset.x += addX;
    [self setContentOffset:offset animated:animated];
}

- (void)setContentInsetBottom:(CGFloat)insetBottom {
    UIEdgeInsets insets = self.contentInset;
    insets.bottom = insetBottom;
    self.contentInset = insets;
}

@end
