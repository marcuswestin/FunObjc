//
//  UIActionSheet+Fun.m
//  ivyq
//
//  Created by Marcus Westin on 12/28/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "UIActionSheet+Fun.h"

static UIActionSheetBlock _onCancel;
static UIActionSheetBlock _onDestroy;
static UIActionSheetButtonBlock _onButton;
static NSArray* _buttons;

@implementation UIActionSheet (Fun)

+ (void)showInView:(UIView *)view title:(NSString *)title buttons:(NSArray *)buttons onButton:(UIActionSheetButtonBlock)onButton {
    [self showInView:view title:title buttons:buttons onCancel:nil onButton:onButton];
}

+ (void)showInView:(UIView *)view title:(NSString *)title buttons:(NSArray *)buttons onCancel:(UIActionSheetBlock)onCancel onButton:(UIActionSheetButtonBlock)onButton {
    [self showInView:view title:title cancel:NSLocalizedString(@"Cancel", @"") destroy:nil buttons:buttons onCancel:onCancel onDestroy:nil onButton:onButton];
}

+ (void)showInView:(UIView *)view title:(NSString *)title cancel:(NSString *)cancel destroy:(NSString *)destroy buttons:(NSArray *)buttons onCancel:(UIActionSheetBlock)onCancel onDestroy:(UIActionSheetBlock)onDestroy onButton:(UIActionSheetButtonBlock)onButton {
    _onCancel = onCancel;
    _onDestroy = onDestroy;
    _onButton = onButton;
    
    UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:title delegate:(id)[self class] cancelButtonTitle:nil destructiveButtonTitle:destroy otherButtonTitles:nil];

    _buttons = buttons;
    for (NSString* button in buttons) {
        [sheet addButtonWithTitle:button];
    }
    
    if (cancel) {
        [sheet setCancelButtonIndex:[sheet addButtonWithTitle:cancel]];
    }
    
    [sheet showInView:view];
}

+ (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex && _onDestroy) {
        if (_onDestroy) {
            _onDestroy();
        }
    } else if (buttonIndex == actionSheet.cancelButtonIndex) {
        if (_onCancel) {
            _onCancel();
        }
    } else {
        _onButton(buttonIndex, _buttons[buttonIndex]);
    }
    [self remove];
}

+ (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    if (_onCancel) {
        _onCancel();
    }
    [self remove];
}

+ (void) remove {
    _onCancel = nil;
    _onDestroy = nil;
    _onButton = nil;
    _buttons = nil;
}

@end
