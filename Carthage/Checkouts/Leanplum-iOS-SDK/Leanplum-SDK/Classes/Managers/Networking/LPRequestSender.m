//
//  LPRequestSender.m
//  Leanplum
//
//  Created by Mayank Sanganeria on 6/30/18.
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

#import "LPRequestSender.h"
#import "LeanplumInternal.h"
#import "LPCountAggregator.h"
#import "LPRequest.h"
#import "LeanplumRequest.h"
#import "LPResponse.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"
#import "LPAPIConfig.h"
#import "LPUtils.h"
#import "LPOperationQueue.h"

@interface LeanplumRequest(LPRequestSender)

- (void)sendNow:(BOOL)async;

@end

@interface LPRequestSender()

@property (nonatomic, strong) id<LPNetworkEngineProtocol> engine;
@property (nonatomic, assign) NSTimeInterval lastSentTime;
@property (nonatomic, strong) NSDictionary *requestHeaders;

@property (nonatomic, strong) NSTimer *uiTimeoutTimer;
@property (nonatomic, assign) BOOL didUiTimeout;

@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end


@implementation LPRequestSender

+ (instancetype)sharedInstance {
    static LPRequestSender *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        if (_engine == nil) {
            if (!_requestHeaders) {
                _requestHeaders = [LPUtils createHeaders];
            }
            _engine = [LPNetworkFactory engineWithHostName:[LPConstantsState sharedState].apiHostName
                                        customHeaderFields:_requestHeaders];
        }
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

- (void)send:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest send];
    } else {
        [self sendEventually:request sync:NO];
        if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
            NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
            NSTimeInterval delay;
            if (!self.lastSentTime || currentTime - self.lastSentTime > LP_REQUEST_DEVELOPMENT_MAX_DELAY) {
                delay = LP_REQUEST_DEVELOPMENT_MIN_DELAY;
            } else {
                delay = (self.lastSentTime + LP_REQUEST_DEVELOPMENT_MAX_DELAY) - currentTime;
            }
            [self performSelector:@selector(sendIfConnected:) withObject:request afterDelay:delay];
        }
    }
    [self.countAggregator incrementCount:@"send_request_lp"];
}

- (void)sendNow:(id<LPRequesting>)request sync:(BOOL)sync
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendNow];
    } else {
        RETURN_IF_TEST_MODE;

        if (![LPAPIConfig sharedConfig].appId) {
            NSLog(@"Leanplum: Cannot send request. appId is not set");
            return;
        }
        if (![LPAPIConfig sharedConfig].accessKey) {
            NSLog(@"Leanplum: Cannot send request. accessKey is not set");
            return;
        }

        [self sendEventually:request sync:sync];
        [self sendRequests:sync];
    }
    [self.countAggregator incrementCount:@"send_now_lp"];
}

- (void)sendEventually:(id<LPRequesting>)request sync:(BOOL)sync
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendEventually:sync];
    } else {
        RETURN_IF_TEST_MODE;
        if (!request.sent) {
            request.sent = YES;

            void (^operationBlock)(void) = ^void() {
                LP_TRY
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                NSString *uuid = [userDefaults objectForKey:LEANPLUM_DEFAULTS_UUID_KEY];
                NSInteger count = [LPEventDataManager count];
                if (!uuid || count % MAX_EVENTS_PER_API_CALL == 0) {
                    uuid = [self generateUUID];
                }

                NSMutableDictionary *args = [self createArgsDictionaryForRequest:request];
                args[LP_PARAM_UUID] = uuid;
                [LPEventDataManager addEvent:args];

                [LPEventCallbackManager addEventCallbackAt:count
                                                 onSuccess:request.responseBlock
                                                   onError:request.errorBlock];
                LP_END_TRY
            };

            if (sync) {
                operationBlock();
            } else {
                [[LPOperationQueue serialQueue] addOperationWithBlock:operationBlock];
            }
        }
    }
    [self.countAggregator incrementCount:@"send_eventually_lp"];
}

