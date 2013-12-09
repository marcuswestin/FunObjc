//
//  ViewController.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/26/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "State.h"

@interface FunViewController : UIViewController
+ (instancetype)withoutState;
+ (instancetype)withState:(State*) state;
+ (void)setDefaultBackgroundColor:(UIColor*)color;
- (instancetype)initWithState:(id<NSCoding>)state;
@property id<NSCoding> state;
- (void)render:(BOOL)animated;

- (void)pushViewController:(UIViewController *)viewController;
@end
