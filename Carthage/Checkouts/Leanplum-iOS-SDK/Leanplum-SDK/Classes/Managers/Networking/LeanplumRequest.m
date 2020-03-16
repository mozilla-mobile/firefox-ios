//
//  LeanplumRequest.m
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

#import "Leanplum.h"
#import "LeanplumInternal.h"
#import "LeanplumRequest.h"
#import "LPCountAggregator.h"
#import "LPResponse.h"
#import "LPConstants.h"
#import "LPFileManager.h"
#import "NSTimer+Blocks.h"
#import "LPKeychainWrapper.h"
#import "LPEventDataManager.h"
#import "LPEventCallbackManager.h"
#import "LPAPIConfig.h"
#import "LPCountAggregator.h"
#import "LPUtils.h"
#import "LPFileTransferManager.h"
#import "LPOperationQueue.h"

static id<LPNetworkEngineProtocol> engine;
static NSString *uploadUrl;
static NSMutableDictionary *fileTransferStatus;
static int pendingDownloads;
static LeanplumVariablesChangedBlock noPendingDownloadsBlock;
static NSString *token = nil;
static NSMutableDictionary *fileUploadSize;
static NSMutableDictionary *fileUploadProgress;
static NSString *fileUploadProgressString;
static NSMutableDictionary *pendingUploads;
static NSTimeInterval lastSentTime;
static NSDictionary *_requestHheaders;

@implementation LeanplumRequest

+ (void)initializeStaticVars
{
    fileTransferStatus = [[NSMutableDictionary alloc] init];
    fileUploadSize = [NSMutableDictionary dictionary];
    fileUploadProgress = [NSMutableDictionary dictionary];
    pendingUploads = [NSMutableDictionary dictionary];
}

+ (void)setUploadUrl:(NSString *)url_
{
    uploadUrl = url_;
}

- (id)initWithHttpMethod:(NSString *)httpMethod
               apiMethod:(NSString *)apiMethod
                  params:(NSDictionary *)params
{
    self = [super init];
    if (self) {
        _httpMethod = httpMethod;
        _apiMethod = apiMethod;
        _params = params;
        _requestId = [[NSUUID UUID] UUIDString];
        if (engine == nil) {
            if (!_requestHheaders) {
                _requestHheaders = [LPUtils createHeaders];
            }
            engine = [LPNetworkFactory engineWithHostName:[LPConstantsState sharedState].apiHostName
                                       customHeaderFields:_requestHheaders];
        }
    }
    return self;
}

+ (LeanplumRequest *)get:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"get_request"];
    
    return [[LeanplumRequest alloc] initWithHttpMethod:@"GET" apiMethod:apiMethod params:params];
}

+ (LeanplumRequest *)post:(NSString *)apiMethod params:(NSDictionary *)params
{
    LPLogType level = [apiMethod isEqualToString:LP_METHOD_LOG] ? LPDebug : LPVerbose;
    LPLog(level, @"Will call API method %@ with arguments %@", apiMethod, params);
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"post_request"];
    
    return [[LeanplumRequest alloc] initWithHttpMethod:@"POST" apiMethod:apiMethod params:params];
}

+ (NSString *)generateUUID
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:uuid forKey:LEANPLUM_DEFAULTS_UUID_KEY];
    [userDefaults synchronize];
    return uuid;
}

- (void)onResponse:(LPNetworkResponseBlock)response
{
    _response = [response copy];
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"on_response"];
}

- (void)onError:(LPNetworkErrorBlock)error
{
    _error = [error copy];
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"on_error"];
}

- (NSMutableDictionary *)createArgsDictionary
{
    LPConstantsState *constants = [LPConstantsState sharedState];
    NSString *timestamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    NSMutableDictionary *args = [@{
                                   LP_PARAM_ACTION: _apiMethod,
                                   LP_PARAM_DEVICE_ID: [LPAPIConfig sharedConfig].deviceId ?: @"",
                                   LP_PARAM_USER_ID: [LPAPIConfig sharedConfig].userId ?: @"",
                                   LP_PARAM_SDK_VERSION: constants.sdkVersion,
                                   LP_PARAM_CLIENT: constants.client,
                                   LP_PARAM_DEV_MODE: @(constants.isDevelopmentModeEnabled),
                                   LP_PARAM_TIME: timestamp,
                                   } mutableCopy];
    if (token) {
        args[LP_PARAM_TOKEN] = token;
    }
    [args addEntriesFromDictionary:_params];
    return args;
}

- (void)send
{
    [self sendEventually:NO];
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval delay;
        if (!lastSentTime || currentTime - lastSentTime > LP_REQUEST_DEVELOPMENT_MAX_DELAY) {
            delay = LP_REQUEST_DEVELOPMENT_MIN_DELAY;
        } else {
            delay = (lastSentTime + LP_REQUEST_DEVELOPMENT_MAX_DELAY) - currentTime;
        }
        [self performSelector:@selector(sendIfConnected) withObject:nil afterDelay:delay];
    }
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_request"];
}

