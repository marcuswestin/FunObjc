//
//  NSArray+Fun.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^MapIdToId)(id val, NSUInteger i);
typedef NSInteger (^MapIdToInt)(id val, NSUInteger i);
typedef void (^Iterate)(id val, NSUInteger i);
typedef BOOL (^Filter)(id val, NSUInteger i);

@interface NSArray (Fun)
+ (NSArray*)arrayWithLength:(NSUInteger)length values:(id)value;

- (void) each:(Iterate)iterateFn;
- (void) asyncEach:(Iterate)iterateFn;
- (NSMutableArray*) map:(MapIdToId)mapper;
- (NSMutableArray*) mapFilter:(MapIdToId)mapper;
- (NSInteger) sum:(MapIdToInt)mapper;
- (NSMutableArray*) filter:(Filter)filterFn;
- (id) pickOne:(Filter)pickFn;
- (id) item:(NSInteger)index;
- (id) reverseItem:(NSInteger)index;
- (BOOL) hasIndex:(NSInteger)index;
- (NSInteger) lastIndex;

- (NSString*)joinBy:(NSString*)joiner;
- (NSString*)joinBy:(NSString*)joiner last:(NSString*)lastJoiner;
- (NSString*)joinedBySpace;
- (NSString*)joinedByComma;
- (NSString*)joinedByCommaSpace;
- (NSString*)joinedByCommaNewline;

- (NSString*)toJson;
@end

@interface NSOrderedSet (Fun)
- (id) item:(NSInteger)index;
- (BOOL) hasIndex:(NSInteger)index;
@end
@interface NSMutableOrderedSet (Fun)
- (BOOL) toggleContainsObject:(id)object;
@end