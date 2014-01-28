//
//  UIActionSheet+Fun.h
//  ivyq
//
//  Created by Marcus Westin on 12/28/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^UIActionSheetBlock)();
typedef void (^UIActionSheetButtonBlock)(NSUInteger buttonIndex, NSString* buttonTitle);

@interface UIActionSheet (Fun)

+ (void)showInView:(UIView*)view title:(NSString*)title buttons:(NSArray*)buttons onButton:(UIActionSheetButtonBlock)onButton;

+ (void)showInView:(UIView*)view title:(NSString*)title buttons:(NSArray*)buttons onCancel:(UIActionSheetBlock)onCancel onButton:(UIActionSheetButtonBlock)onButton;

+ (void)showInView:(UIView*)view title:(NSString*)title cancel:(NSString*)cancel destroy:(NSString*)destroy buttons:(NSArray*)buttons onCancel:(UIActionSheetBlock)onCancel onDestroy:(UIActionSheetBlock)onDestroy onButton:(UIActionSheetButtonBlock)onButton;


@end
