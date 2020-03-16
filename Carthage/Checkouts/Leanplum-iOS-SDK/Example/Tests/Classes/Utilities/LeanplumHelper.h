//
//  LeanplumHelper.h
//  Leanplum-SDK
//
//  Created by Milos Jakovljevic on 10/17/16.
//  Copyright © 2016 Leanplum. All rights reserved.
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
#import "Leanplum.h"
#import "LPVarCache.h"

extern NSString *APPLICATION_ID;
extern NSString *DEVELOPMENT_KEY;
extern NSString *PRODUCTION_KEY;

/// host of the api
extern NSString *API_HOST;

/// default dispatch time
extern NSInteger DISPATCH_WAIT_TIME;

@interface LeanplumHelper : NSObject

/// called before starting any test, to swizzle methods
+ (void)setup_method_swizzling;

/// sets up development keys
+ (void)setup_development_test;
/// sets up production keys
+ (void)setup_production_test;

/// sets up development keys and starts the sdk
+ (BOOL)start_development_test;
/// sets up production keys and starts the sdk
+ (BOOL)start_production_test;

/// used to reset everything after single test case
+ (void)clean_up;

/// default dispatch time of 10 seconds
+ (dispatch_time_t)default_dispatch_time;

/// retrieve string from a file
+ (NSString *)retrieve_string_from_file:(NSString *)file ofType:(NSString *)type;

/// retrieve data from a file
+ (NSData *)retrieve_data_from_file:(NSString *)file ofType:(NSString *)type;

@end
