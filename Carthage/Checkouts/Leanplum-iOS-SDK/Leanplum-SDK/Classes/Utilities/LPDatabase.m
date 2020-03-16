//
//  LPDatabase.m
//  Leanplum
//
//  Created by Alexis Oyama on 6/9/17.
//  Copyright (c) 2017 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LPDatabase.h"
#import "LPFileManager.h"
#import "LeanplumInternal.h"
#import "LPConstants.h"
#import <sqlite3.h>

static sqlite3 *sqlite;
static BOOL retryOnCorrupt;
static BOOL willSendErrorLog;

@implementation LPDatabase

- (id)init
{
    if (self = [super init]) {
        retryOnCorrupt = NO;
        willSendErrorLog = NO;
        [self initSQLite];
    }
    return self;
}

/**
 * Create/Open SQLite database.
 */
- (sqlite3 *)initSQLite
{
    const char *sqliteFilePath = [[LPDatabase sqliteFilePath] UTF8String];
    int result = sqlite3_open_v2(sqliteFilePath, &sqlite, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, NULL);
    if (result != SQLITE_OK) {
        [self handleSQLiteError:@"SQLite fail to open" errorResult:result query:nil];
        return nil;
    }

    if (result == SQLITE_OK) {
        if ([LPFileManager addSkipBackupAttributeToItemAtPath:[LPDatabase sqliteFilePath]]) {
            NSLog(@"Leanplum: Successfully excluded database from syncing.");
        } else {
            NSLog(@"Leanplum: Unable to exclude database from syncing.");
        }
    }

    retryOnCorrupt = NO;
    
    // Create tables.
    [self runQuery:@"CREATE TABLE IF NOT EXISTS event ("
                        "data TEXT NOT NULL"
                    "); PRAGMA user_version = 1;"];
    return sqlite;
}

- (void)dealloc
{
    sqlite3_close(sqlite);
}

+ (LPDatabase *)sharedDatabase
{
    static id _database = nil;
    static dispatch_once_t databaseToken;
    dispatch_once(&databaseToken, ^{
        _database = [self new];
    });
    return _database;
}

/**
 * Returns the file path of sqlite.
 */
+ (NSString *)sqliteFilePath
{
    return [[LPFileManager documentsDirectory] stringByAppendingPathComponent:LEANPLUM_SQLITE_NAME];
}

/**
 * Helper function that logs and sends to the server.
 */
- (void)handleSQLiteError:(NSString *)errorName errorResult:(int)result query:(NSString *)query
{
    NSString *reason = [NSString stringWithFormat:@"%s (%d)", sqlite3_errmsg(sqlite), result];
    if (query) {
        reason = [NSString stringWithFormat:@"'%@' %@", query, reason];
    }
    LPLog(LPError, @"%@: %@", errorName, reason);
    
    // If SQLite is corrupted, create a new one.
    // Using retryOnCorrupt to prevent infinite loop.
    if (result == SQLITE_CORRUPT && !retryOnCorrupt) {
        [[NSFileManager defaultManager] removeItemAtPath:[LPDatabase sqliteFilePath] error:nil];
        retryOnCorrupt = YES;
        [self initSQLite];
    }
}

/**
 * Helper method that returns sqlite statement from query.
 * Used by both runQuery: and rowsFromQuery.
 */
- (sqlite3_stmt *)sqliteStatementFromQuery:(NSString *)query
                               bindObjects:(NSArray *)objectsToBind
{
    // Retry creating SQLite.
    if (!query || (!sqlite && [self initSQLite])) {
        return nil;
    }
    
    sqlite3_stmt *statement;
    int __block result = sqlite3_prepare_v2(sqlite, [query UTF8String], -1, &statement, NULL);
    if (result != SQLITE_OK) {
        [self handleSQLiteError:@"SQLite fail to prepare" errorResult:result query:query];
        return nil;
    }
    
    // Bind objects.
    // It is recommended to use this instead of making a full query in NSString to
    // prevent from SQL injection attacks and errors from having a quotation mark in text.
    [objectsToBind enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isKindOfClass:[NSString class]]) {
            LPLog(LPError, @"Bind object have to be NSString.");
        }
        
        result = sqlite3_bind_text(statement, (int)idx+1, [obj UTF8String],
                                   (int)[obj lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                   SQLITE_TRANSIENT);
        
        if (result != SQLITE_OK) {
            NSString *message = [NSString stringWithFormat:@"SQLite fail to bind %@ to %ld", obj, idx+1];
            [self handleSQLiteError:message errorResult:result query:query];
        }
    }];
    
    return statement;
}

- (void)runQuery:(NSString *)query
{
    [self runQuery:query bindObjects:nil];
}

- (void)runQuery:(NSString *)query bindObjects:(NSArray *)objectsToBind
{
    // Retry creating SQLite.
    if (!sqlite && [self initSQLite]) {
        return;
    }
    
    @synchronized (self) {
        @try {
            sqlite3_stmt *statement = [self sqliteStatementFromQuery:query bindObjects:objectsToBind];
            if (!statement) {
                return;
            }
            int result = sqlite3_step(statement);
            if (result != SQLITE_DONE) {
                LPLog(LPError, @"SQLite fail to run query.");
            }
            sqlite3_finalize(statement);
        } @catch (NSException *e) {
            LPLog(LPError, @"SQLite operation failed.");
            // TODO: Make sure to catch this when new logging is in place,
        }
    }
}

- (NSArray *)rowsFromQuery:(NSString *)query
{
    return [self rowsFromQuery:query bindObjects:nil];
}

- (NSArray *)rowsFromQuery:(NSString *)query bindObjects:(NSArray *)objectsToBind
{
    // Retry creating SQLite.
    if (!sqlite && [self initSQLite]) {
        return @[];
    }
    
    @synchronized (self) {
        @try {
            NSMutableArray *rows = [NSMutableArray new];
            sqlite3_stmt *statement = [self sqliteStatementFromQuery:query
                                                         bindObjects:objectsToBind];
            if (!statement) {
                return @[];
            }
            
            // Iterate through rows.
            while (sqlite3_step(statement) == SQLITE_ROW) {
                // Get column data as dictionary where column name is the key
                // and value will be a blob or a string. This is a safe conversion.
                // Details: http://www.sqlite.org/c3ref/column_blob.html
                NSMutableDictionary *columnData = [NSMutableDictionary new];
                int columnsCount = sqlite3_column_count(statement);
                for (int i=0; i<columnsCount; i++){
                    char *columnKeyUTF8 = (char *)sqlite3_column_name(statement, i);
                    NSString *columnKey = [NSString stringWithUTF8String:columnKeyUTF8];
                    
                    if (sqlite3_column_type(statement, i) == SQLITE_BLOB) {
                        NSData *columnBytes = [[NSData alloc] initWithBytes:sqlite3_column_blob(statement, i)
                                                                     length:sqlite3_column_bytes(statement, i)];
                        columnData[columnKey] = [NSKeyedUnarchiver unarchiveObjectWithData:columnBytes];
                    } else {
                        char *columnValueUTF8 = (char *)sqlite3_column_text(statement, i);
                        if (columnValueUTF8) {
                            NSString *columnValue = [NSString stringWithUTF8String:columnValueUTF8];
                            columnData[columnKey] = columnValue;
                        }
                    }
                }
                [rows addObject:columnData];
            }
            sqlite3_finalize(statement);
            return rows;
        } @catch (NSException *e) {
            LPLog(LPError, @"SQLite operation failed.");
            // TODO: Make sure to catch this when new logging is in place,
        }
    }
    return @[];
}

@end
