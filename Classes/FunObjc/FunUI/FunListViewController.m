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

@interface FunListViewController ()
@property id subscriber;
@end

@implementation FunListViewController

- (void)_funViewControllerRender:(BOOL)animated {
    if (![self conformsToProtocol:@protocol(FunListViewDelegate)]) {
        [NSException raise:@"Error" format:@"Make sure that %@ conforms to the FunListViewDelegate protocol", [self className]];
    }
    CGSize size = self.view.size;
    _listView = [[FunListView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    [_listView appendTo:self.view];
    _shouldMoveWithKeyboard = YES;
    _listView.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [super _funViewControllerRender:animated];
    _listView.delegate = (id<FunListViewDelegate>)self;
    _subscriber = @1;
    [_listView.scrollView addContentInsetTop:[StatusBar height]];
    if (!self.navigationController.navigationBarHidden) {
        CGFloat height = self.navigationController.navigationBar.frame.size.height;
        [_listView.scrollView addContentInsetTop:height];
    }
    // TODO Check if there is a visible navigation bar on bottom
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Keyboard onWillChange:_subscriber callback:^(KeyboardEventInfo *info) {
        if (_shouldMoveWithKeyboard) {
            [info animate:^{
                [self moveListWithKeyboard:info.heightChange];
            }];
        } else {
            [_listView.scrollView addContentInsetBottom:info.heightChange]; // make room for keyboard
        }
    }];
}

- (void)moveListWithKeyboard:(CGFloat)heightChange {
    [_listView.scrollView addContentInsetTop:heightChange];
    for (UIView* view in _listView.subviews) {
        [view moveByY:-heightChange];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [Keyboard off:_subscriber];
}

@end