- (void)sendIfConnected:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendIfConnected];
    } else {
        LP_TRY
        [self sendIfConnected:request sync:NO];
        LP_END_TRY
    }
    [self.countAggregator incrementCount:@"send_if_connected_lp"];
}

- (void)sendIfConnected:(id<LPRequesting>)request sync:(BOOL)sync
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendIfConnectedSync:sync];
    } else {
        if ([[Leanplum_Reachability reachabilityForInternetConnection] isReachable]) {
            if (sync) {
                [self sendNowSync:request];
            } else {
                [self sendNow:request];
            }
        } else {
            [self sendEventually:request sync:sync];
            if (request.errorBlock) {
                request.errorBlock([NSError errorWithDomain:@"Leanplum" code:1
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Device is offline"}]);
            }
        }
    }
    [self.countAggregator incrementCount:@"send_if_connected_sync_lp"];
}

- (void)sendNow:(id<LPRequesting>)request
{
    [self sendNow:request sync:NO];
}

- (void)sendNowSync:(id<LPRequesting>)request
{
    [self sendNow:request sync:YES];
}

// Wait 1 second for potential other API calls, and then sends the call synchronously
// if no other call has been sent within 1 minute.
- (void)sendIfDelayed:(id<LPRequesting>)request
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendIfDelayed];
    } else {
        [self sendEventually:request sync:NO];
        [self performSelector:@selector(sendIfDelayedHelper:)
                   withObject:request
                   afterDelay:LP_REQUEST_RESUME_DELAY];

    }
}

// Sends the call synchronously if no other call has been sent within 1 minute.
- (void)sendIfDelayedHelper:(LPRequest *)request
{
    LP_TRY
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        [self send:request];
    } else {
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        if (!self.lastSentTime || currentTime - self.lastSentTime > LP_REQUEST_PRODUCTION_DELAY) {
            [self sendIfConnected:request];
        }
    }
    LP_END_TRY
}

- (void)sendNow:(id<LPRequesting>)request withData:(NSData *)data forKey:(NSString *)key
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendDataNow:data forKey:key];
    } else {
        [self sendNow:request withDatas:@{key: data}];
    }
    
    [self.countAggregator incrementCount:@"send_now_with_data_lp"];
}

- (void)sendNow:(id<LPRequesting>)request withDatas:(NSDictionary *)datas
{
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldLeanplumRequest = request;
        [oldLeanplumRequest sendDatasNow:datas];
    } else {
        NSMutableDictionary *dict = [self createArgsDictionaryForRequest:request];
        [self attachApiKeys:dict];
        id<LPNetworkOperationProtocol> op =
        [self.engine operationWithPath:[LPConstantsState sharedState].apiServlet
                                params:dict
                            httpMethod:@"POST"
                                   ssl:[LPConstantsState sharedState].apiSSL
                        timeoutSeconds:60];

        [datas enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [op addData:obj forKey:key];
        }];

        [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
            if (request.responseBlock != nil) {
                request.responseBlock(operation, json);
            }
        } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
            LP_TRY
            if (request.errorBlock != nil) {
                request.errorBlock(err);
            }
            LP_END_TRY
        }];
        [self.engine enqueueOperation: op];
    }
    [self.countAggregator incrementCount:@"send_now_with_datas_lp"];
}

- (void)attachApiKeys:(NSMutableDictionary *)dict
{
    dict[LP_PARAM_APP_ID] = [LPAPIConfig sharedConfig].appId;
    dict[LP_PARAM_CLIENT_KEY] = [LPAPIConfig sharedConfig].accessKey;
}

- (NSString *)generateUUID
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:uuid forKey:LEANPLUM_DEFAULTS_UUID_KEY];
    [userDefaults synchronize];
    return uuid;
}

