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
    unsigned long _mutations;
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
    _mutations += 1;
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
    _mutations += 1;
    Link* newTail = [Link withObject:obj];
    if (![self hasContent]) {
        _head = _tail = _pointer = newTail;
    } else {
        newTail.next = _tail;
        _tail.prev = newTail;
        _tail = newTail;
    }
}
- (id)removeHead {
    _mutations += 1;
    if (_pointer == _head) {
        _pointer = _head.prev;
    }
    id object = _head.object;
    _head = _head.prev;
    return object;
}
- (id)removeTail {
    _mutations += 1;
    if (_pointer == _tail) {
        _pointer = _tail.next;
    }
    id object = _tail.object;
    _tail = _tail.next;
    return object;
}
- (void)movePointerBackward {
    _mutations += 1;
    if (_pointer == _tail) { return; }
    _pointer = _pointer.prev;
}
- (void)movePointerForward {
    _mutations += 1;
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
- (void)each:(Iterate)iterateFn {
    Link* link = _tail;
    NSInteger index = 0;
    while (link) {
        iterateFn(link.object, index);
        index += 1;
    }
}
- (id)pickOne:(Filter)pickFn {
    Link* link = _tail;
    NSInteger index = 0;
    while (link) {
        if (pickFn(link.object, index)) {
            return link.object;
        }
        index += 1;
    }
    return nil;
}

#pragma mark NSFastEnumeration for/in
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    if (state->state == 0) {
        // Initial setup
        state->mutationsPtr = &_mutations;
        state->state = 1;
        state->extra[1] = (long)_tail; // This is the position in the list
    }
    
    NSUInteger count = 0;
    state->itemsPtr = buffer;
    Link* link; void* _link = (void*)state->extra[1]; link = (__bridge Link*)_link; // casts to avoid ARC retain operations
    
    while (link) {
        buffer[count] = link.object;
        count += 1;
        if(count < len) {
            // continue if there's still room
            link = link.next;
        } else {
            // break if we run out of room in the buffer
            break;
        }
    }
    
    // link may be nil at this point, but ObjC returns nil on messages sent to nil
    // save the next start node which is nil if the list is exhausted
    state->extra[1] = (long)link.next;
    
    return count;
}
@end
