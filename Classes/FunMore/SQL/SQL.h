//
//  SQL.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunObjc.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@interface SQLRes : NSObject
@property NSError* error;
@property NSArray* rows;
@property NSDictionary* row;
@end

@interface SQLConn : NSObject
@property FMDatabase* db;
- (SQLRes*)select:(NSString *)sql args:(NSArray *)args;
- (SQLRes*)selectOne:(NSString *)sql args:(NSArray *)args;
- (NSError*)update:(NSString*)sql args:(NSArray*)args;
- (NSError*)updateOne:(NSString*)sql args:(NSArray*)args;
- (NSError*)insert:(NSString*)sql args:(NSArray*)args;
- (NSError*)insertInto:(NSString*)table item:(NSDictionary*)item;
- (NSError*)insertMultiple:(NSString*)sql argsList:(NSArray*)argsList;
- (NSError*)insertOrReplaceInto:(NSString*)table item:(NSDictionary*)item;
- (NSError*)insertOrReplaceMultipleInto:(NSString*)table items:(NSArray*)items;
- (NSError*)schema:(NSString*)sql;
@end

typedef NSError* (^MigrationBlock)(SQLConn* conn);
@interface SQLMigrations : NSObject
@property SQLConn* conn;
- (void) registerMigration:(NSString*)name withBlock:(MigrationBlock)migrationBlock;
@end

typedef void (^SQLRegisterMigrations)(SQLMigrations* migrations);
typedef void (^SQLSelectCallback)(id err, NSArray* rows);
typedef void (^SQLSelectOneCallback)(id err, id row);
typedef void (^SQLAutocommitBlock)(SQLConn *conn);
typedef void (^SQLRollbackBlock)();
typedef void (^SQLTransactionBlock)(SQLConn *conn, SQLRollbackBlock rollback);

@interface SQL : NSObject
+ (void)autocommit:(SQLAutocommitBlock)block;
+ (void)transact:(SQLTransactionBlock)block;
+ (SQLRes*)select:(NSString*)sql args:(NSArray*)args;
+ (SQLRes*)selectOne:(NSString*)sql args:(NSArray*)args;
+ (void)openDocument:(NSString*)name withMigrations:(SQLRegisterMigrations)migrationsFn;
+ (NSString*) joinSelect:(NSDictionary*)tableColumns;
@end

