//
//  State.h
//  ivyq
//
//  Created by Marcus Westin on 9/22/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FunBase.h"

@protocol StateInflateDeflate <NSObject>
+ (NSDictionary*)inflateDeflateMap;
@end

@interface State : NSObject <NSCoding>
+ (void)observeValue:(NSString*)valueName subscriber:(id)subscriber callback:(void(^)(id value))callback;
+ (void)unobserveValue:(NSString*)valueName subscriber:(id)subscriber;
+ (void)updateValue:(NSString*)valueName newValue:(id)newValue;
+ (void)incrementValue:(NSString*)valueName;
+ (void)decrementValue:(NSString*)valueName;
+ (void)addToValue:(NSString*)valueName number:(NSInteger)num;
+ (id)getValue:(NSString*)valueName;

+ (instancetype) fromDict:(NSDictionary*)dict;
+ (instancetype) fromDeflatedDict:(NSDictionary*)deflatedDict;
+ (instancetype) fromDeflatedJson:(NSString*)json;
+ (instancetype) fromJson:(NSString*)json;
- (BOOL)archiveToDocument:(NSString*)archiveDocName;
- (NSDictionary*)toDictionary;
- (void)mergeDict:(NSDictionary*)dict;
+ (instancetype)fromArchiveDocument:(NSString*)archiveDocName;
- (instancetype) copyWithDictionary:(NSDictionary*)dict;
- (void)setDefaults;
- (NSDictionary*)deflatedDict;
@end

