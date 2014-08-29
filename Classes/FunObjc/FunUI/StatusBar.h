//
//  StatusBar.h
//  Diary-iOS
//
//  Created by Marcus Westin on 8/3/14.
//  Copyright (c) 2014 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Events.h"

@interface StatusBar : NSObject

+ (void)onTap:(EventSubscriber)subscriber callback:(EventCallback)callback;
+ (void)offTap:(EventSubscriber)subscriber;
+ (void)hideWithAnimation:(UIStatusBarAnimation)statusBarAnimationStyle;
+ (void)showWithAnimation:(UIStatusBarAnimation)statusBarAnimationStyle;
+ (void)setHidden:(BOOL)hidden animation:(UIStatusBarAnimation)statusBarAnimation;
+ (void)setBackgroundColor:(UIColor*)backgroundColor;
+ (BOOL)isHidden;
+ (void)setContentHidden:(BOOL)hidden animation:(UIStatusBarAnimation)animationStyle;
+ (UIView*)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates;
+ (CGRect)bounds;
+ (UIColor*)backgroundColor;
+ (void)setHeight:(CGFloat)height;
+ (CGFloat)height;
+ (CGRect)frame;
+ (CGSize)size;
+ (UIView*)backgroundView;
+ (void)setBackgroundGradientFrom:(UIColor*)color to:(UIColor*)color2;

@end