- (NSMutableDictionary *)createArgsDictionaryForRequest:(LPRequest *)request
{
    LPConstantsState *constants = [LPConstantsState sharedState];
    NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    NSMutableDictionary *args = [@{
                                   LP_PARAM_ACTION: request.apiMethod,
                                   LP_PARAM_DEVICE_ID: [LPAPIConfig sharedConfig].deviceId ?: @"",
                                   LP_PARAM_USER_ID: [LPAPIConfig sharedConfig].userId ?: @"",
                                   LP_PARAM_SDK_VERSION: constants.sdkVersion,
                                   LP_PARAM_CLIENT: constants.client,
                                   LP_PARAM_DEV_MODE: @(constants.isDevelopmentModeEnabled),
                                   LP_PARAM_TIME: timestamp,
                                   LP_PARAM_REQUEST_ID: request.requestId,
                                   } mutableCopy];
    if ([LPAPIConfig sharedConfig].token) {
        args[LP_PARAM_TOKEN] = [LPAPIConfig sharedConfig].token;
    }
    [args addEntriesFromDictionary:request.params];
    return args;
}

- (void)sendRequests:(BOOL)sync
{
    NSBlockOperation *requestOperation = [NSBlockOperation new];
    __weak NSBlockOperation *weakOperation = requestOperation;

    void (^operationBlock)(void) = ^void() {
        LP_TRY
        if ([weakOperation isCancelled]) {
            return;
        }

        [self generateUUID];
        self.lastSentTime = [NSDate timeIntervalSinceReferenceDate];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        [[LPCountAggregator sharedAggregator] sendAllCounts];
        // Simulate pop all requests.
        NSArray *requestsToSend = [LPEventDataManager eventsWithLimit:MAX_EVENTS_PER_API_CALL];
        if (requestsToSend.count == 0) {
            return;
        }

        // Set up request operation.
        NSString *requestData = [LPJSON stringFromJSON:@{LP_PARAM_DATA:requestsToSend}];
        NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
        LPConstantsState *constants = [LPConstantsState sharedState];
        NSMutableDictionary *multiRequestArgs = [@{
                                                   LP_PARAM_DATA: requestData,
                                                   LP_PARAM_SDK_VERSION: constants.sdkVersion,
                                                   LP_PARAM_CLIENT: constants.client,
                                                   LP_PARAM_ACTION: LP_METHOD_MULTI,
                                                   LP_PARAM_TIME: timestamp
                                                   } mutableCopy];
        [self attachApiKeys:multiRequestArgs];
        int timeout = sync ? constants.syncNetworkTimeoutSeconds : constants.networkTimeoutSeconds;

        NSTimeInterval uiTimeoutInterval = timeout;
        timeout = 5 * timeout; // let slow operations complete

        dispatch_async(dispatch_get_main_queue(), ^{
            self.uiTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:uiTimeoutInterval target:self selector:@selector(uiDidTimeout) userInfo:nil repeats:NO];
        });
        self.didUiTimeout = NO;

        id<LPNetworkOperationProtocol> op = [self.engine operationWithPath:constants.apiServlet
                                                                    params:multiRequestArgs
                                                                httpMethod:@"POST"
                                                                       ssl:constants.apiSSL
                                                            timeoutSeconds:timeout];

        // Request callbacks.
        [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
            LP_TRY
            if ([weakOperation isCancelled]) {
                dispatch_semaphore_signal(semaphore);
                return;
            }

            [self.uiTimeoutTimer invalidate];
            self.uiTimeoutTimer = nil;

            // Delete events on success.
            [LPEventDataManager deleteEventsWithLimit:requestsToSend.count];

            // Send another request if the last request had maximum events per api call.
            if (requestsToSend.count == MAX_EVENTS_PER_API_CALL) {
                [self sendRequests:sync];
            }

            if (!self.didUiTimeout) {
                [LPEventCallbackManager invokeSuccessCallbacksOnResponses:json
                                                                 requests:requestsToSend
                                                                operation:operation];
            }
            dispatch_semaphore_signal(semaphore);
            LP_END_TRY

        } errorHandler:^(id<LPNetworkOperationProtocol> completedOperation, NSError *err) {
            LP_TRY
            if ([weakOperation isCancelled]) {
                dispatch_semaphore_signal(semaphore);
                return;
            }

            // Retry on 500 and other network failures.
            NSInteger httpStatusCode = completedOperation.HTTPStatusCode;
            if (httpStatusCode == 408
                || (httpStatusCode >= 500 && httpStatusCode < 600)
                || err.code == NSURLErrorBadServerResponse
                || err.code == NSURLErrorCannotConnectToHost
                || err.code == NSURLErrorDNSLookupFailed
                || err.code == NSURLErrorNotConnectedToInternet
                || err.code == NSURLErrorTimedOut) {
                NSLog(@"Leanplum: %@", err);
            } else {
                id errorResponse = completedOperation.responseJSON;
                NSString *errorMessage = [LPResponse getResponseError:[LPResponse getLastResponse:errorResponse]];
                if (errorMessage) {
                    if ([errorMessage hasPrefix:@"App not found"]) {
                        errorMessage = @"No app matching the provided app ID was found.";
                        constants.isInPermanentFailureState = YES;
                    } else if ([errorMessage hasPrefix:@"Invalid access key"]) {
                        errorMessage = @"The access key you provided is not valid for this app.";
                        constants.isInPermanentFailureState = YES;
                    } else if ([errorMessage hasPrefix:@"Development mode requested but not permitted"]) {
                        errorMessage = @"A call to [Leanplum setAppIdForDevelopmentMode] with your production key was made, which is not permitted.";
                        constants.isInPermanentFailureState = YES;
                    }
                    NSLog(@"Leanplum: %@", errorMessage);
                } else {
                    NSLog(@"Leanplum: %@", err);
                }

                // Delete on permanant error state.
                [LPEventDataManager deleteEventsWithLimit:requestsToSend.count];
            }

            // Invoke errors on all requests.
            [LPEventCallbackManager invokeErrorCallbacksWithError:err];
            [[LPOperationQueue serialQueue] cancelAllOperations];
            dispatch_semaphore_signal(semaphore);
            LP_END_TRY
        }];

        // Execute synchronously. Don't block for more than 'timeout' seconds.
        [self.engine enqueueOperation:op];
        dispatch_time_t dispatchTimeout = dispatch_time(DISPATCH_TIME_NOW, timeout*NSEC_PER_SEC);
        long status = dispatch_semaphore_wait(semaphore, dispatchTimeout);

        // Request timed out.
        if (status != 0) {
            LP_TRY
            NSLog(@"Leanplum: Multi Request timed out");
            [op cancel];
            NSError *error = [NSError errorWithDomain:@"Leanplum" code:1
                                             userInfo:@{NSLocalizedDescriptionKey: @"Request timed out"}];
            [LPEventCallbackManager invokeErrorCallbacksWithError:error];
            [[LPOperationQueue serialQueue] cancelAllOperations];
            LP_END_TRY
        }
        LP_END_TRY
    };

    // Send. operationBlock will run synchronously.
    // Adding to OperationQueue puts it in the background.
    if (sync) {
        operationBlock();
    } else {
        [requestOperation addExecutionBlock:operationBlock];
        [[LPOperationQueue serialQueue] addOperation:requestOperation];
    }
}

-(void)uiDidTimeout {
    self.didUiTimeout = YES;
    [self.uiTimeoutTimer invalidate];
    self.uiTimeoutTimer = nil;
    // Invoke errors on all requests.
    NSError *error = [NSError errorWithDomain:@"leanplum" code:-1001 userInfo:[NSDictionary dictionaryWithObject:@"Request timed out" forKey:NSLocalizedDescriptionKey]];
    [LPEventCallbackManager invokeErrorCallbacksWithError:error];
}

@end
