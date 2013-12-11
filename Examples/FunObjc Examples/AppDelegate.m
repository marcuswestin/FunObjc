//
//  AppDelegate.m
//  FunObjc Examples
//
//  Created by Marcus Westin on 12/10/13.
//  Copyright (c) 2013 Marcus Westin. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeViewController.h"

@implementation AppDelegate

- (void)interfaceWillLoad {
    ENABLE_AUTO(@"View ListView Example")
}

- (void)interfaceDidLoad:(UIWindow *)window {

}

- (UIViewController *)rootViewControllerForFreshLoad {
    return [FunNavigationController withRootViewController:[HomeViewController new] navigationBar:YES];
}

- (void)styleLabels:(UILabelStyles *)labels buttons:(UIButtonStyles *)buttons textFields:(UITextFieldStyles *)textFields textViews:(UITextViewStyles *)textViews {
    buttons.textColor = STEELBLUE;
    labels.textColor = RED;
}

@end
