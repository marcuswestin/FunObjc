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
+ (instancetype)forView:(UIView*)view;
- (void)onTap:(id)target selector:(SEL)selector;
- (void)persistPositionToDocument:(NSString*)documentName;
@end
