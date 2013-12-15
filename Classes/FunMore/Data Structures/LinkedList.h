//
//  LinkedList.h
//  Dogo iOS
//
//  Created by Marcus Westin on 12/14/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LinkedList : NSObject
- (void)push:(id)obj;
- (id)pop;
- (void)unshift:(id)obj;
- (id)shift;
- (id)first;
- (id)last;
- (BOOL)isEmpty;
@end
