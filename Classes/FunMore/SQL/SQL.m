//
//  SQL.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunObjc.h"
#import "SQL.h"
#import "FMDatabaseAdditions.h"
#import "Files.h"

@interface TableInfo : NSObject
@property NSString* insertOrReplaceSql;
@property NSString* insertSql;
- (NSArray*)values:(NSDictionary*)item;
@end

@implementation TableInfo {
    NSArray* _columns;
    NSMutableArray* _values;
}
- (id)initWithTable:(NSString*)table db:(FMDatabase*)db {
    if (self = [super init]) {
        NSMutableArray* columns = [NSMutableArray array];
        FMResultSet* rs = [db getTableSchema:table];
        if (!rs) { return nil; }
        while ([rs next]) {
            [columns addObject:[rs stringForColumn:@"name"]];
        }
        [rs close];
        
        NSString* questionMarks = [@"?" append:[NSString repeat:@",?" times:columns.count-1]];
        NSString* columnNames = [columns map:^id(id name, NSUInteger i) { return name; }].joinedByCommaSpace;
        
        _columns = columns;
        _insertOrReplaceSql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@) VALUES (%@)", table, columnNames, questionMarks];
        _insertSql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", table, columnNames, questionMarks];
        _values = [NSMutableArray arrayWithCapacity:columns.count];
    }
    return self;
}

- (NSArray *)values:(NSDictionary *)item {
    if (!item || [item isNull]) { return nil; }
    [_values removeAllObjects];
    for (NSString* column in _columns) {
        [_values addObject:item[column] ? item[column] : NSNull.null];
    }
    return _values;
}
@end

@implementation SQLRes
@end

static NSMutableDictionary* columnsCache;

@implementation SQLMigrations {
    NSMutableArray* _completedMigrations;
    NSUInteger _migrationIndex;
    NSMutableArray* _newMigrations;
    NSString* _name;
}
- (id)initWithName:(NSString*)name {
    if (self = [super init]) {
        _name = name;
        NSDictionary* migrationInfo = [Files readDocumentJson:[self migrationDoc]];
        _migrationIndex = 0;
        _newMigrations = [NSMutableArray array];
        if (migrationInfo) {
            _completedMigrations = [NSMutableArray arrayWithArray:migrationInfo[@"completedMigrations"]];
        } else {
            _completedMigrations = [NSMutableArray array];
        }
    }
    return self;
}
- (NSString*)migrationDoc {
    return [_name append:@"-MigrationInfo"];
}
- (void)registerMigration:(NSString *)name withBlock:(MigrationBlock)block {
    if (_migrationIndex < _completedMigrations.count) {
        NSString* expectedMigraitonName = _completedMigrations[_migrationIndex];
        if (![name isEqualToString:expectedMigraitonName]) {
            NSLog(@"Error: Bad migration order");
            [NSException raise:@"BadMigration" format:@"Expected migration named %@ but found %@", expectedMigraitonName, name];
        }
    } else {
        [_newMigrations addObject:@{ @"name":name, @"block":block }];
    }
    _migrationIndex += 1;
}
- (void)_finish {
    [_newMigrations each:^(NSDictionary* migration, NSUInteger i) {
        NSLog(@"Running migration %@", migration[@"name"]);
        [SQL transact:^(SQLConn *conn, SQLRollbackBlock rollback) {
            MigrationBlock migrationBlock = migration[@"block"];
            NSError* err;
            @try {
                err = migrationBlock(conn);
            }
            @catch (NSException *exception) {
                err = makeError(exception.reason);
            }
            if (err) {
                NSLog(@"Error: %@", err);
                rollback();
                fatal(err);
            }
        }];
        NSLog(@"Completed migration %@", migration[@"name"]);
        [_completedMigrations addObject:migration[@"name"]];
    }];
    
    [Files writeDocumentJson:[self migrationDoc] object:@{@"completedMigrations": _completedMigrations}];
}
@end

@implementation SQL

static FMDatabaseQueue* queue;

+ (void) openDocument:(NSString*)name withMigrations:(SQLRegisterMigrations)migrationsFn {
    queue = [FMDatabaseQueue databaseQueueWithPath:[Files documentPath:name]];
    columnsCache = [NSMutableDictionary dictionary];
    SQLMigrations* migrations = [[SQLMigrations alloc] initWithName:name];
    migrationsFn(migrations);
    [migrations _finish];
}

+ (void)autocommit:(SQLAutocommitBlock)block {
    [queue inDatabase:^(FMDatabase *db) {
        SQLConn* conn = [[SQLConn alloc] init];
        conn.db = db;
        block(conn);
    }];
}

