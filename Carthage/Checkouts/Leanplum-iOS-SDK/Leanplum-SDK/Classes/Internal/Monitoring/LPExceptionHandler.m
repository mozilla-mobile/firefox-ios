//
//  LPExceptionHandler.h
//  Leanplum iOS SDK Version 2.0.6
//
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

#import "LPExceptionHandler.h"
#import "LPCountAggregator.h"

@interface LPExceptionHandler()

@property (nonatomic, strong) id<LPExceptionReporting> exceptionReporter;
@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end

@implementation LPExceptionHandler

+(instancetype)sharedExceptionHandler
{
    static LPExceptionHandler *sharedExceptionHandler = nil;
    @synchronized(self) {
        if (!sharedExceptionHandler) {
            sharedExceptionHandler = [[self alloc] init];
        }
    }
    return sharedExceptionHandler;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeLeanplumReporter];
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

-(void)initializeLeanplumReporter
{
    Class LPExceptionReporterClass = NSClassFromString(@"LPExceptionReporter");
    if (LPExceptionReporterClass) {
        _exceptionReporter = [[LPExceptionReporterClass alloc] init];
    }
}

-(void)reportException:(NSException *)exception
{
    if (self.exceptionReporter) {
        [self.exceptionReporter reportException:exception];
        
        [self.countAggregator incrementCount:@"report_exception"];
    }
}

@end
