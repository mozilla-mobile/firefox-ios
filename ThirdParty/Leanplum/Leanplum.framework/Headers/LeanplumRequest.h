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
#import "LPRequesting.h"

@interface LeanplumRequest : NSObject <LPRequesting> {
@private
    NSString *_httpMethod;
    NSString *_apiMethod;
    NSDictionary *_params;
    LPNetworkResponseBlock _response;
    LPNetworkErrorBlock _error;
    BOOL _sent;
    NSString *_requestId;
}

+ (void)initializeStaticVars;
+ (void)setUploadUrl:(NSString *)url;

- (void)attachApiKeys:(NSMutableDictionary *)dict;

- (id)initWithHttpMethod:(NSString *)httpMethod apiMethod:(NSString *)apiMethod
    params:(NSDictionary *)params;

+ (LeanplumRequest *)get:(NSString *)apiMethod params:(NSDictionary *)params;
+ (LeanplumRequest *)post:(NSString *)apiMethod params:(NSDictionary *)params;

- (void)onResponse:(LPNetworkResponseBlock)response;
- (void)onError:(LPNetworkErrorBlock)error;

- (void)send;
- (void)sendNow;
- (void)sendEventually;
- (void)sendIfConnected;
- (void)sendIfConnectedSync:(BOOL)sync;
// Sends the request if another request hasn't been sent within a particular time delay.
- (void)sendIfDelayed;
- (void)sendFilesNow:(NSArray *)filenames;

/**
 * Sends one data. Uses sendDatasNow: internally. See this method for more information.
 */
- (void)sendDataNow:(NSData *)data forKey:(NSString *)key;

/**
 * Send datas where key is the name and object is the data.
 * For example, key can be "file0" and object is NSData of png.
 */
- (void)sendDatasNow:(NSDictionary *)datas;

- (void)downloadFile:(NSString *)path;

+ (int)numPendingDownloads;
+ (void)onNoPendingDownloads:(LeanplumVariablesChangedBlock)block;

@end
