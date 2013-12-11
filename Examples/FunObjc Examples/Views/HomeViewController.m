//
//  HomeViewController.m
//  FunObjc Examples
//
//  Created by Marcus Westin on 12/10/13.
//  Copyright (c) 2013 Marcus Westin. All rights reserved.
//

#import "HomeViewController.h"
#import "ExampleListViewController.h"

@implementation HomeViewController

- (void)render:(BOOL)animated {
    self.title = @"Home";
    self.view.backgroundColor = WHITE;
    [UIButton.appendTo(self.view).text(@"ListView Example").size.center onTap:^(UIEvent *event) {
        [self viewListViewExample];
    }];
    
    AUTO(@"View ListView Example", [self viewListViewExample]);
}

- (void)viewListViewExample {
    [self pushViewController:[ExampleListViewController new]];
}

@end
