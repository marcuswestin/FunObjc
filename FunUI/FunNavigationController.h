//
//  NavigationController.h
//  Dogo iOS
//
//  Created by Marcus Westin on 11/11/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;
@class FunNavigationController;
@class NavigationAnimator;

@interface FunNavigationController : UINavigationController <UINavigationControllerDelegate>

- (void)setup;
- (void)renderHeadHeight:(CGFloat)height block:(void(^)(UIView* view))block;
- (void)renderFootHeight:(CGFloat)height block:(void(^)(UIView* view))block;

@property UIView* head;
@property UIView* foot;
@property id<UIViewControllerAnimatedTransitioning>currentAnimator;

- (void)push:(UIViewController*)viewController withAnimator:(id<UIViewControllerAnimatedTransitioning>)animator;
@end
