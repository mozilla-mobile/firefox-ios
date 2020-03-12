//
//  LPCountAggregator.m
//  Leanplum
//
//  Created by Grace Gu on 8/27/18.
//  Copyright (c) 2018 Leanplum, Inc. All rights reserved.
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

#import "LPCountAggregator.h"
#import "LPConstants.h"
#import "LeanplumRequest.h"

@interface LPCountAggregator()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *counts;

@end

@implementation LPCountAggregator

static LPCountAggregator *sharedCountAggregator = nil;
static dispatch_once_t leanplum_onceToken;

+ (instancetype)sharedAggregator {
    dispatch_once(&leanplum_onceToken, ^{
        sharedCountAggregator = [[self alloc] init];
    });
    return sharedCountAggregator;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if (!self.counts) {
            self.counts = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (void)incrementCount:(nonnull NSString *)name {
    [self incrementCount:name by: 1];
}

- (void)incrementCount:(nonnull NSString *)name by:(int)incrementCount {
    if ([self.enabledCounters containsObject:name]) {
        int count = 0;
        if ([self.counts objectForKey:name]) {
            count = [self.counts[name] intValue];
        }
        count = count + incrementCount;
        self.counts[name] = [NSNumber numberWithInt:count];
    }
}

- (NSDictionary<NSString *, NSNumber *> *)getAndClearCounts {
    NSDictionary<NSString *, NSNumber *> *previousCounts = [[NSDictionary alloc]initWithDictionary:self.counts];
    [self.counts removeAllObjects];
    return previousCounts;
}

- (NSMutableDictionary<NSString *, id> *)makeParams:(nonnull NSString *)name withCount:(int) count {
    NSMutableDictionary<NSString *, id> *params = [[NSMutableDictionary alloc] init];

    params[LP_PARAM_TYPE] = LP_VALUE_SDK_COUNT;
    params[LP_PARAM_NAME] = name;
    params[LP_PARAM_COUNT] = [NSNumber numberWithInt:count];
    return params;
}

- (void)sendAllCounts {
    NSDictionary<NSString *, NSNumber *> *counts = [self getAndClearCounts];
    for (NSString *name in counts) { // iterate over counts, creating one request per counter
        int count = [counts[name] intValue];
        NSMutableDictionary<NSString *, id> *params = [self makeParams:name withCount:count];
        [[LeanplumRequest post:LP_METHOD_LOG params:params] sendEventually:NO];
    }
}

@end
