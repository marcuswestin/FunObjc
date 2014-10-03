//
//  SQL.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunBase.h"
#import "FunCategories.h"
#import "SQL.h"
#import "FMDatabaseAdditions.h"
#import "Files.h"
#import "StatusBar.h"

@interface TableInfo : NSObject
@property NSString* insertOrReplaceSql;
@property NSString* insertSql;
@property NSArray* columns;
- (NSArray*)values:(NSDictionary*)item;
@end

@implementation TableInfo {
    NSMutableArray* _values;
}
- (id)initWithTable:(NSString*)table db:(FMDatabase*)db {
    if (self = [super init]) {
        NSMutableArray* columns = [NSMutableArray array];
        FMResultSet* rs = [db getTableSchema:table];
        if (!rs || rs.columnNameToIndexMap.count == 0) {
            [NSException raise:@"BadTable" format:@"Unknown table %@", table];
        }
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
            fatal(makeError([NSString stringWithFormat:@"Expected migration named %@ but found %@", expectedMigraitonName, name]));
        }
    } else {
        [_newMigrations addObject:@{ @"name":name, @"block":block }];
    }
    _migrationIndex += 1;
}
- (void)_finish {
    [_newMigrations each:^(NSDictionary* migration, NSUInteger i) {
        DLog(@"Running migration %@", migration[@"name"]);
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
                DLog(@"FAILED migration: %@", err);
                rollback();
                fatal(err);
            } else {
                DLog(@"Completed migration %@", migration[@"name"]);
                [_completedMigrations addObject:migration[@"name"]];
            }
        }];
    }];
    
    [Files writeDocumentJson:[SQLMigrations migrationDoc:_name] object:@{@"completedMigrations": _completedMigrations}];
}
@end

@implementation SQL

static FMDatabaseQueue* queue;
static NSMutableArray* openCallbacks;

+ (void)whenOpen:(void (^)())callback {
    if (queue) {
        callback();
    } else if (openCallbacks) {
        [openCallbacks addObject:callback];
    } else {
        openCallbacks = [NSMutableArray arrayWithObject:callback];
    }
}

+ (void)removeDatabase:(NSString *)name {
    [Files removeDocument:name];
    [Files removeDocument:[SQLMigrations migrationDoc:name]];
}

+ (void)copyDatabase:(NSString *)fromName to:(NSString *)toName {
    NSData* dbData = [Files readDocument:fromName];
    if (!dbData) { return; }
    NSData* migrationData = [Files readDocument:[SQLMigrations migrationDoc:fromName]];
    [Files writeDocument:toName data:dbData];
    [Files writeDocument:[SQLMigrations migrationDoc:toName] data:migrationData];
}

+ (void)backupDatabase:(NSString *)name {
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy:MM:dd HH:MM:ss:SSS"];
    NSString* backupName = [NSString stringWithFormat:@"%@-Backup-%@", name, [formatter stringFromDate:date]];
    
    NSString* size = [NSByteCountFormatter stringFromByteCount:[Files sizeOfDocument:name] countStyle:NSByteCountFormatterCountStyleFile];
    DLog(@"SQL: Backup db \"%@\" to \"%@\" (size: %@)", name, backupName, size);
    [self copyDatabase:name to:backupName];
}

+ (void) openDatabase:(NSString*)name practiceMode:(BOOL)practiceMode withMigrations:(SQLRegisterMigrations)migrationsFn {
    if (practiceMode) {
        [SQL copyDatabase:name to:@"SQLMigrationPractice"];
        name = @"SQLMigrationPractice";
        [UILabel.appendTo([StatusBar backgroundView]).bg([WHITE withAlpha:0.5]).text(@"Migration practice mode").textFont([Fonts bold:8]).size.textCenter.outsetSides(2).textColor(RED).fromRight(33).y(5) render];
    } else {
        [SQL backupDatabase:name];
    }
    queue = [FMDatabaseQueue databaseQueueWithPath:[Files documentPath:name]];
    columnsCache = [NSMutableDictionary dictionary];
    SQLMigrations* migrations = [[SQLMigrations alloc] initWithName:name];
    migrationsFn(migrations);
    [migrations _finish];
    if (openCallbacks) {
        NSArray* callbacks = openCallbacks;
        openCallbacks = nil;
        for (Block callback in callbacks) {
            callback();
        }
    }
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

+ (NSArray *)select:(NSString *)sql args:(NSArray *)args {
    return [self select:sql args:args error:nil];
}
+ (NSArray *)select:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    __block NSArray* result;
    [SQL autocommit:^(SQLConn *conn) {
        result = [conn select:sql args:args error:outError];
    }];
    return result;
}

