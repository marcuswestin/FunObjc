//
//  LinkedList.h
//  Dogo iOS
//
//  Created by Marcus Westin on 12/14/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LinkedList : NSObject
- (void)addObjectToHead:(id)obj;
- (id)removeObjectFromHead;
- (void)addObjectToTail:(id)obj;
- (id)removeObjectFromTail;
- (id)tail;
- (id)head;
- (id)pointer;
- (BOOL)hasContent;
- (void)enumerateWithBlock:(void(^)(id obj))block;
- (void)movePointerForward;
- (void)movePointerBackward;
- (id)peekNextPointer;
- (id)peekPrevPointer;
@end