// Wait 1 second for potential other API calls, and then sends the call synchronously
// if no other call has been sent within 1 minute.
- (void)sendIfDelayed
{
    [self sendEventually:NO];
    [self performSelector:@selector(sendIfDelayedHelper)
               withObject:nil
               afterDelay:LP_REQUEST_RESUME_DELAY];
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_if_delayed"];
}

// Sends the call synchronously if no other call has been sent within 1 minute.
- (void)sendIfDelayedHelper
{
    LP_TRY
    if ([LPConstantsState sharedState].isDevelopmentModeEnabled) {
        [self send];
    } else {
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        if (!lastSentTime || currentTime - lastSentTime > LP_REQUEST_PRODUCTION_DELAY) {
            [self sendIfConnected];
        }
    }
    LP_END_TRY
}

- (void)sendIfConnected
{
    LP_TRY
    [self sendIfConnectedSync:NO];
    LP_END_TRY
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_if_connected"];
}

- (void)sendIfConnectedSync:(BOOL)sync
{
    if ([[Leanplum_Reachability reachabilityForInternetConnection] isReachable]) {
        if (sync) {
            [self sendNowSync];
        } else {
            [self sendNow];
        }
    } else {
        [self sendEventually:sync];
        if (_error) {
            _error([NSError errorWithDomain:@"Leanplum" code:1
                                   userInfo:@{NSLocalizedDescriptionKey: @"Device is offline"}]);
        }
    }
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_if_connected_sync"];
}

- (void)attachApiKeys:(NSMutableDictionary *)dict
{
    dict[LP_PARAM_APP_ID] = [LPAPIConfig sharedConfig].appId;
    dict[LP_PARAM_CLIENT_KEY] = [LPAPIConfig sharedConfig].accessKey;
}

- (void)sendNow:(BOOL)async
{
    RETURN_IF_TEST_MODE;

    if (![LPAPIConfig sharedConfig].appId) {
        NSLog(@"Leanplum: Cannot send request. appId is not set");
        return;
    }
    if (![LPAPIConfig sharedConfig].accessKey) {
        NSLog(@"Leanplum: Cannot send request. accessKey is not set");
        return;
    }

    // Sends the requests asynchronous [self sendEventually:NO].
    [self sendEventually:!async];
    [self sendRequests:async];

    [[LPCountAggregator sharedAggregator] incrementCount:@"send_now"];
}

