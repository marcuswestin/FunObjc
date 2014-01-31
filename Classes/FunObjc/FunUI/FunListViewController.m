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



@interface FunViewController ()
- (void)_funViewControllerRender:(BOOL)animated;
@end


@implementation FunListViewController

- (void)_funViewControllerRender:(BOOL)animated {
    if (![self conformsToProtocol:@protocol(FunListViewDelegate)]) {
        [NSException raise:@"Error" format:@"Make sure that %@ conforms to the FunListViewDelegate protocol", [self className]];
    }
    [self render:animated];
    _listView = [[FunListView alloc] initWithFrame:self.view.bounds];
    _listView.delegate = (id<FunListViewDelegate>)self;
    [_listView prependTo:self.view];
    [super _funViewControllerRender:animated];
}

@end

