//
//  LPNetworkOperation.m
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

#import "LPNetworkOperation.h"
#import "LPNetworkEngine.h"
#import "LeanplumInternal.h"

@interface LPNetworkOperation()

@property (nonatomic, strong) LPNetworkResponseBlock responseBlock;
@property (nonatomic, strong) LPNetworkResponseErrorBlock errorBlock;
@property (nonatomic, strong) LPNetworkProgressBlock uploadProgressBlock;

@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSData *dataFromResponse;

@property (nonatomic, strong) NSMutableArray *requestDatas;
@property (nonatomic, strong) NSMutableArray *requestFiles;

@end

@implementation LPNetworkOperation

- (id)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
                           request:(NSMutableURLRequest *)request
                             param:(NSDictionary *)param
{
    if (self = [self init]) {
        self.session = [NSURLSession sessionWithConfiguration:configuration
                                                     delegate:self delegateQueue:nil];
        self.request = request;
        self.requestDatas = [NSMutableArray new];
        self.requestFiles = [NSMutableArray new];
        self.requestParam = param;
    }
    return self;
}

- (void)dealloc
{
    [self.session invalidateAndCancel];
}

- (void)addCompletionHandler:(LPNetworkResponseBlock)response
                errorHandler:(LPNetworkResponseErrorBlock)error
{
    self.responseBlock = response;
    self.errorBlock = error;
}

- (void)onUploadProgressChanged:(LPNetworkProgressBlock)uploadProgressBlock
{
    self.uploadProgressBlock = uploadProgressBlock;
}

- (NSInteger)HTTPStatusCode
{
    if (!self.response) {
        LPLog(LPWarning, @"No response from %@. Make sure to call in the callback",
              self.request.URL.absoluteString);
        return 0;
    }

    if ([self.response isKindOfClass:[NSHTTPURLResponse class]]) {
        return [(NSHTTPURLResponse *)self.response statusCode];
    }

    return 0;
}

- (id)responseJSON
{
    if (!self.dataFromResponse) {
        LPLog(LPWarning, @"No response data from %@. Make sure to call in the callback",
              self.request.URL.absoluteString);
        return @{};
    }
    return [LPJSON JSONFromData:self.dataFromResponse];
}

- (NSData *)responseData
{
    if (!self.dataFromResponse) {
        LPLog(LPWarning, @"No response data from %@. Make sure to call in the callback",
              self.request.URL.absoluteString);
    }
    return self.dataFromResponse;
}

- (NSString *)responseString
{
    if (!self.dataFromResponse) {
        LPLog(LPWarning, @"No response data from %@. Make sure to call in the callback",
              self.request.URL.absoluteString);
        return @"";
    }
    return [[NSString alloc] initWithData:self.dataFromResponse encoding:NSUTF8StringEncoding];
}

- (void)addFile:(NSString *)filePath forKey:(NSString *)key
{
    [self.request setHTTPMethod:@"POST"];
    NSDictionary *object = @{@"filepath":filePath, @"name":key,
                          @"mimetype":@"application/octet-stream"};
    [self.requestFiles addObject:object];
}

- (void)addData:(NSData *)data forKey:(NSString *)key
{
    [self.request setHTTPMethod:@"POST"];
    NSDictionary *object = @{@"data":data, @"name":key, @"mimetype":@"application/octet-stream",
                             @"filename":@"file"};
    [self.requestDatas addObject:object];
}

- (void)cancel
{
    if (self.task) {
        [self.task suspend];
    }
    [self.session finishTasksAndInvalidate];
}

- (void)run
{
    [self runSynchronously:NO];
}

- (void)runSynchronously:(BOOL)synchronous
{
    dispatch_semaphore_t sem;
    if (synchronous) {
        sem = dispatch_semaphore_create(0);
    }

    // Response Block
    void (^responseBlock)(NSData *, NSURLResponse *, NSError *) =
            ^(NSData *data, NSURLResponse *response, NSError *error) {

        void (^callbackBlock)(void) = ^(){
            self.response = response;
            self.dataFromResponse = data;

            if (synchronous) {
                dispatch_semaphore_signal(sem);
            }
            
            // Handle unsuccessful http response code.
            NSError *responseError = error;
            if (!responseError && [self HTTPStatusCode] != 200) {
                responseError = [NSError errorWithDomain:NSURLErrorDomain
                                                    code:[self HTTPStatusCode]
                                                userInfo:nil];
            }

            if (responseError) {
                if (self.errorBlock) {
                    self.errorBlock(self, responseError);
                }
            } else {
                if (self.responseBlock) {
                    self.responseBlock(self, [self responseJSON]);
                }
            }
            [self.session finishTasksAndInvalidate];
        };

        // Callback on the main queue
        if ([NSThread isMainThread] || synchronous) {
            callbackBlock();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock();
            });
        }
    };

    // Use Upload Task for file & data upload, Data Task for others
    self.request.HTTPBody = [self bodyData];
    if (self.requestFiles.count || self.requestDatas.count) {
        self.task = [self.session uploadTaskWithRequest:self.request fromData:nil completionHandler:
                     ^(NSData * _Nullable data, NSURLResponse * _Nullable response,
                       NSError * _Nullable error) {
            responseBlock(data, response, error);
        }];
    } else {
        self.task = [self.session dataTaskWithRequest:self.request completionHandler:
                     ^(NSData *data, NSURLResponse *response, NSError *error) {
            responseBlock(data, response, error);
        }];
    }

    // Run
    [self.task resume];

    if (synchronous) {
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
}

