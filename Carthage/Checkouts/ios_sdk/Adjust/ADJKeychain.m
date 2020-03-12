//
//  ADJKeychain.m
//  Adjust
//
//  Created by Uglješa Erceg on 25/08/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJLogger.h"
#import "ADJKeychain.h"
#import "ADJAdjustFactory.h"
#include <dlfcn.h>

@implementation ADJKeychain

#pragma mark - Object lifecycle methods

+ (id)getInstance {
    static ADJKeychain *defaultInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        defaultInstance = [[self alloc] init];
    });

    return defaultInstance;
}

- (id)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    return self;
}

#pragma mark - Public methods

+ (BOOL)setValue:(NSString *)value forKeychainKey:(NSString *)key inService:(NSString *)service {
    if (key == nil) {
        return NO;
    }

    return [[ADJKeychain getInstance] setValue:value forKeychainKey:key inService:service];
}

+ (NSString *)valueForKeychainKey:(NSString *)key service:(NSString *)service {
    if (key == nil) {
        return nil;
    }

    return [[ADJKeychain getInstance] valueForKeychainKey:key service:service];
}

#pragma mark - Set Keychain item value

- (BOOL)setValue:(NSString *)value forKeychainKey:(NSString *)key inService:(NSString *)service {
    OSStatus status = [self setValueWithStatus:value forKeychainKey:key inService:service];

    if (status != noErr) {
        [[ADJAdjustFactory logger] warn:@"Value unsuccessfully written to the keychain"];
        return NO;
    } else {
        // Check was writing successful.
        BOOL wasSuccessful = [self wasWritingSuccessful:value forKeychainKey:key inService:service];

        if (wasSuccessful) {
            [[ADJAdjustFactory logger] warn:@"Value successfully written to the keychain"];
        }

        return wasSuccessful;
    }
}

- (OSStatus)setValueWithStatus:(NSString *)value forKeychainKey:(NSString *)key inService:(NSString *)service {
    NSMutableDictionary *keychainItem;
    
    keychainItem = [self keychainItemForKey:key service:service];
    keychainItem[(__bridge id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
    
    return SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
}

#pragma mark - Get Keychain item value

- (NSString *)valueForKeychainKey:(NSString *)key service:(NSString *)service {
    NSMutableDictionary *keychainItem = [self keychainItemForKey:key service:service];
    return [self valueForKeychainItem:keychainItem key:key service:service];
}

- (NSString *)valueForKeychainItem:(NSMutableDictionary *)keychainItem key:(NSString *)key service:(NSString *)service {
    if (!keychainItem) {
        return nil;
    }

    keychainItem[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    keychainItem[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;

    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result);
    if (status != noErr) {
        return nil;
    }

    NSDictionary *resultDict = (__bridge_transfer NSDictionary *)result;
    NSData *data = resultDict[(__bridge id)kSecValueData];
    if (!data) {
        return nil;
    }

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - Build Keychain item

- (NSMutableDictionary *)keychainItemForKey:(NSString *)key service:(NSString *)service {
    NSMutableDictionary *keychainItem = [[NSMutableDictionary alloc] init];

    keychainItem[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    [self keychainItemForKey:keychainItem key:key service:service];

    return keychainItem;
}

- (void)keychainItemForKey:(NSMutableDictionary *)keychainItem key:(NSString *)key service:(NSString *)service {
    keychainItem[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    keychainItem[(__bridge id)kSecAttrAccount] = key;
    keychainItem[(__bridge id)kSecAttrService] = service;
}

#pragma mark - Writing validation

- (BOOL)wasWritingSuccessful:(NSString *)value forKeychainKey:(NSString *)key inService:(NSString *)service {
    NSString *writtenValue = [self valueForKeychainKey:key service:service];
    if ([writtenValue isEqualToString:value]) {
        return YES;
    } else {
        return NO;
    }
}

@end
