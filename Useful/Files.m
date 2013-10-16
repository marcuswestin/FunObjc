//
//  FunFiles.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Files.h"
#import "FunObjc.h"
#import "NSObject+Fun.h"

@implementation Files

static NSString* _appDocumentsDirectory;
static NSString* _appCachesDirectory;
static NSString* _funDocumentsDirectory;
static NSString* _funCachesDirectory;
static NSString* _funPersistPath;

+ (void)initialize {
    _appDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    _appCachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    _funPersistPath = [_appDocumentsDirectory stringByAppendingPathComponent:@"FunFilesPathPersist"];
    
    NSString* funRootName = [NSString stringWithContentsOfFile:_funPersistPath encoding:NSUTF8StringEncoding error:nil];
    if (funRootName) {
        [self setFileRootTo:funRootName];
    } else {
        [self resetFileRoot];
    }
}
+ (void)resetFileRoot {
    NSString* funRootName = [NSString stringWithFormat:@"FunFileRoot-%@", [NSString UUID]];
    [funRootName writeToFile:_funPersistPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [self setFileRootTo:funRootName];
    [[NSFileManager defaultManager] createDirectoryAtPath:_funDocumentsDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:_funCachesDirectory withIntermediateDirectories:NO attributes:nil error:nil];
}
+ (void)setFileRootTo:(NSString*)funRootName {
    _funDocumentsDirectory = [_appDocumentsDirectory stringByAppendingPathComponent:funRootName];
    _funCachesDirectory = [_appCachesDirectory stringByAppendingPathComponent:funRootName];
}
+ (id)readJsonDocument:(NSString *)filename {
    return [JSON parseData:[Files readDocument:filename]];
}
+ (id)readJsonDocument:(NSString *)filename property:(NSString *)property {
    return [Files readJsonDocument:filename][property];
}
+ (void)writeJsonDocument:(NSString *)filename data:(id)data {
    [Files writeDocument:filename data:[JSON serialize:data]];
}
+ (void)writeJsonDocument:(NSString *)filename property:(NSString *)property data:(id)data {
    id readDoc = [Files readJsonDocument:filename];
    NSMutableDictionary* doc = [(readDoc ? readDoc : @{}) mutableCopy];
    doc[property] = data;
    [Files writeJsonDocument:filename data:doc];
}
+ (NSData*)readDocument:(NSString*)name {
    return [NSData dataWithContentsOfFile:[self documentPath:name]];
}
+ (NSData*)readCache:(NSString*)name {
    return [NSData dataWithContentsOfFile:[self cachePath:name]];
}
+ (BOOL)writeCache:(NSString*)name data:(NSData*)data {
    return [data writeToFile:[self cachePath:name] atomically:YES];
}
+ (BOOL)writeDocument:(NSString *)name data:(NSData *)data {
    return [data writeToFile:[self documentPath:name] atomically:YES];
}
+ (NSString*)cachePath:(NSString*)filename {
    return [_funCachesDirectory stringByAppendingPathComponent:filename];
}
+ (NSString*)documentPath:(NSString*)filename {
    return [_funDocumentsDirectory stringByAppendingPathComponent:filename];
}
+ (BOOL)removeCache:(NSString *)name {
    return [Files removeFile:[Files cachePath:name]];
}
+ (BOOL)removeDocument:(NSString *)name {
    return [Files removeFile:[Files documentPath:name]];
}
+ (BOOL)removeFile:(NSString*)path {
    return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}
+ (NSData *)readResource:(NSString *)name {
    return [Files readResource:name ofType:nil];
}
+ (NSData *)readResource:(NSString *)name ofType:(NSString *)type {
    NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:type];
    return [NSData dataWithContentsOfFile:path];
}
@end
