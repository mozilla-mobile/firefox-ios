//
//  LPEventDataManager.h
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

@interface LPEventDataManager : NSObject

/**
 * Add event to database.
 */
+ (void)addEvent:(NSDictionary *)event;

/**
 * Add multiple events to database.
 */
+ (void)addEvents:(NSArray *)events;

/**
 * Fetch events with limit. 
 * Usually you pass the maximum events server can handle.
 */
+ (NSArray *)eventsWithLimit:(NSInteger)limit;

/**
 * Delete first X events using limit.
 */
+ (void)deleteEventsWithLimit:(NSInteger)limit;

/**
 * Returns the number of total events stored.
 */
+ (NSInteger)count;

@end
