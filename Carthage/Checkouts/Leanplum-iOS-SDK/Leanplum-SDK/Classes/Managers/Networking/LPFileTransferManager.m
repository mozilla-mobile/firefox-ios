//
//  LPFileTransferManager.m
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/1/19.
//  Copyright © 2019 Leanplum. All rights reserved.
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

#import "LPFileTransferManager.h"
#import "LeanplumInternal.h"
#import "LPRequest.h"
#import "LeanplumRequest.h"
#import "LPRequestSender.h"
#import "LPRequestFactory.h"
#import "LPResponse.h"
#import "LPFileManager.h"
#import "LPUtils.h"

@interface LPFileTransferManager()

@property (nonatomic, strong) NSMutableDictionary *fileTransferStatus;

@property (nonatomic, strong) NSMutableDictionary *fileUploadSize;
@property (nonatomic, strong) NSMutableDictionary *fileUploadProgress;
@property (nonatomic, strong) NSString *fileUploadProgressString;
@property (nonatomic, strong) NSMutableDictionary *pendingUploads;
@property (nonatomic, strong) NSDictionary *requestHeaders;

@property (nonatomic, assign) int pendingDownloads;
@property (nonatomic, strong) LeanplumVariablesChangedBlock noPendingDownloadsBlock;

@property (nonatomic, strong) id<LPNetworkEngineProtocol> engine;

@end


@implementation LPFileTransferManager

+ (instancetype)sharedInstance {
    static LPFileTransferManager *sharedManager = nil;
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
        _fileTransferStatus = [[NSMutableDictionary alloc] init];
        _fileUploadSize = [NSMutableDictionary dictionary];
        _fileUploadProgress = [NSMutableDictionary dictionary];
        _pendingUploads = [NSMutableDictionary dictionary];

        if (_engine == nil) {
            if (!_requestHeaders) {
                _requestHeaders = [LPUtils createHeaders];
            }
            _engine = [LPNetworkFactory engineWithHostName:[LPConstantsState sharedState].apiHostName
                                        customHeaderFields:_requestHeaders];
        }

    }
    return self;
}

- (void)sendFilesNow:(NSArray *)filenames fileData:(NSArray *)fileData
{
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory uploadFileWithParams:@{LP_PARAM_DATA: [LPJSON stringFromJSON:fileData]}];
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldRequest = [reqFactory uploadFileWithParams:@{LP_PARAM_DATA: [LPJSON stringFromJSON:fileData]}];
        [oldRequest sendFilesNow:filenames];
    } else {
        NSMutableDictionary *dict = [[LPRequestSender sharedInstance] createArgsDictionaryForRequest:request];

        RETURN_IF_TEST_MODE;
        NSMutableArray *filesToUpload = [NSMutableArray array];
        dict[LP_PARAM_COUNT] = @(filesToUpload.count);
        [[LPRequestSender sharedInstance] attachApiKeys:dict];

        for (NSString *filename in filenames) {
            // Set state.
            if ([self.fileTransferStatus[filename] boolValue]) {
                [filesToUpload addObject:@""];
            } else {
                [filesToUpload addObject:filename];
                self.fileTransferStatus[filename] = @(YES);
                NSNumber *size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filename error:nil] objectForKey:NSFileSize];
                self.fileUploadSize[filename] = size;
                self.fileUploadProgress[filename] = @0.0;
            }
        }
        if (filesToUpload.count == 0) {
            return;
        }
        @synchronized (self.pendingUploads) {
            self.pendingUploads[filesToUpload] = dict;
        }
        [self maybeSendNextUpload];

        NSLog(@"Leanplum: Uploading files...");
    }
}

- (void)printUploadProgress
{
    NSInteger totalFiles = [self.fileUploadSize count];
    int sentFiles = 0;
    int totalBytes = 0;
    int sentBytes = 0;
    for (NSString *filename in [self.fileUploadSize allKeys]) {
        int fileSize = [self.fileUploadSize[filename] intValue];
        double fileProgress = [self.fileUploadProgress[filename] doubleValue];
        if (fileProgress == 1) {
            sentFiles++;
        }
        sentBytes += (int)(fileSize * fileProgress);
        totalBytes += fileSize;
    }
    NSString *progressString = [NSString stringWithFormat:@"Uploading resources. %d/%ld files completed; %@/%@ transferred.",
                                sentFiles, (long) totalFiles,
                                [self getSizeAsString:sentBytes], [self getSizeAsString:totalBytes]];
    if (![self.fileUploadProgressString isEqualToString:progressString]) {
        self.fileUploadProgressString = progressString;
        NSLog(@"Leanplum: %@", progressString);
    }
}

