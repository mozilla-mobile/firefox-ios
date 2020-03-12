//
//  LPOperationQueue.m
//  Leanplum
//
//  Created by Milos Jakovljevic on 10/3/19.
//  Copyright (c) 2019 Leanplum, Inc. All rights reserved.
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

#import "LPOperationQueue.h"

@implementation LPOperationQueue

+ (NSOperationQueue *) serialQueue
{
    static NSOperationQueue *_operationQueue;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _operationQueue = [NSOperationQueue new];
        _operationQueue.maxConcurrentOperationCount = 1;
    });
    return _operationQueue;
}

@end
