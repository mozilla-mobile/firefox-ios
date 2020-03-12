//
//  SentryDsn.m
//  Sentry
//
//  Created by Daniel Griesser on 03/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryDsn.h>
#import <Sentry/SentryClient.h>
#import <Sentry/SentryError.h>

#else
#import "SentryDsn.h"
#import "SentryClient.h"
#import "SentryError.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SentryDsn ()

@end

@implementation SentryDsn

- (_Nullable instancetype)initWithString:(NSString *)dsnString didFailWithError:(NSError *_Nullable *_Nullable)error {
    self = [super init];
    if (self) {
        self.url = [self convertDsnString:dsnString didFailWithError:error];
        if (nil != error && nil != *error) {
            return nil;
        }
    }
    return self;
}

- (NSString *)getHash {
    NSData *data = [[self.url absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

- (NSURL *_Nullable)convertDsnString:(NSString *)dsnString didFailWithError:(NSError *_Nullable *_Nullable)error {
    NSString *trimmedDsnString = [dsnString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSSet *allowedSchemes = [NSSet setWithObjects:@"http", @"https", nil];
    NSURL *url = [NSURL URLWithString:trimmedDsnString];
    NSString *errorMessage = nil;
    if (nil == url.scheme) {
        errorMessage = @"URL scheme of DSN is missing";
        url = nil;
    }
    if (![allowedSchemes containsObject:url.scheme]) {
        errorMessage = @"Unrecognized URL scheme in DSN";
        url = nil;
    }
    if (nil == url.host || url.host.length == 0) {
        errorMessage = @"Host component of DSN is missing";
        url = nil;
    }
    if (nil == url.user) {
        errorMessage = @"User component of DSN is missing";
        url = nil;
    }
    if (url.pathComponents.count < 2) {
        errorMessage = @"Project ID path component of DSN is missing";
        url = nil;
    }
    if (nil == url) {
        if (nil != error) {
            *error = NSErrorFromSentryError(kSentryErrorInvalidDsnError, errorMessage);
        }
        return nil;
    }
    return url;
}

@end

NS_ASSUME_NONNULL_END
