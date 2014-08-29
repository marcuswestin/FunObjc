//
//  FunListViewController.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 8/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunListViewController.h"
#import "UIView+FunStyle.h"
#import "FunBase.h"
#import "UIColor+Fun.h"
#import "Keyboard.h"
#import "UIScrollView+Fun.h"
#import "UIView+FunStyle.h"
#import "UIView+Fun.h"
#import "NSArray+Fun.h"
#import "StatusBar.h"


@interface FunViewController ()
- (void)_funViewControllerRender:(BOOL)animated;
@end


@implementation FunListViewController

- (void)_funViewControllerRender:(BOOL)animated {
    if (![self conformsToProtocol:@protocol(FunListViewDelegate)]) {
        [NSException raise:@"Error" format:@"Make sure that %@ conforms to the FunListViewDelegate protocol", [self className]];
    }
    CGSize size = self.view.size;
    _listView = [[FunListView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    [_listView appendTo:self.view];
    [super _funViewControllerRender:animated];
    _listView.delegate = (id<FunListViewDelegate>)self;
    _listView.shouldMoveWithKeyboard = YES;
    _listView.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag; // UIScrollViewKeyboardDismissModeInteractive
    [_listView.scrollView addContentInsetTop:[StatusBar height]];
}

@end