+ (void)transact:(SQLTransactionBlock)block {
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        SQLConn* conn = [[SQLConn alloc] init];
        conn.db = db;
        block(conn, ^{
            *rollback = YES;
        });
    }];
}

+ (SQLRes *)select:(NSString *)sql args:(NSArray *)args {
    __block SQLRes* result;
    [SQL autocommit:^(SQLConn *conn) {
        result = [conn select:sql args:args];
    }];
    return result;
}

+ (SQLRes *)selectOne:(NSString *)sql args:(NSArray *)args {
    __block SQLRes* result;
    [SQL autocommit:^(SQLConn *conn) {
        result = [conn selectOne:sql args:args];
    }];
    return result;
}

+ (NSString *)joinSelect:(NSDictionary *)tableColumns {
    NSMutableArray* selections = [NSMutableArray array];
    [tableColumns each:^(NSString* columnList, NSString* tableName) {
        [columnList.splitByComma each:^(NSString* columnName, NSUInteger i) {
            [selections addObject:[NSString stringWithFormat:@"%@.%@ AS %@", tableName, columnName, columnName]];
        }];
    }];
    return [@"SELECT " stringByAppendingString:selections.joinedByCommaSpace];
}

@end

static NSMutableDictionary* columns;

@implementation SQLConn

- (SQLRes*)select:(NSString *)sql args:(NSArray *)args {
    SQLRes* result = [[SQLRes alloc] init];

    FMResultSet* resultSet = [_db executeQuery:sql withArgumentsInArray:args];
    if (!resultSet) {
        result.error = _db.lastError;
        return result;
    }
    
    NSMutableArray* rows = [NSMutableArray array];
    while ([resultSet next]) {
        [rows addObject:[resultSet resultDictionary]];
    }
    
    result.rows = rows;
    if (rows.count == 1) {
        result.row = rows[0];
    }
    
    return result;
}

- (SQLRes*)selectOne:(NSString *)sql args:(NSArray *)args {
    SQLRes* result = [self select:sql args:args];
    
    if (result.error) { return result; }
    
    if (result.rows.count > 1) {
        result.error = makeError(@"Bad number of rows");
        return result;
    }
    
    return result;
}

- (NSError *)insert:(NSString *)sql args:(NSArray *)args {
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
    if (!success) { return _db.lastError; }
    return nil;
}

- (NSError *)insertMultiple:(NSString *)sql argsList:(NSArray *)argsList {
    for (NSArray* args in argsList) {
        BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
        if (!success) { return _db.lastError; }
    }
    return nil;
}

- (NSError*)insertOrReplaceMultipleInto:(NSString*)table items:(NSArray*)items {
    if (!items || [items isNull] || items.count == 0) { return nil; }
    TableInfo* tableInfo = [self tableInfo:table];
    for (NSDictionary* item in items) {
        BOOL success = [_db executeUpdate:tableInfo.insertOrReplaceSql withArgumentsInArray:[tableInfo values:item]];
        if (!success) { return _db.lastError; }
    }
    return nil;
}

- (NSError*)insertOrReplaceInto:(NSString*)table item:(NSDictionary*)item {
    TableInfo* tableInfo = [self tableInfo:table];
    return [self _insert:table item:item sql:tableInfo.insertOrReplaceSql values:[tableInfo values:item]];
}

-(NSError *)insertInto:(NSString *)table item:(NSDictionary *)item {
    TableInfo* tableInfo = [self tableInfo:table];
    return [self _insert:table item:item sql:tableInfo.insertSql values:[tableInfo values:item]];
}

- (NSError*)_insert:(NSString*)table item:(NSDictionary*)item sql:(NSString*)sql values:(NSArray*)values {
    if (!values) { return nil; }
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:values];
    if (!success) { return _db.lastError; }
    return nil;
}

- (NSError *)schema:(NSString *)sql {
    NSArray* statements = [sql split:@";"];
    if (!statements.count) {
        return makeError(@"Empty schema");
    }
    for (NSString* statement in statements) {
        if (statement.trim.isEmpty) { continue; }
        NSError* err = [self update:statement args:nil];
        if (err) { return err; }
    }
    return nil;
}

- (NSError *)update:(NSString *)sql args:(NSArray *)args {
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
    return (success ? nil : _db.lastError);
}

- (NSError *)updateOne:(NSString *)sql args:(NSArray *)args {
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
    if (!success) { return _db.lastError; }
    if (_db.changes > 1) { return makeError(@"updateOne affected multipe rows"); }
    return nil;
}

- (TableInfo*)tableInfo:(NSString*)table {
    if (columnsCache[table]) {
        return columnsCache[table];
    }
    return columnsCache[table] = [[TableInfo alloc] initWithTable:table db:_db];
}

@end