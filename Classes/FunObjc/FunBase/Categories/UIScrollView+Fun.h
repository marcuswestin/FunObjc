//
//  UIScrollView+Fun.h
//  ivyq
//
//  Created by Marcus Westin on 10/14/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (Fun)

- (void)addContentInset:(UIEdgeInsets)insets;
- (void)addContentInsetTop:(CGFloat)insetTop;
- (void)addContentInsetBottom:(CGFloat)insetBottom;
- (void)setContentInsetBottom:(CGFloat)insetBottom;
- (void)addContentHeight:(CGFloat)addHeight;
- (void)addContentWidth:(CGFloat)addWidth;
- (void)addContentSize:(CGSize)addSize;
- (void)addContentOffsetY:(CGFloat)addY;
- (void)addContentOffsetY:(CGFloat)addY animated:(BOOL)animated;
- (void)addContentOffsetX:(CGFloat)addX;
- (void)addContentOffsetX:(CGFloat)addX animated:(BOOL)animated;

@end
