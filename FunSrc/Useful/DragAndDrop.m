//
//  DragAndDrop.m
//  Dogo iOS
//
//  Created by Marcus Westin on 10/17/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "DragAndDrop.h"

@implementation DragAndDrop
+ (instancetype)forView:(UIView *)view {
    DragAndDrop* instance = [DragAndDrop new];
    instance.view = view;
    [view onPan:^(UIPanGestureRecognizer *pan) {
        CGPoint translation = [pan translationInView:instance.view];
        switch (pan.state) {
            case UIGestureRecognizerStateBegan:
                instance.startX = view.x;
                instance.startY = view.y;
                break;
            case UIGestureRecognizerStateChanged:
            case UIGestureRecognizerStateEnded:
                view.x = instance.startX + translation.x;
                view.y = instance.startY + translation.y;
                break;
            default:
                break;
        }
    }];
    return instance;
}

- (void)onTap:(TapHandler)tapHandler {
    [_view onTap:tapHandler];
}
@end
