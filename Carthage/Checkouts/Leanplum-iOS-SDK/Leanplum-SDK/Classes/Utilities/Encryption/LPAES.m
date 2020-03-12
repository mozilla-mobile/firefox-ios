//
//  LPAES.m
//  Leanplum
//
//  Created by Alexis Oyama on 4/25/17.
//  Copyright (c) 2017 Leanplum, Inc. All rights reserved.
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

#import "LPAES.h"
#import "LPConstants.h"
#import "LeanplumRequest.h"
#import <CommonCrypto/CommonCryptor.h>
#import "LPAPIConfig.h"

@implementation LPAES

+ (NSData *)encryptedDataFromData:(NSData *)data;
{
    return [LPAES AES128WithOperation:kCCEncrypt
                                  key:[LPAPIConfig sharedConfig].token
                           identifier:LP_IV
                                 data:data];
}

+ (NSData *)decryptedDataFromData:(NSData *)data
{
    return [LPAES AES128WithOperation:kCCDecrypt
                                  key:[LPAPIConfig sharedConfig].token
                           identifier:LP_IV
                                 data:data];
}

+ (NSData *)AES128WithOperation:(CCOperation)operation
                            key:(NSString *)key
                     identifier:(NSString *)identifier
                           data:(NSData *)data
{
    // Note: The key will be 0's but we intentionally are keeping it this way to maintain
    // compatibility. The correct code is:
    // char keyPtr[[key length] + 1];
    char keyCString[kCCKeySizeAES128 + 1];
    memset(keyCString, 0, sizeof(keyCString));
    [key getCString:keyCString maxLength:sizeof(keyCString) encoding:NSUTF8StringEncoding];

    char identifierCString[kCCBlockSizeAES128 + 1];
    memset(identifierCString, 0, sizeof(identifierCString));
    [identifier getCString:identifierCString
                 maxLength:sizeof(identifierCString)
                  encoding:NSUTF8StringEncoding];

    size_t outputAvailableSize = [data length] + kCCBlockSizeAES128;
    void *output = malloc(outputAvailableSize);

    size_t outputMovedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          keyCString,
                                          kCCBlockSizeAES128,
                                          identifierCString,
                                          [data bytes],
                                          [data length],
                                          output,
                                          outputAvailableSize,
                                          &outputMovedSize);

    if (cryptStatus != kCCSuccess) {
        free(output);
        return nil;
    }

    return [NSData dataWithBytesNoCopy:output length:outputMovedSize];
}

@end
