//
//  FunFiles.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FunGlobals.h"

@interface Files : NSObject

+ (NSDictionary*)readDocumentJson:(NSString*)filename;
+ (id)readDocumentJson:(NSString*)filename property:(NSString*)property;
+ (BOOL)writeDocumentJson:(NSString*)filename object:(NSDictionary*)object;
+ (BOOL)writeDocumentJson:(NSString*)filename property:(NSString*)property data:(id)data;
+ (id)readCacheJson:(NSString*)filename;
+ (id)readCacheJson:(NSString*)filename property:(NSString*)property;
+ (void)writeCacheJson:(NSString*)filename object:(NSDictionary*)object;
+ (void)writeCacheJson:(NSString*)filename property:(NSString*)property data:(id)data;

+ (NSData*)readDocument:(NSString*)filename;
+ (NSData*)readCache:(NSString*)filename;
+ (BOOL)writeDocument:(NSString*)filename data:(NSData*)data;
+ (BOOL)writeCache:(NSString*)filename data:(NSData*)data;
+ (NSString*)cachePath:(NSString*)filename;
+ (NSString*)documentPath:(NSString*)filename;
+ (NSString*)sanitizeName:(NSString*)filename;
+ (BOOL)removeDocument:(NSString*)name;
+ (BOOL)removeCache:(NSString*)name;

+ (NSData*)readResource:(NSString*)name;
+ (NSData*)readResource:(NSString*)resourceName ofType:(NSString*)type;

+ (void)resetFileRoot;
+ (BOOL)didReset;

+ (void)writeNumber:(NSNumber*)number name:(NSString*)name;
+ (NSNumber*)readNumber:(NSString*)name;

+ (void)writeString:(NSString*)string name:(NSString*)name;
+ (NSString*)readString:(NSString*)name;

+ (unsigned long long)sizeOfDocument:(NSString*)filename;
+ (unsigned long long)sizeOfCache:(NSString*)filename;

+ (NSArray*)documentURLs;
+ (NSArray*)cacheURLs;
@end