- (void)sendRequests:(BOOL)async
{
    NSBlockOperation *requestOperation = [NSBlockOperation new];
    __weak NSBlockOperation *weakOperation = requestOperation;
    
    void (^operationBlock)(void) = ^void() {
        LP_TRY
        if ([weakOperation isCancelled]) {
            return;
        }
        
        [LeanplumRequest generateUUID];
        lastSentTime = [NSDate timeIntervalSinceReferenceDate];
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
        int timeout = async ? constants.networkTimeoutSeconds : constants.syncNetworkTimeoutSeconds;
        id<LPNetworkOperationProtocol> op = [engine operationWithPath:constants.apiServlet
                                                               params:multiRequestArgs
                                                           httpMethod:self->_httpMethod
                                                                  ssl:constants.apiSSL
                                                       timeoutSeconds:timeout];
        
        // Request callbacks.
        [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
            LP_TRY
            if ([weakOperation isCancelled]) {
                dispatch_semaphore_signal(semaphore);
                return;
            }

            // Delete events on success.
            [LPEventDataManager deleteEventsWithLimit:requestsToSend.count];

            // Send another request if the last request had maximum events per api call.
            if (requestsToSend.count == MAX_EVENTS_PER_API_CALL) {
                [self sendRequests:async];
            }

            [LPEventCallbackManager invokeSuccessCallbacksOnResponses:json
                                                             requests:requestsToSend
                                                            operation:operation];
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
        [engine enqueueOperation:op];
        dispatch_time_t dispatchTimeout = dispatch_time(DISPATCH_TIME_NOW, timeout*NSEC_PER_SEC);
        long status = dispatch_semaphore_wait(semaphore, dispatchTimeout);
        
        // Request timed out.
        if (status != 0) {
            LP_TRY
            NSLog(@"Leanplum: Request %@ timed out", self->_apiMethod);
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
    if (async) {
        [requestOperation addExecutionBlock:operationBlock];
        [[LPOperationQueue serialQueue] addOperation:requestOperation];
    } else {
        operationBlock();
    }
}

- (void)sendNow
{
    [self sendNow:YES];
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_now"];
}

- (void)sendNowSync
{
    [self sendNow:NO];
}

- (void)sendEventually:(BOOL)sync
{
    RETURN_IF_TEST_MODE;
    if (!_sent) {
        _sent = YES;

        void (^operationBlock)(void) = ^void() {
            LP_TRY
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString *uuid = [userDefaults objectForKey:LEANPLUM_DEFAULTS_UUID_KEY];
            NSInteger count = [LPEventDataManager count];
            if (!uuid || count % MAX_EVENTS_PER_API_CALL == 0) {
                uuid = [LeanplumRequest generateUUID];
            }

            NSMutableDictionary *args = [self createArgsDictionary];
            args[LP_PARAM_UUID] = uuid;
            
            [LPEventDataManager addEvent:args];

            [LPEventCallbackManager addEventCallbackAt:count
                                             onSuccess:self->_response
                                               onError:self->_error];
            LP_END_TRY
        };

        if (sync) {
            operationBlock();
        } else {
            [[LPOperationQueue serialQueue] addOperationWithBlock:operationBlock];
        }
    }
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_eventually"];
}

+ (NSString *)getSizeAsString:(int)size
{
    if (size < (1 << 10)) {
        return [NSString stringWithFormat:@"%d B", size];
    } else if (size < (1 << 20)) {
        return [NSString stringWithFormat:@"%d KB", (size >> 10)];
    } else {
        return [NSString stringWithFormat:@"%d MB", (size >> 20)];
    }
}

+ (void)printUploadProgress
{
    NSInteger totalFiles = [fileUploadSize count];
    int sentFiles = 0;
    int totalBytes = 0;
    int sentBytes = 0;
    for (NSString *filename in [fileUploadSize allKeys]) {
        int fileSize = [fileUploadSize[filename] intValue];
        double fileProgress = [fileUploadProgress[filename] doubleValue];
        if (fileProgress == 1) {
            sentFiles++;
        }
        sentBytes += (int)(fileSize * fileProgress);
        totalBytes += fileSize;
    }
    NSString *progressString = [NSString stringWithFormat:@"Uploading resources. %d/%ld files completed; %@/%@ transferred.",
                                sentFiles, (long) totalFiles,
                                [self getSizeAsString:sentBytes], [self getSizeAsString:totalBytes]];
    if (![fileUploadProgressString isEqualToString:progressString]) {
        fileUploadProgressString = progressString;
        NSLog(@"Leanplum: %@", progressString);
    }
}

- (void)maybeSendNextUpload
{
    NSMutableArray *filesToUpload;
    NSMutableDictionary *dict;
    NSString *url;
    @synchronized (pendingUploads) {
        for (NSMutableArray *item in pendingUploads) {
            filesToUpload = item;
            dict = pendingUploads[item];
            break;
        }
        if (dict) {
            if (!uploadUrl) {
                return;
            }
            url = uploadUrl;
            uploadUrl = nil;
            [pendingUploads removeObjectForKey:filesToUpload];
        }
    }
    if (dict == nil) {
        return;
    }
    id<LPNetworkOperationProtocol> op = [engine operationWithURLString:url
                                                                params:dict
                                                            httpMethod:_httpMethod
                                                        timeoutSeconds:60];
    
    int fileIndex = 0;
    for (NSString *filename in filesToUpload) {
        if (filename.length) {
            [op addFile:filename forKey:[NSString stringWithFormat:LP_PARAM_FILES_PATTERN, fileIndex]];
        }
        fileIndex++;
    }
    
    // Callbacks.
    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
        LP_TRY
        for (NSString *filename in filesToUpload) {
            if (filename.length) {
                fileUploadProgress[filename] = @(1.0);
            }
        }
        [LeanplumRequest printUploadProgress];
        LP_END_TRY
        if (self->_response != nil) {
            self->_response(operation, json);
        }
        LP_TRY
        @synchronized (pendingUploads) {
            uploadUrl = [[LPResponse getLastResponse:json]
                         objectForKey:LP_KEY_UPLOAD_URL];
        }
        [self maybeSendNextUpload];
        LP_END_TRY
     } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
         LP_TRY
         for (NSString *filename in filesToUpload) {
             if (filename.length) {
                 [fileUploadProgress setObject:@(1.0) forKey:filename];
             }
         }
         [LeanplumRequest printUploadProgress];
         NSLog(@"Leanplum: %@", err);
         if (self->_error != nil) {
             self->_error(err);
         }
         [self maybeSendNextUpload];
         LP_END_TRY
     }];
    [op onUploadProgressChanged:^(double progress) {
         LP_TRY
         for (NSString *filename in filesToUpload) {
             if (filename.length) {
                 [fileUploadProgress setObject:@(MIN(progress, 1.0)) forKey:filename];
             }
         }
         [LeanplumRequest printUploadProgress];
         LP_END_TRY
     }];
    
    // Send.
    [engine enqueueOperation: op];
}

