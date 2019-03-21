//
//  LPUtils.h
//  Leanplum
//
//  Created by Ben Marten on 6/6/16.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
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

@interface LPUtils : NSObject

/**
 * Checks if the object is null or empty.
 */
+ (BOOL)isNullOrEmpty:(id)obj;

/**
 * Checks if the string is empty or have spaces.
 */
+ (BOOL)isBlank:(id)obj;

/**
 * Computes MD5 of NSData. Mostly used for uploading images.
 */
+ (NSString *)md5OfData:(NSData *)data;

/**
 * Returns base64 encoded string from NSData. Convenience method
 * that supports iOS6.
 */
+ (NSString *)base64EncodedStringFromData:(NSData *)data;

/**
 * Initialize exception handling
 */
+ (void)initExceptionHandling;

/**
 * Report an exception
 */
+ (void)handleException:(NSException *)exception;

/**
 * Create Request Headers for network call
 */
+ (NSDictionary *)createHeaders;

@end
