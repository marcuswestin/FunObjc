//
//  ViewController.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/26/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FunCategories.h"
#import "FunBase.h"
#import "State.h"
#import "FunNavigationController.h"

@interface FunViewController : UIViewController
+ (instancetype)withoutState;
+ (instancetype)withState:(State*) state;
+ (void)setDefaultBackgroundColor:(UIColor*)color;
- (instancetype)initWithState:(id<NSCoding>)state;
@property id<NSCoding> state;
- (void)render:(BOOL)animated;
- (void)cleanup;
- (void)pushViewController:(UIViewController *)viewController;
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popViewController;
- (void)popViewControllerAnimated:(BOOL)animated;
@end