/**
 * Creates body data using parameters, files, and data.
 * NSURLSession doesn't support multi-form upload out of the box.
 * Borrowed from MKNetworkKit for simplicity.
 */
- (NSData *)bodyData
{
    if (self.requestFiles.count == 0 && self.requestDatas.count == 0) {
        NSMutableString *bodyString = [NSMutableString string];
        for (NSString *key in self.requestParam) {
            NSObject *value = [self.requestParam valueForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                [bodyString appendFormat:@"%@=%@&", [self urlEncodedString:key],
                 [self urlEncodedString:(NSString *)value]];
            } else {
                [bodyString appendFormat:@"%@=%@&", [self urlEncodedString:key], value];
            }
        }

        if (bodyString.length > 0) {
            [bodyString deleteCharactersInRange:NSMakeRange(bodyString.length - 1, 1)];
        }
        return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    }

    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSMutableData *body = [NSMutableData data];
    __block NSUInteger postLength = 0;

    [self.requestParam enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *fieldString = [NSString stringWithFormat:
                                @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
                                boundary, key, obj];
        [body appendData:[fieldString dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];

    [self.requestFiles enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSString *fieldString = [NSString stringWithFormat:
                                @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; "
                                @"filename=\"%@\"\r\nContent-Type: %@\r\n"
                                @"Content-Transfer-Encoding: binary\r\n\r\n",
                                boundary, obj[@"name"], [obj[@"filepath"] lastPathComponent],
                                obj[@"mimetype"]];
        [body appendData:[fieldString dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData: [NSData dataWithContentsOfFile:obj[@"filepath"]]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];

    [self.requestDatas enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSString *fieldString = [NSString stringWithFormat:
                                @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; "
                                @"filename=\"%@\"\r\nContent-Type: %@\r\n"
                                @"Content-Transfer-Encoding: binary\r\n\r\n",
                                boundary, obj[@"name"], obj[@"filename"], obj[@"mimetype"]];
        [body appendData:[fieldString dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:obj[@"data"]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];

    if (postLength >= 1)
        [self.request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postLength]
            forHTTPHeaderField:@"content-length"];

    [body appendData: [[NSString stringWithFormat:@"--%@--\r\n", boundary]
                       dataUsingEncoding:NSUTF8StringEncoding]];

    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName
            (CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));

    if (self.requestFiles.count || self.requestDatas.count) {
        [self.request setValue:[NSString stringWithFormat:
                                @"multipart/form-data; charset=%@; boundary=%@",
                                charset, boundary]
            forHTTPHeaderField:@"Content-Type"];

        [self.request setValue:[NSString stringWithFormat:@"%d", (unsigned)[body length]]
            forHTTPHeaderField:@"Content-Length"];
    }

    return body;
}

/**
 * This method is used by bodyData to encode string.
 * Borrowed from MKNetworkKit.
 */
- (NSString *)urlEncodedString:(NSString *)string
{
    CFStringRef encodedCFString = CFURLCreateStringByAddingPercentEscapes
            (kCFAllocatorDefault, (__bridge CFStringRef) string, nil,
             CFSTR("?!@#$^&%*+,:;='\"`<>()[]{}/\\| "), kCFStringEncodingUTF8);
    NSString *encodedString = [[NSString alloc] initWithString:
                               (__bridge_transfer NSString*) encodedCFString];
    if (!encodedString) {
        encodedString = @"";
    }
    return encodedString;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    if (task != self.task || totalBytesExpectedToSend == NSURLSessionTransferSizeUnknown) {
        return;
    }

    if (self.uploadProgressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.uploadProgressBlock( (double)totalBytesSent/totalBytesExpectedToSend );
        });
    }
}

+ (NSString *)fileRequestMethod;
{
    return @"POST";
}

@end
