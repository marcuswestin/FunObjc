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
- (void)addContentHeight:(CGFloat)addHeight;
- (void)addContentOffset:(CGFloat)addY;
- (void)addContentOffset:(CGFloat)addY animated:(BOOL)animated;

@end
