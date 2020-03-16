//
//  LPKeychainWrapper.m
//  Leanplum
//
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

#import "LPKeychainWrapper.h"
#import <Security/Security.h>
#include <CommonCrypto/CommonCryptor.h>


static NSString *KeychainWrapperErrorDomain = @"KeychainWrapperErrorDomain";

@implementation LPKeychainWrapper

+ (NSString *) getPasswordForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error {
    if (!username || !serviceName) {
        if (error != nil) {
            *error = [NSError errorWithDomain: KeychainWrapperErrorDomain code: -2000 userInfo: nil];
        }
        return nil;
    }
    
    if (error != nil) {
        *error = nil;
    }
    
    // Set up a query dictionary with the base query attributes: item type (generic), username, and service
    
    NSArray *keys = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClass, kSecAttrAccount, kSecAttrService, nil];
    NSArray *objects = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClassGenericPassword, username, serviceName, nil];
    
    NSMutableDictionary *query = [[NSMutableDictionary alloc] initWithObjects: objects forKeys: keys];
    
    // First do a query for attributes, in case we already have a Keychain item with no password data set.
    // One likely way such an incorrect item could have come about is due to the previous (incorrect)
    // version of this code (which set the password as a generic attribute instead of password data).
    
    NSMutableDictionary *attributeQuery = [query mutableCopy];
    attributeQuery[(__bridge_transfer id) kSecReturnAttributes] = (id) kCFBooleanTrue;
    CFTypeRef attrResult = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) attributeQuery, &attrResult);
    
    if (status != noErr) {
        // No existing item found--simply return nil for the password
        if (error != nil && status != errSecItemNotFound) {
            //Only return an error if a real exception happened--not simply for "not found."
            *error = [NSError errorWithDomain: KeychainWrapperErrorDomain code: status userInfo: nil];
        }
        
        return nil;
    }
    CFRelease(attrResult);

    // We have an existing item, now query for the password data associated with it.
    
    NSMutableDictionary *passwordQuery = [query mutableCopy];
    passwordQuery[(__bridge_transfer id) kSecReturnData] = (id) kCFBooleanTrue;
    CFTypeRef resData = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef) passwordQuery, (CFTypeRef *) &resData);
    NSData *resultData = (__bridge_transfer NSData *)resData;
    
    if (status != noErr) {
        if (status == errSecItemNotFound) {
            // We found attributes for the item previously, but no password now, so return a special error.
            // Users of this API will probably want to detect this error and prompt the user to
            // re-enter their credentials.  When you attempt to store the re-entered credentials
            // using storeUsername:andPassword:forServiceName:updateExisting:error
            // the old, incorrect entry will be deleted and a new one with a properly encrypted
            // password will be added.
            if (error != nil) {
                *error = [NSError errorWithDomain: KeychainWrapperErrorDomain code: -1999 userInfo: nil];
            }
        }
        else {
            // Something else went wrong. Simply return the normal Keychain API error code.
            if (error != nil) {
                *error = [NSError errorWithDomain: KeychainWrapperErrorDomain code: status userInfo: nil];
            }
        }
        
        return nil;
    }
    
    NSString *password = nil;
    
    if (resultData) {
        password = [[NSString alloc] initWithData: resultData encoding: NSUTF8StringEncoding];
    }
    else {
        // There is an existing item, but we weren't able to get password data for it for some reason,
        // Possibly as a result of an item being incorrectly entered by the previous code.
        // Set the -1999 error so the code above us can prompt the user again.
        if (error != nil) {
            *error = [NSError errorWithDomain: KeychainWrapperErrorDomain code: -1999 userInfo: nil];
        }
    }
    
    return password;
}

