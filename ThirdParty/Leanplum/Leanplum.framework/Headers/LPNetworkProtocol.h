//
//  LPNetworkProtocol.h
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
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
#import "Leanplum_Reachability.h"

@protocol LPNetworkOperationProtocol;

/**
 * Network callback blocks.
 */
typedef void (^LPNetworkResponseBlock)(id<LPNetworkOperationProtocol> operation, id json);
typedef void (^LPNetworkResponseErrorBlock)(id<LPNetworkOperationProtocol> operation,
                                            NSError *error);
typedef void (^LPNetworkErrorBlock)(NSError *error);
typedef void (^LPNetworkProgressBlock)(double progress);

/**
 * Network Operation Protocol that all network operation have to implement.
 */
@protocol LPNetworkOperationProtocol <NSObject>

- (void)addCompletionHandler:(LPNetworkResponseBlock)response
                errorHandler:(LPNetworkResponseErrorBlock)error;
- (void)onUploadProgressChanged:(LPNetworkProgressBlock)uploadProgressBlock;

- (NSInteger)HTTPStatusCode;
- (id)responseJSON;
- (NSData *)responseData;
- (NSString*)responseString;
- (void)addFile:(NSString *)filePath forKey:(NSString *)key;
- (void)addData:(NSData *)data forKey:(NSString *)key;
- (void)cancel;
+ (NSString *)fileRequestMethod;

@end

/**
 * Network Engine Protocol that all network engine have to implement.
 */
@protocol LPNetworkEngineProtocol <NSObject>

- (id)initWithHostName:(NSString *)hostName customHeaderFields:(NSDictionary *)headers;
- (id)initWithHostName:(NSString *)hostName;

- (id<LPNetworkOperationProtocol>)operationWithPath:(NSString *)path
                                             params:(NSMutableDictionary *)body
                                         httpMethod:(NSString *)method
                                                ssl:(BOOL)useSSL
                                     timeoutSeconds:(int)timeout;
- (id<LPNetworkOperationProtocol>)operationWithURLString:(NSString *)urlString
                                                  params:(NSMutableDictionary *)body
                                              httpMethod:(NSString *)method
                                          timeoutSeconds:(int)timeout;
- (id<LPNetworkOperationProtocol>)operationWithURLString:(NSString *)urlString;
- (void)enqueueOperation:(id<LPNetworkOperationProtocol>)operation;
- (void)runSynchronously:(id<LPNetworkOperationProtocol>)operation;

@end
