//
//  LinkedList.m
//  Dogo iOS
//
//  Created by Marcus Westin on 12/14/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "LinkedList.h"

@interface Link : NSObject
@property Link* prev;
@property Link* next;
@property id object;
+ (instancetype)withObject:(id)object;
@end

@implementation Link
+ (instancetype)withObject:(id)object {
    Link* link = [[[self class] alloc] init];
    link.object = object;
    return link;
}
@end

@implementation LinkedList {
    Link* _head;
    Link* _pointer;
    Link* _tail;
}
- (id)head {
    return _head.object;
}
- (id)tail {
    return _tail.object;
}
- (id)pointer {
    return _pointer.object;
}
- (BOOL)hasContent {
    return !!_head;
}
- (void)addObjectToHead:(id)obj {
    Link* newHead = [Link withObject:obj];
    if (![self hasContent]) {
        _head = _tail = _pointer = newHead;
    } else {
        newHead.prev = _head;
        _head.next = newHead;
        _head = newHead;
    }
}
- (void)addObjectToTail:(id)obj {
    Link* newTail = [Link withObject:obj];
    if (![self hasContent]) {
        _head = _tail = _pointer = newTail;
    } else {
        newTail.next = _tail;
        _tail.prev = newTail;
        _tail = newTail;
    }
}
- (id)removeObjectFromHead {
    if (_pointer == _head) {
        _pointer = _head.prev;
    }
    id object = _head.object;
    _head = _head.prev;
    return object;
}
- (id)removeObjectFromTail {
    if (_pointer == _tail) {
        _pointer = _tail.next;
    }
    id object = _tail.object;
    _tail = _tail.next;
    return object;
}
- (void)movePointerBackward {
    if (_pointer == _tail) { return; }
    _pointer = _pointer.prev;
}
- (void)movePointerForward {
    if (_pointer == _head) { return; }
    _pointer = _pointer.next;
}
- (id)peekPrevPointer {
    return _pointer.prev.object;
}
- (id)peekNextPointer {
    return _pointer.next.object;
}
- (void)enumerateWithBlock:(void (^)(id))block {
    Link* link = _tail;
    while (link) {
        block(link.object);
        link = link.next;
    }
}
@end
