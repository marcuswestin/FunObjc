//
//  NSArray+Fun.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "NSArray+Fun.h"

@implementation NSArray (Fun)

+ (NSArray *)arrayWithLength:(NSUInteger)length values:(id)value {
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:length];
    for (int i=0; i<length; i++) {
        arr[i] = value;
    }
    return [arr copy];
}

- (NSMutableArray*) map:(MapIdToId)mapFn {
    NSMutableArray* results = [NSMutableArray arrayWithCapacity:self.count];
    [self each:^(id val, NSUInteger i) {
        results[i] = mapFn(val, i);
    }];
    return results;
}

- (NSMutableArray*) mapFilter:(MapIdToId)mapFn {
    NSMutableArray* results = [NSMutableArray arrayWithCapacity:self.count];
    [self each:^(id val, NSUInteger i) {
        id res = mapFn(val, i);
        if (res) {
            [results addObject:res];
        }
    }];
    return results;
}

- (NSInteger)sum:(MapIdToInt)mapper {
    NSInteger __block sum = 0;
    [self each:^(id val, NSUInteger i) {
        sum += mapper(val, i);
    }];
    return sum;
}

- (void) each:(Iterate)iterateFn {
    NSUInteger length = [self count];
    for (NSUInteger i=0; i<length; i++) {
        iterateFn(self[i], i);
    }
}

- (void)asyncEach:(Iterate)iterateFn {
    [self enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        iterateFn(obj, idx);
    }];
}

- (NSMutableArray *)filter:(Filter)filterFn {
    NSMutableArray* results = [NSMutableArray array];
    [self each:^(id val, NSUInteger i) {
        if (!filterFn(val, i)) { return; }
        [results addObject:val];
    }];
    return results;
}

- (id)pickOne:(Filter)pickFn {
    NSUInteger length = [self count];
    for (NSUInteger i=0; i<length; i++) {
        if (pickFn(self[i], i)) { return self[i]; }
    }
    return nil;
}

- (id)item:(NSInteger)index {
    if (index < 0 || index >= self.count) {
        return nil;
    }
    return self[index];
}

- (NSString*) joinBy:(NSString*)joiner {
    return [self componentsJoinedByString:joiner];
}

- (NSString *)joinBy:(NSString *)joiner last:(NSString *)lastJoiner {
    if (self.count <= 2) { return [self joinBy:lastJoiner]; }

    NSMutableArray* arr = [NSMutableArray arrayWithArray:self];
    id lastObj = arr.lastObject;
    [arr removeLastObject];
    return [NSString stringWithFormat:@"%@%@%@", [arr joinBy:joiner], lastJoiner, lastObj];
}

- (NSString *)joinedByComma {
    return [self joinBy:@","];
}

- (NSString *)joinedBySpace {
    return [self joinBy:@" "];
}

- (NSString *)joinedByCommaSpace {
    return [self joinBy:@", "];
}

- (NSString *)joinedByCommaNewline {
    return [self joinBy:@",\n"];
}

@end

@implementation NSOrderedSet (Fun)
- (id)item:(NSInteger)index {
    if (index < 0 || index >= self.count) {
        return nil;
    }
    return self[index];
}
@end