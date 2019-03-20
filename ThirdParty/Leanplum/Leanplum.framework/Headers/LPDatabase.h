//
//  LPDatabase.h
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

#import <Foundation/Foundation.h>

@interface LPDatabase : NSObject

/**
 * Returns shared database.
 */
+ (LPDatabase *)sharedDatabase;

/**
 * Returns a file path of sqlite from the documents directory.
 */
+ (NSString *)sqliteFilePath;

/**
 * Runs a query. 
 * Use this to create, update, and delete.
 */
- (void)runQuery:(NSString *)query;

/**
 * Runs a query with objects to bind. Use this to insert.
 * Use ? in the query and pass array of NSString objects to bindObjects.
 */
- (void)runQuery:(NSString *)query bindObjects:(NSArray *)objectsToBind;

/**
 * Return rows as array from the query. 
 * Use this for fetching data.
 * Datas are saved as NSDictionary. Key is the column's name.
 */
- (NSArray *)rowsFromQuery:(NSString *)query;

/**
 * Return rows as array from the query with objects.
 * Use ? in the query and pass array of NSString objects to bindObjects.
 */
- (NSArray *)rowsFromQuery:(NSString *)query bindObjects:(NSArray *)objectsToBind;

@end
