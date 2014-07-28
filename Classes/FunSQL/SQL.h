//
//  SQL.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@interface SQLConn : NSObject
@property FMDatabase* db;
- (NSArray*)select:(NSString *)sql args:(NSArray *)args error:(NSError**)outError;
- (NSDictionary*)selectOne:(NSString *)sql args:(NSArray *)args error:(NSError**)outError;
- (NSDictionary*)selectMaybe:(NSString*)sql args:(NSArray*)args error:(NSError**)outError;
- (void)execute:(NSString*)sql args:(NSArray*)args error:(NSError**)outError;
- (void)updateOne:(NSString*)sql args:(NSArray*)args error:(NSError**)outError;
- (void)insertInto:(NSString*)table item:(id)item error:(NSError**)outError;
- (void)insertMultiple:(NSString*)sql argsList:(NSArray*)argsList error:(NSError**)outError;
- (void)insertOrReplaceInto:(NSString*)table item:(id)item error:(NSError**)outError;
- (void)insertOrReplaceMultipleInto:(NSString*)table items:(NSArray*)items error:(NSError**)outError;
- (void)updateSchema:(NSString*)sql error:(NSError**)outError;
- (BOOL)table:(NSString*)table hasColumn:(NSString*)column;
- (BOOL)tableExists:(NSString*)table;
@end

typedef void (^MigrationBlock)(SQLConn* conn, NSError** outError);
@interface SQLMigrations : NSObject
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
+ (NSDictionary*)selectMaybe:(NSString*)sql args:(NSArray*)args error:(NSError**)outError;
+ (void)openDatabase:(NSString*)name withMigrations:(SQLRegisterMigrations)migrationsFn;
+ (void)removeDatabase:(NSString*)name;
+ (void)copyDatabase:(NSString*)fromName to:(NSString*)toName;
+ (void)backupDatabase:(NSString*)name;
+ (NSString*) joinSelect:(NSDictionary*)tableColumns;
@end

