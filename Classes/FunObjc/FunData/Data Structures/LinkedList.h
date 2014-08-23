//
//  LinkedList.h
//  Dogo iOS
//
//  Created by Marcus Westin on 12/14/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSArray+Fun.h"

@interface LinkedList : NSObject <NSFastEnumeration>
- (void)addObjectToHead:(id)obj;
- (id)removeHead;
- (void)addObjectToTail:(id)obj;
- (id)removeTail;
- (id)tail;
- (id)head;
- (id)pointer;
- (BOOL)hasContent;
- (void)enumerateWithBlock:(void(^)(id obj))block;
- (void)movePointerForward;
- (void)movePointerBackward;
- (id)peekNextPointer;
- (id)peekPrevPointer;

- (void)each:(Iterate)iterateFn;
- (id)pickOne:(Filter)pickFn;
@end

