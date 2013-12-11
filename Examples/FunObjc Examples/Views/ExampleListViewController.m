//
//  ExampleListViewController.m
//  FunObjc Examples
//
//  Created by Marcus Westin on 12/10/13.
//  Copyright (c) 2013 Marcus Westin. All rights reserved.
//

#import "ExampleListViewController.h"

@implementation ExampleListViewController

- (void)render:(BOOL)animated {
    self.title = @"Infinite List View";
    self.view.backgroundColor = WHITE;
    [self renderFoot];
}

- (void)renderFoot {
    UIView* view = [UIView.appendTo(self.view).h(50).fromBottom(0).blur render];
    [UIButton.appendTo(view).text(@"Prepend 5").size.centerVertically.x(8) onTap:^(UIEvent *event) {
        [self prependToListCount:5];
    }];
}

- (ListIndex)listStartIndex {
    return 20;
}

- (UIView *)listViewForIndex:(ListIndex)index width:(CGFloat)width {
    UIView* view = [UIView.styler.wh(width, 50).bg([UIColor randomColor]) render];
    [UILabel.appendTo(view).name(@"label").text([NSString stringWithFormat:@"Index %d", index]).textColor(WHITE).size.centerVertically.x(8) render];
    return view;
}

- (void)listSelectIndex:(ListIndex)index view:(UIView *)view {
    [UIView animateWithDuration:0.35 animations:^{
        view.height *= 1.5;
        [[view viewByName:@"label"] centerVertically];
        [self setHeight:view.height forVisibleViewWithIndex:index];
    }];
}

@end
