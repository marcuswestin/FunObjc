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

static BOOL didReset = NO;

+ (NSArray *)documentURLs {
    NSError* err;
    NSArray* urls = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_funDocumentsDirectory error:&err];
    if (err) { fatal(err); }
    return urls;
}

+ (NSArray *)cacheURLs {
    NSError* err;
    NSArray* urls = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_funCachesDirectory error:&err];
    if (err) { fatal(err); }
    return urls;
}

+ (void)setup {
    _appDocumentsDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    _appCachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    _funPersistPath = [NSString stringWithFormat:@"%@/%@", _appDocumentsDirectory, @"FunFilesPathPersist"];
    
    NSString* funRootName = [NSString stringWithContentsOfFile:_funPersistPath encoding:NSUTF8StringEncoding error:nil];
    if (funRootName) {
        [self setFileRootTo:funRootName];
    } else {
        [self resetFileRoot];
    }
}

+ (BOOL)didReset {
    return didReset;
}

+ (void)resetFileRoot {
    NSError* __block err;
    NSFileManager* fileMgr = [NSFileManager defaultManager];

    NSArray* removeDirs = (_funDocumentsDirectory ? @[_funDocumentsDirectory, _funCachesDirectory] : @[]);
    NSString* funRootName = [NSString stringWithFormat:@"FunFileRoot-%@", [NSString UUID]];
    [self setFileRootTo:funRootName];
    
    [fileMgr createDirectoryAtPath:_funDocumentsDirectory withIntermediateDirectories:NO attributes:nil error:&err];
    if (err) { return error(err); }
    
    [fileMgr createDirectoryAtPath:_funCachesDirectory withIntermediateDirectories:NO attributes:nil error:&err];
    if (err) { return error(err); }
    
    async(^{
        // If resetFileRoot is called from appWillFinishLaunchingWithOptions,
        // it gets called again when the app is terminated. Don't ask me why.
        // Observed in iOS7 Feb 3, 2014.
        // While the app goes ahead and uses the new state directory right away,
        // we make the cleanup of previous state and comitting to new state async.
        // This prevents the app from resetting state *again* on shutdown.
        [funRootName writeToFile:_funPersistPath atomically:YES encoding:NSUTF8StringEncoding error:&err];
        if (err) { return error(err); }
        
        [removeDirs each:^(NSString* dir, NSUInteger i) {
            [fileMgr removeItemAtPath:dir error:&err];
            if (err) { return error(err); }
        }];
    });
}
+ (void)setFileRootTo:(NSString*)funRootName {
    _funDocumentsDirectory = [NSString stringWithFormat:@"%@/%@", _appDocumentsDirectory, funRootName];
    _funCachesDirectory = [NSString stringWithFormat:@"%@/%@", _appCachesDirectory, funRootName];
}

+ (NSDictionary*)readDocumentJson:(NSString *)filename {
    return [JSON parseData:[Files readDocument:filename]];
}
+ (id)readDocumentJson:(NSString *)filename property:(NSString *)property {
    return [Files readDocumentJson:filename][property];
}
+ (BOOL)writeDocumentJson:(NSString *)filename object:(NSDictionary *)object {
    return [Files writeDocument:filename data:[JSON serialize:object]];
}
+ (BOOL)writeDocumentJson:(NSString *)filename property:(NSString *)property data:(id)data {
    id readObj = [Files readDocumentJson:filename];
    NSMutableDictionary* obj = [(readObj ? readObj : @{}) mutableCopy];
    obj[property] = data;
    return [Files writeDocumentJson:filename object:obj];
}

+ (id)readCacheJson:(NSString *)filename {
    return [JSON parseData:[Files readCache:filename]];
}
+ (NSDictionary*)readCacheJson:(NSString *)filename property:(NSString *)property {
    return [Files readCacheJson:filename][property];
}
+ (void)writeCacheJson:(NSString *)filename object:(NSDictionary*)object {
    [Files writeCache:filename data:[JSON serialize:object]];
}
+ (void)writeCacheJson:(NSString *)filename property:(NSString *)property data:(id)data {
    NSDictionary* readObj = [Files readCacheJson:filename];
    NSMutableDictionary* obj = [(readObj ? readObj : @{}) mutableCopy];
    obj[property] = data;
    [Files writeCacheJson:filename object:obj];
}

+ (NSData*)readDocument:(NSString*)name {
    return [NSData dataWithContentsOfFile:[self documentPath:name]];
}
+ (NSData*)readCache:(NSString*)name {
    return [NSData dataWithContentsOfFile:[self cachePath:name]];
}
+ (BOOL)writeCache:(NSString*)name data:(NSData*)data {
    return [self _write:[self cachePath:name] data:data];
}
+ (BOOL)writeDocument:(NSString *)name data:(NSData *)data {
    return [self _write:[self documentPath:name] data:data];
}
+ (BOOL)_write:(NSString*)path data:(NSData*)data {
    NSError* err;
    if (![data writeToFile:path options:NSDataWritingAtomic error:&err]) {
        NSLog(@"Error writing file: %@", err);
        return NO;
    }
    return YES;
}
+ (NSString*)cachePath:(NSString*)filename {
    return [_funCachesDirectory stringByAppendingPathComponent:filename];
}
+ (NSString*)documentPath:(NSString*)filename {
    return [_funDocumentsDirectory stringByAppendingPathComponent:filename];
}
static NSCharacterSet* illegalFileNameCharacters;
+ (void)load {
    illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:"];
}
+ (NSString*)sanitizeName:(NSString*)filename {
    return [[filename componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
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

+ (void)writeNumber:(NSNumber *)number name:(NSString *)name {
    if (!number) {
        [Files removeDocument:name];
        return;
    }
    [Files writeDocumentJson:name object:@{ @"Number":number }];
}
+ (NSNumber *)readNumber:(NSString *)name {
    NSDictionary* dict = [Files readDocumentJson:name];
    return (dict ? dict[@"Number"] : nil);
}
+ (void)writeStringDocument:(NSString *)string name:(NSString *)name {
    [Files writeDocument:name data:string.toData];
}
+ (NSString *)readStringDocument:(NSString *)name {
    return [Files readDocument:name].toString;
}

+ (unsigned long long)sizeOfDocument:(NSString *)filename {
    return [self sizeOfFileAtPath:[self documentPath:filename]];
}
+ (unsigned long long)sizeOfCache:(NSString *)filename {
    return [self sizeOfFileAtPath:[self cachePath:filename]];
}
+ (unsigned long long)sizeOfFileAtPath:(NSString *)path {
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil][NSFileSize] unsignedLongLongValue];
}
@end
