//
//  ExampleListViewController.m
//  FunObjc Examples
//
//  Created by Marcus Westin on 12/10/13.
//  Copyright (c) 2013 Marcus Westin. All rights reserved.
//

#import "ExampleListViewController.h"

@interface ExampleListViewController ()
@property NSUInteger groupBy;
@end

@implementation ExampleListViewController

- (void)render:(BOOL)animated {
    self.title = @"List Example";
    self.view.backgroundColor = WHITE;
    [self renderFoot];
}

- (void)renderFoot {
    UIView* view = [UIView.appendTo(self.view).h(50).fromBottom(0).blur render];
    [UIButton.appendTo(view).text(@"Prepend 5").size.centerVertically.x(8) onTap:^(UIEvent *event) {
        [self prependToListCount:5];
    }];
    self.groupBy = 10;
    [UIButton.appendTo(view).text(@"Group by: add 10").size.centerVertically.fromRight(8) onTap:^(UIEvent *event) {
        self.groupBy += 10;
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

- (id)listGroupIdForIndex:(ListIndex)index {
    return [NSNumber numberWithInt:index / self.groupBy];
}

- (UIView *)listViewForGroupHead:(NSNumber*)groupId withIndex:(ListIndex)index width:(CGFloat)width {
    UIView* view = [UIView.styler.wh(width, 30).bg(BLACK) render];
    NSNumber* nextGroupId = [self listGroupIdForIndex:index + self.groupBy];
    NSString* text = [NSString stringWithFormat:@"%d-%d", groupId.integerValue * self.groupBy, nextGroupId.integerValue * self.groupBy];
    [UILabel.appendTo(view).text(text).textColor(WHITE).size.center render];
    return view;
}

@end