+ (NSDictionary *)selectMaybe:(NSString *)sql args:(NSArray *)args {
    return [self selectMaybe:sql args:args error:nil];
}
+ (NSDictionary *)selectMaybe:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    __block NSDictionary* result;
    [SQL autocommit:^(SQLConn *conn) {
        result = [conn selectMaybe:sql args:args error:outError];
    }];
    return result;
}

+ (NSNumber *)selectNumber:(NSString *)sql args:(NSArray *)args {
    return [self selectNumber:sql args:args error:nil];
}
+ (NSNumber *)selectNumber:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    NSNumber* __block result;
    [SQL autocommit:^(SQLConn *conn) {
        result = [conn selectNumber:sql args:args error:outError];
    }];
    return result;
}

+ (void)execute:(NSString *)sql args:(NSArray *)args {
    return [self execute:sql args:args error:nil];
}
+ (void)execute:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    [SQL autocommit:^(SQLConn *conn) {
        [conn execute:sql args:args error:outError];
    }];
}

+ (NSDictionary *)selectOne:(NSString *)sql args:(NSArray *)args {
    return [self selectOne:sql args:args error:nil];
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

- (BOOL)table:(NSString *)table hasColumn:(NSString *)column {
    return [[self tableInfo:table].columns containsObject:column];
}

- (BOOL)tableExists:(NSString *)table {
    return [_db tableExists:table];
}

- (NSArray *)select:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    FMResultSet* resultSet = [_db executeQuery:sql withArgumentsInArray:args ];
    if (!resultSet) {
        [self onError:_db.lastError outError:outError];
        return nil;
    }
    
    NSMutableArray* rows = [NSMutableArray array];
    while ([resultSet next]) {
        [rows addObject:[resultSet resultDictionary]];
    }
    
    return rows;
}

- (void)onError:(NSError*)err outError:(NSError *__autoreleasing *)outError {
    if (!outError) {
        [NSException raise:@"DbError" format:@"Database error without outError set: %@", err];
    } else {
        *outError = err;
    }
}

- (NSDictionary *)selectOne:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    NSDictionary* row = [self selectMaybe:sql args:args error:outError];
    if (outError && *outError) {
        return nil;
    }
    
    if (!row) {
        [self onError:makeError([NSString stringWithFormat:@"SelectOne returned no rows.\nQuery: %@", sql]) outError:outError];
        return nil;
    }
    
    return row;
}

- (NSDictionary *)selectMaybe:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    NSArray* rows = [self select:sql args:args error:outError];
    
    if (outError && *outError) {
        return nil;
    }
    
    if (rows.count > 1) {
        [self onError:makeError([NSString stringWithFormat:@"SelectOne/SelectMaybe got more than 1 rows.\nQuery: %@", sql]) outError:outError];
        return nil;
    }
    
    return rows.firstObject;
}

- (NSNumber *)selectNumber:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    FMResultSet* resultSet = [_db executeQuery:sql withArgumentsInArray:args];
    if (!resultSet) {
        [self onError:_db.lastError outError:outError];
        return nil;
    }
    if (![resultSet next]) {
        [self onError:makeError(@"selectNumber got 0 rows") outError:outError];
        return nil;
    }
    NSNumber* result = [resultSet objectForColumnIndex:0];
    if ([resultSet next]) {
        [self onError:makeError(@"selectNumber got more than 1 row") outError:outError];
        return nil;
    }
    return result;
}

- (void)insertMultiple:(NSString *)sql argsList:(NSArray *)argsList error:(NSError *__autoreleasing *)outError {
    for (NSArray* args in argsList) {
        BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
        if (!success) {
            [self onError:_db.lastError outError:outError];
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
            [self onError:_db.lastError outError:outError];
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
        [self onError:_db.lastError outError:outError];
        return;
    }
}

- (void)updateSchema:(NSString *)sql error:(NSError *__autoreleasing *)outError {
    return [self schema:sql error:outError];
}
- (void)schema:(NSString *)sql error:(NSError *__autoreleasing *)outError {
    NSArray* statements = [sql split:@";"];
    if (!statements.count) {
        [self onError:makeError(@"Empty schema") outError:outError];
        return;
    }
    for (NSString* statement in statements) {
        if (!statement.trim.hasContent) { continue; }
        [self execute:statement args:nil error:outError];
        if (outError && *outError) {
            return;
        }
    }
}

- (void)execute:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
    if (!success) {
        [self onError:_db.lastError outError:outError];
        return;
    }
}

- (void)updateOne:(NSString *)sql args:(NSArray *)args error:(NSError *__autoreleasing *)outError {
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:args];
    if (!success) {
        [self onError:_db.lastError outError:outError];
        return;
    }
    if (_db.changes != 1) {
        [self onError:makeError(_db.changes == 0 ? @"updateOne affected no rows" : @"updateOne affected multipe rows") outError:outError];
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