//
//  SQL.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunCategories.h"
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

- (NSArray *)values:(id)item {
    if (!item || [item isNull]) { return nil; }
    [_values removeAllObjects];
    BOOL useObjectForKey = ([item isKindOfClass:[NSDictionary class]]);
    for (NSString* column in _columns) {
        id obj = (useObjectForKey ? [item objectForKey:column] : [item valueForKey:column]);
        if (!obj) { obj = NSNull.null; }
        [_values addObject:obj];
    }
    return _values;
}
@end

static NSMutableDictionary* columnsCache;

@implementation SQLMigrations {
    NSMutableArray* _completedMigrations;
    NSUInteger _migrationIndex;
    NSMutableArray* _newMigrations;
    NSString* _name;
    SQLConn* _conn;
}
- (id)initWithName:(NSString*)name {
    if (self = [super init]) {
        _name = name;
        NSDictionary* migrationInfo = [Files readDocumentJson:[SQLMigrations migrationDoc:name]];
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
+ (NSString*)migrationDoc:(NSString*)name {
    return [name append:@"-MigrationInfo"];
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
                migrationBlock(conn, &err);
            }
            @catch (NSException *exception) {
                err = makeError(exception.reason);
            }
            if (err) {
                NSLog(@"FAILED migration: %@", err);
                rollback();
                fatal(err);
            } else {
                NSLog(@"Completed migration %@", migration[@"name"]);
                [_completedMigrations addObject:migration[@"name"]];
            }
        }];
    }];
    
    [Files writeDocumentJson:[SQLMigrations migrationDoc:_name] object:@{@"completedMigrations": _completedMigrations}];
}
@end

@implementation SQL

static FMDatabaseQueue* queue;

+ (void)removeDatabase:(NSString *)name {
    [Files removeDocument:name];
    [Files removeDocument:[SQLMigrations migrationDoc:name]];
}

+ (void)copyDatabase:(NSString *)fromName to:(NSString *)toName {
    NSData* dbData = [Files readDocument:fromName];
    NSData* migrationData = [Files readDocument:[SQLMigrations migrationDoc:fromName]];
    [Files writeDocument:toName data:dbData];
    [Files writeDocument:[SQLMigrations migrationDoc:toName] data:migrationData];
}

+ (void) openDatabase:(NSString*)name withMigrations:(SQLRegisterMigrations)migrationsFn {
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

+ (NSArray *)select:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    __block NSArray* result;
    [SQL autocommit:^(SQLConn *conn) {
        result = [conn select:sql args:args error:outError];
    }];
    return result;
}

+ (NSDictionary *)selectMaybe:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    __block NSDictionary* result;
    [SQL autocommit:^(SQLConn *conn) {
        result = [conn selectMaybe:sql args:args error:outError];
    }];
    return result;
}

+ (NSDictionary *)selectOne:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    __block NSDictionary* result;
    [SQL autocommit:^(SQLConn *conn) {
        result = [conn selectOne:sql args:args error:outError];
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

- (NSArray *)select:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    FMResultSet* resultSet = [_db executeQuery:sql withArgumentsInArray:args ];
    if (!resultSet) {
        *outError = _db.lastError;
        return nil;
    }
    
    NSMutableArray* rows = [NSMutableArray array];
    while ([resultSet next]) {
        [rows addObject:[resultSet resultDictionary]];
    }
    
    return rows;
}

- (NSDictionary *)selectOne:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    NSDictionary* row = [self selectMaybe:sql args:args error:outError];
    if (*outError) {
        return nil;
    }
    
    if (!row) {
        *outError = makeError([NSString stringWithFormat:@"SelectOne returned no rows.\nQuery: %@", sql]);
        return nil;
    }
    
    return row;
}

- (NSDictionary *)selectMaybe:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    NSArray* rows = [self select:sql args:args error:outError];
    
    if (*outError) {
        return nil;
    }
    
    if (rows.count > 1) {
        *outError = makeError([NSString stringWithFormat:@"SelectOne/SelectMaybe got more than 1 rows.\nQuery: %@", sql]);
        return nil;
    }
    
    return rows.firstObject;
}

- (void)insertMultiple:(NSString *)sql argsList:(NSArray *)argsList error:(NSError *__autoreleasing *)outError {
    for (NSArray* args in argsList) {
        BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
        if (!success) {
            *outError = _db.lastError;
            return;
        }
    }
}

- (void)insertOrReplaceMultipleInto:(NSString *)table items:(NSArray *)items error:(NSError *__autoreleasing *)outError {
    if (!items || [items isNull] || items.count == 0) {
        return;
    }
    TableInfo* tableInfo = [self tableInfo:table];
    for (id item in items) {
        BOOL success = [_db executeUpdate:tableInfo.insertOrReplaceSql withArgumentsInArray:[tableInfo values:item]];
        if (!success) {
            *outError = _db.lastError;
            return;
        }
    }
}

- (void)insertOrReplaceInto:(NSString *)table item:(id)item error:(NSError *__autoreleasing *)outError {
    TableInfo* tableInfo = [self tableInfo:table];
    [self _insert:table item:item sql:tableInfo.insertOrReplaceSql values:[tableInfo values:item] error:outError];
}

-(void)insertInto:(NSString *)table item:(id)item error:(NSError *__autoreleasing *)outError {
    TableInfo* tableInfo = [self tableInfo:table];
    [self _insert:table item:item sql:tableInfo.insertSql values:[tableInfo values:item] error:outError];
}

- (void)_insert:(NSString*)table item:(NSDictionary*)item sql:(NSString*)sql values:(NSArray*)values error:(NSError *__autoreleasing *)outError {
    if (!values) {
        return;
    }
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:values];
    if (!success) {
        *outError = _db.lastError;
        return;
    }
}

- (void)updateSchema:(NSString *)sql error:(NSError *__autoreleasing *)outError {
    NSArray* statements = [sql split:@";"];
    if (!statements.count) {
        *outError = makeError(@"Empty schema");
        return;
    }
    for (NSString* statement in statements) {
        if (!statement.trim.hasContent) { continue; }
        [self execute:statement args:nil error:outError];
        if (*outError) {
            return;
        }
    }
}

- (void)execute:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
    if (!success) {
        *outError = _db.lastError;
        return;
    }
}

- (void)updateOne:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
    if (!success) {
        *outError = _db.lastError;
        return;
    }
    if (_db.changes > 1) {
        *outError = makeError(@"updateOne affected multipe rows");
        return;
    }
}

- (TableInfo*)tableInfo:(NSString*)table {
    if (columnsCache[table]) {
        return columnsCache[table];
    }
    return columnsCache[table] = [[TableInfo alloc] initWithTable:table db:_db];
}

@end