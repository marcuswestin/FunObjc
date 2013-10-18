//
//  DragAndDrop.h
//  Dogo iOS
//
//  Created by Marcus Westin on 10/17/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIView+Fun.h"
#import "UIControl+Fun.h"

@interface DragAndDrop : NSObject
@property UIView* view;
@property CGFloat startX;
@property CGFloat startY;
@property (copy) EventHandler tapHandler;
+ (instancetype)forView:(UIView*)view;
- (void)onTap:(TapHandler)tapHandler;
@end
