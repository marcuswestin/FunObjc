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
- (void)renderTopBar:(void(^)(UIView* topBar))block;
@property UIView* head;
@property UIView* foot;

- (void)push:(ViewController*)viewController withAnimator:(NavigationAnimator*(^)())block;
@end