+ (BOOL) storeUsername: (NSString *) username andPassword: (NSString *) password forServiceName: (NSString *) serviceName updateExisting: (BOOL) updateExisting error: (NSError **) error
{
    if (!username || !password || !serviceName) {
        if (error != nil) {
            *error = [NSError errorWithDomain: KeychainWrapperErrorDomain code: -2000 userInfo: nil];
        }
        return NO;
    }
    
    // See if we already have a password entered for these credentials.
    NSError *getError = nil;
    NSString *existingPassword = [LPKeychainWrapper getPasswordForUsername: username andServiceName: serviceName error:&getError];
    
    if ([getError code] == -1999) {
        // There is an existing entry without a password properly stored (possibly as a result of the previous incorrect version of this code.
        // Delete the existing item before moving on entering a correct one.
        
        getError = nil;
        
        [self deleteItemForUsername: username andServiceName: serviceName error: &getError];
        
        if ([getError code] != noErr) {
            if (error != nil) {
                *error = getError;
            }
            return NO;
        }
    }
    else if ([getError code] != noErr) {
        if (error != nil) {
            *error = getError;
        }
        return NO;
    }
    
    if (error != nil) {
        *error = nil;
    }
    
    OSStatus status = noErr;
    
    if (existingPassword) {
        // We have an existing, properly entered item with a password.
        // Update the existing item.
        
        if (![existingPassword isEqualToString:password] && updateExisting) {
            //Only update if we're allowed to update existing.  If not, simply do nothing.
            
            NSArray *keys = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClass,
                             kSecAttrService,
                             kSecAttrLabel,
                             kSecAttrAccount,
                             nil];
            
            NSArray *objects = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClassGenericPassword,
                                serviceName,
                                serviceName,
                                username,
                                nil];
            
            NSDictionary *query = [[NSDictionary alloc] initWithObjects: objects forKeys: keys];
            
            status = SecItemUpdate((__bridge CFDictionaryRef) query, (__bridge CFDictionaryRef) [NSDictionary dictionaryWithObject: [password dataUsingEncoding: NSUTF8StringEncoding] forKey: (__bridge_transfer NSString *) kSecValueData]);
        }
    } else {
        // No existing entry (or an existing, improperly entered, and therefore now
        // deleted, entry).  Create a new entry.
        
        NSArray *keys = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClass,
                         kSecAttrService,
                         kSecAttrLabel,
                         kSecAttrAccount,
                         kSecValueData,
                         nil];
        
        NSArray *objects = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClassGenericPassword,
                            serviceName,
                            serviceName,
                            username,
                            [password dataUsingEncoding: NSUTF8StringEncoding],
                            nil];
        
        NSDictionary *query = [[NSDictionary alloc] initWithObjects: objects forKeys: keys];
        
        status = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
    }
    
    if (error != nil && status != noErr) {
        // Something went wrong with adding the new item. Return the Keychain error code.
        *error = [NSError errorWithDomain: KeychainWrapperErrorDomain code: status userInfo: nil];
        
        return NO;
    }
    
    return YES;
}

+ (BOOL) deleteItemForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error
{
    if (!username || !serviceName) {
        if (error != nil) {
            *error = [NSError errorWithDomain: KeychainWrapperErrorDomain code: -2000 userInfo: nil];
        }
        return NO;
    }
    
    if (error != nil) {
        *error = nil;
    }
    
    NSArray *keys = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClass, kSecAttrAccount, kSecAttrService, kSecReturnAttributes, nil];
    NSArray *objects = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClassGenericPassword, username, serviceName, kCFBooleanTrue, nil];
    
    NSDictionary *query = [[NSDictionary alloc] initWithObjects: objects forKeys: keys];
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef) query);
    
    if (error != nil && status != noErr) {
        *error = [NSError errorWithDomain: KeychainWrapperErrorDomain code: status userInfo: nil];
        return NO;
    }
    
    return YES;
}

+ (NSData*)AES256Encrypt:(NSData*)data withKey:(NSString*)key
{
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize           = dataLength + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t numBytesEncrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

+ (NSData *)cipherData:(NSData *)data withKey:(NSData*)cipherKey {
    return [self aesOperation:kCCEncrypt OnData:data withKey:cipherKey];
}

+ (NSData *)decipherData:(NSData *)data withKey:(NSData*)cipherKey {
    return [self aesOperation:kCCDecrypt OnData:data withKey:cipherKey];
}

+ (NSData *)cipherString:(NSString *)data withKey:(NSString*)cipherKey {
    return [self aesOperation:kCCEncrypt OnData:[data dataUsingEncoding:NSUTF8StringEncoding] withKey:[cipherKey dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString *)decipherString:(NSData *)data withKey:(NSString*)cipherKey {
    return [[NSString alloc] initWithData:[self aesOperation:kCCDecrypt OnData:data withKey:[cipherKey dataUsingEncoding:NSUTF8StringEncoding]] encoding:NSUTF8StringEncoding];
}

+ (NSData *)aesOperation:(CCOperation)op OnData:(NSData *)data withKey:(NSData*)cipherKey {
    NSData *outData = nil;
    
    // Data in parameters
    const void *key = cipherKey.bytes;
    const void *dataIn = data.bytes;
    size_t dataInLength = data.length;
    // Data out parameters
    size_t outMoved = 0;
    
    // Init out buffer
    const int BUFFER_SIZE = 1024;
    unsigned char outBuffer[BUFFER_SIZE];
    memset(outBuffer, 0, BUFFER_SIZE);
    CCCryptorStatus status = -1;
    
    status = CCCrypt(op, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key, kCCKeySizeAES256, NULL,
                     dataIn, dataInLength, &outBuffer, BUFFER_SIZE, &outMoved);
    
    if(status == kCCSuccess) {
        outData = [NSData dataWithBytes:outBuffer length:outMoved];
    } else if(status == kCCBufferTooSmall) {
        // Resize the out buffer
        //size_t newsSize = outMoved;
        //void *dynOutBuffer = malloc(newsSize);
        //memset(dynOutBuffer, 0, newsSize);
        outMoved = 0;
        
        status = CCCrypt(op, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key, kCCKeySizeAES256, NULL,
                         dataIn, dataInLength, &outBuffer, BUFFER_SIZE, &outMoved);
        
        if(status == kCCSuccess) {
            outData = [NSData dataWithBytes:outBuffer length:outMoved];
        }
    }
    
    return outData; 
}

@end
