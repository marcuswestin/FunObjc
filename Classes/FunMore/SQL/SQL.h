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

@interface SQLConn : NSObject
@property FMDatabase* db;
- (NSArray*)select:(NSString *)sql args:(NSArray *)args error:(NSError**)outError;
- (NSDictionary*)selectOne:(NSString *)sql args:(NSArray *)args error:(NSError**)outError;
- (void)execute:(NSString*)sql args:(NSArray*)args error:(NSError**)outError;
- (void)updateOne:(NSString*)sql args:(NSArray*)args error:(NSError**)outError;
- (void)insertInto:(NSString*)table item:(id)item error:(NSError**)outError;
- (void)insertMultiple:(NSString*)sql argsList:(NSArray*)argsList error:(NSError**)outError;
- (void)insertOrReplaceInto:(NSString*)table item:(id)item error:(NSError**)outError;
- (void)insertOrReplaceMultipleInto:(NSString*)table items:(NSArray*)items error:(NSError**)outError;
- (void)updateSchema:(NSString*)sql error:(NSError**)outError;
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
+ (NSArray*)select:(NSString*)sql args:(NSArray*)args error:(NSError**)outError;
+ (NSDictionary*)selectOne:(NSString*)sql args:(NSArray*)args error:(NSError**)outError;
+ (void)openDocument:(NSString*)name withMigrations:(SQLRegisterMigrations)migrationsFn;
+ (NSString*) joinSelect:(NSDictionary*)tableColumns;
@end

