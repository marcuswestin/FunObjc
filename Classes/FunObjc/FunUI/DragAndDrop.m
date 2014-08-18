//
//  DragAndDrop.m
//  Dogo iOS
//
//  Created by Marcus Westin on 10/17/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "DragAndDrop.h"

@interface DragAndDrop ()
@property UIView* view;
@property CGFloat startX;
@property CGFloat startY;
@property NSString* document;
@end

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
                view.x = instance.startX + translation.x;
                view.y = instance.startY + translation.y;
                break;
            case UIGestureRecognizerStateEnded:
                view.x = instance.startX + translation.x;
                view.y = instance.startY + translation.y;
                if (instance.document) {
                    [Files writeString:NSStringFromCGPoint(view.frame.origin) name:instance.document];
                }
                break;
            default:
                break;
        }
    }];
    return instance;
}

- (void)onTap:(id)target selector:(SEL)selector {
    [_view onTap:target selector:selector];
}

- (void)persistPositionToDocument:(NSString *)document {
    _document = document;
    NSString* str = [Files readString:document];
    if (str) {
        [_view moveToPosition:CGPointFromString(str)];
    }
}
@end
