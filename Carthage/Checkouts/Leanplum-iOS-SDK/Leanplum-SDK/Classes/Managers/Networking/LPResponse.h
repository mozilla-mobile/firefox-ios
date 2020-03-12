//
//  LeanplumRequest.h
//  Leanplum
//
//  Created by Andrew First on 4/30/12.
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
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
#import "LPNetworkFactory.h"

@interface LPResponse : NSObject

+ (NSUInteger)numResponsesInDictionary:(NSDictionary *)dictionary;
+ (NSDictionary *)getResponseAt:(NSUInteger)index fromDictionary:(NSDictionary *)dictionary;
+ (NSDictionary *)getLastResponse:(NSDictionary *)dictionary;
+ (BOOL)isResponseSuccess:(NSDictionary *)dictionary;
+ (NSString *)getResponseError:(NSDictionary *)dictionary;

@end
