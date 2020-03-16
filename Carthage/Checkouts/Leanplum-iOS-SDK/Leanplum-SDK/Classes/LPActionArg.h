//
//  Leanplum.h
//  Leanplum iOS SDK Version 2.0.6
//
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
#import <UIKit/UIKit.h>
#import "LPInbox.h"

@interface LPActionArg : NSObject
/**
 * @{
 * Defines a Leanplum Action Argument
 */
+ (LPActionArg *)argNamed:(NSString *)name withNumber:(NSNumber *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withString:(NSString *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withBool:(BOOL)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withFile:(NSString *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withDict:(NSDictionary *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withArray:(NSArray *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withAction:(NSString *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withColor:(UIColor *)defaultValue;
/**@}*/

@property (readonly, strong) NSString *name;
@property (readonly, strong) id defaultValue;
@property (readonly, strong) NSString *kind;

@end
