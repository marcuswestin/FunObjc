//
//  NavigationController.h
//  Dogo iOS
//
//  Created by Marcus Westin on 11/11/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FunApp.h"

@class ViewController;
@class NavigationController;
@class NavigationAnimator;

static NavigationController* Nav;

@interface NavigationController : UINavigationController <UINavigationControllerDelegate>
- (void)renderHeadHeight:(CGFloat)height block:(void(^)(UIView* view))block;
- (void)renderLeftWidth:(CGFloat)width block:(void(^)(UIView* view))block;

@property UIView* head;
@property UIView* foot;
@property UIView* left;

- (void)push:(ViewController*)viewController withAnimator:(NavigationAnimator*(^)())block;
@end
