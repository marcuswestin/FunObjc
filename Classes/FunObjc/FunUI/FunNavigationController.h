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
+ (instancetype)withRootViewController:(UIViewController*)rootViewController navigationBar:(BOOL)navigationBarVisible;
- (void)setup;
- (void)push:(UIViewController*)viewController withAnimator:(id<UIViewControllerAnimatedTransitioning>)animator;
@end