- (void)sendDataNow:(NSData *)data forKey:(NSString *)key
{
    [self sendDatasNow:@{key: data}];
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_data_now"];
}

- (void)sendDatasNow:(NSDictionary *)datas
{
    NSMutableDictionary *dict = [self createArgsDictionary];
    [self attachApiKeys:dict];
    id<LPNetworkOperationProtocol> op =
    [engine operationWithPath:[LPConstantsState sharedState].apiServlet
                       params:dict
                   httpMethod:_httpMethod
                          ssl:[LPConstantsState sharedState].apiSSL
               timeoutSeconds:60];

    [datas enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [op addData:obj forKey:key];
    }];
    
    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
        if (self->_response != nil) {
            self->_response(operation, json);
        }
    } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
        LP_TRY
        if (self->_error != nil) {
            self->_error(err);
        }
        LP_END_TRY
    }];
    [engine enqueueOperation: op];
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_datas_now"];
}

- (void)sendFilesNow:(NSArray *)filenames
{
    RETURN_IF_TEST_MODE;
    NSMutableArray *filesToUpload = [NSMutableArray array];
    for (NSString *filename in filenames) {
        // Set state.
        if ([fileTransferStatus[filename] boolValue]) {
            [filesToUpload addObject:@""];
        } else {
            [filesToUpload addObject:filename];
            fileTransferStatus[filename] = @(YES);
            NSNumber *size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filename error:nil] objectForKey:NSFileSize];
            fileUploadSize[filename] = size;
            fileUploadProgress[filename] = @0.0;
        }
    }
    if (filesToUpload.count == 0) {
        return;
    }

    // Create request.
    NSMutableDictionary *dict = [self createArgsDictionary];
    dict[LP_PARAM_COUNT] = @(filesToUpload.count);
    [self attachApiKeys:dict];
    @synchronized (pendingUploads) {
        pendingUploads[filesToUpload] = dict;
    }
    [self maybeSendNextUpload];
 
    NSLog(@"Leanplum: Uploading files...");
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"send_files_now"];
}

- (void)downloadFile:(NSString *)path
{
    RETURN_IF_TEST_MODE;
    if ([fileTransferStatus[path] boolValue]) {
        return;
    }
    pendingDownloads++;
    NSLog(@"Leanplum: Downloading resource %@", path);
    fileTransferStatus[path] = @(YES);

    id<LPNetworkOperationProtocol> op = [self operationForDownloadFile:path];
    [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
        LP_TRY
        [[operation responseData] writeToFile:[LPFileManager fileRelativeToDocuments:path
                                              createMissingDirectories:YES] atomically:YES];
        pendingDownloads--;
        if (self->_response != nil) {
            self->_response(operation, json);
        }
        if (pendingDownloads == 0 && noPendingDownloadsBlock) {
            noPendingDownloadsBlock();
        }
        LP_END_TRY
    } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
        LP_TRY
        NSLog(@"Leanplum: %@", err);
        pendingDownloads--;
        if (self->_error != nil) {
            self->_error(err);
        }
        if (pendingDownloads == 0 && noPendingDownloadsBlock) {
            noPendingDownloadsBlock();
        }
        LP_END_TRY
    }];
    [engine enqueueOperation: op];
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"download_file"];
}

- (id<LPNetworkOperationProtocol>)operationForDownloadFile:(NSString *)path {
    // Download it directly if the argument is URL.
    // Otherwise look up the URL in the filenameToURLs dictionary.
    // Otherwise continue with the api request.
    id<LPNetworkOperationProtocol> op;
    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) {
        op = [engine operationWithURLString:path];
    } else if ([[LPFileTransferManager sharedInstance].filenameToURLs valueForKey:path]) {
        op = [engine operationWithURLString:[[LPFileTransferManager sharedInstance].filenameToURLs valueForKey:path]];
    } else {
        NSMutableDictionary *dict = [self createArgsDictionary];
        dict[LP_KEY_FILENAME] = path;
        [self attachApiKeys:dict];
        op = [engine operationWithPath:[LPConstantsState sharedState].apiServlet
                                params:dict
                            httpMethod:[LPNetworkFactory fileRequestMethod]
                                   ssl:[LPConstantsState sharedState].apiSSL
                        timeoutSeconds:[LPConstantsState sharedState]
              .networkTimeoutSecondsForDownloads];
    }
    return op;
}

+ (int)numPendingDownloads
{
    return pendingDownloads;
}

+ (void)onNoPendingDownloads:(LeanplumVariablesChangedBlock)block
{
    noPendingDownloadsBlock = block;
}

@synthesize apiMethod;

@synthesize errorBlock;

@synthesize params;

@synthesize responseBlock;

@synthesize sent;

@end