- (void)maybeSendNextUpload
{
    NSMutableArray *filesToUpload;
    NSMutableDictionary *dict;
    NSString *url;
    @synchronized (self.pendingUploads) {
        for (NSMutableArray *item in self.pendingUploads) {
            filesToUpload = item;
            dict = self.pendingUploads[item];
            break;
        }
        if (dict) {
            if (!self.uploadUrl) {
                return;
            }
            url = self.uploadUrl;
            self.uploadUrl = nil;
            [self.pendingUploads removeObjectForKey:filesToUpload];
        }
    }
    if (dict == nil) {
        return;
    }
    id<LPNetworkOperationProtocol> op = [self.engine operationWithURLString:url
                                                                     params:dict
                                                                 httpMethod:@"POST"
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
                self.fileUploadProgress[filename] = @(1.0);
            }
        }
        [self printUploadProgress];
        LP_END_TRY
        LP_TRY
        @synchronized (self.pendingUploads) {
            self.uploadUrl = [[LPResponse getLastResponse:json]
                              objectForKey:LP_KEY_UPLOAD_URL];
        }
        [self maybeSendNextUpload];
        LP_END_TRY
    } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
        LP_TRY
        for (NSString *filename in filesToUpload) {
            if (filename.length) {
                [self.fileUploadProgress setObject:@(1.0) forKey:filename];
            }
        }
        [self printUploadProgress];
        NSLog(@"Leanplum: %@", err);
        [self maybeSendNextUpload];
        LP_END_TRY
    }];
    [op onUploadProgressChanged:^(double progress) {
        LP_TRY
        for (NSString *filename in filesToUpload) {
            if (filename.length) {
                [self.fileUploadProgress setObject:@(MIN(progress, 1.0)) forKey:filename];
            }
        }
        [self printUploadProgress];
        LP_END_TRY
    }];

    // Send.
    [self.engine enqueueOperation: op];
}

- (NSString *)getSizeAsString:(int)size
{
    if (size < (1 << 10)) {
        return [NSString stringWithFormat:@"%d B", size];
    } else if (size < (1 << 20)) {
        return [NSString stringWithFormat:@"%d KB", (size >> 10)];
    } else {
        return [NSString stringWithFormat:@"%d MB", (size >> 20)];
    }
}

- (void)downloadFile:(NSString *)path onResponse:(LPNetworkResponseBlock)responseBlock onError:(LPNetworkErrorBlock)errorBlock
{
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory downloadFileWithParams:nil];
    if ([request isKindOfClass:[LeanplumRequest class]]) {
        LeanplumRequest *oldRequest = request;
        [oldRequest onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
            if (responseBlock) {
                responseBlock(operation, json);
            }
        }];
        [oldRequest onError:^(NSError *op) {
            if (errorBlock) {
                errorBlock(op);
            }
        }];
        [oldRequest downloadFile:path];
    } else {
        NSMutableDictionary *dict = [[LPRequestSender sharedInstance] createArgsDictionaryForRequest:request];
        dict[LP_KEY_FILENAME] = path;

        RETURN_IF_TEST_MODE;
        if ([self.fileTransferStatus[path] boolValue]) {
            return;
        }
        self.pendingDownloads++;
        NSLog(@"Leanplum: Downloading resource %@", path);
        self.fileTransferStatus[path] = @(YES);

        [[LPRequestSender sharedInstance] attachApiKeys:dict];

        // Download it directly if the argument is URL.
        // Otherwise continue with the api request.
        id<LPNetworkOperationProtocol> op;
        if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) {
            op = [self.engine operationWithURLString:path];
        } else if ([self.filenameToURLs valueForKey:path]) {
            op = [self.engine operationWithURLString:[self.filenameToURLs valueForKey:path]];
        } else {
            op = [self.engine operationWithPath:[LPConstantsState sharedState].apiServlet
                                         params:dict
                                     httpMethod:[LPNetworkFactory fileRequestMethod]
                                            ssl:[LPConstantsState sharedState].apiSSL
                                 timeoutSeconds:[LPConstantsState sharedState]
                  .networkTimeoutSecondsForDownloads];
        }

        [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
            LP_TRY
            [[operation responseData] writeToFile:[LPFileManager fileRelativeToDocuments:path
                                                                createMissingDirectories:YES] atomically:YES];
            self.pendingDownloads--;
            if (responseBlock != nil) {
                responseBlock(operation, json);
            }
            if (self.pendingDownloads == 0 && self.noPendingDownloadsBlock) {
                self.noPendingDownloadsBlock();
            }
            LP_END_TRY
        } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *err) {
            LP_TRY
            NSLog(@"Leanplum: %@", err);
            self.pendingDownloads--;
            if (errorBlock != nil) {
                errorBlock(err);
            }
            if (self.pendingDownloads == 0 && self.noPendingDownloadsBlock) {
                self.noPendingDownloadsBlock();
            }
            LP_END_TRY
        }];
        [self.engine enqueueOperation: op];
    }
}

- (int)numPendingDownloads
{
    return _pendingDownloads;
}

- (void)onNoPendingDownloads:(LeanplumVariablesChangedBlock)noPendingDownloadsBlock
{
    self.noPendingDownloadsBlock = noPendingDownloadsBlock;
}


@end
