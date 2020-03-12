//
//  SentryNSURLRequest.m
//  Sentry
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryDsn.h>
#import <Sentry/SentryNSURLRequest.h>
#import <Sentry/SentryClient.h>
#import <Sentry/SentryEvent.h>
#import <Sentry/SentryError.h>
#import <Sentry/SentryLog.h>
#import <Sentry/NSData+SentryCompression.h>

#else
#import "SentryDsn.h"
#import "SentryNSURLRequest.h"
#import "SentryClient.h"
#import "SentryEvent.h"
#import "SentryError.h"
#import "SentryLog.h"
#import "NSData+SentryCompression.h"

#endif

NS_ASSUME_NONNULL_BEGIN

NSString *const SentryServerVersionString = @"7";
NSTimeInterval const SentryRequestTimeout = 15;

@interface SentryNSURLRequest ()

@property(nonatomic, strong) SentryDsn *dsn;

@end

@implementation SentryNSURLRequest

- (_Nullable instancetype)initStoreRequestWithDsn:(SentryDsn *)dsn
                                         andEvent:(SentryEvent *)event
                                 didFailWithError:(NSError *_Nullable *_Nullable)error {
    NSData *jsonData;
    if (nil != event.json) {
        // If we have event.json, this has been set from JS and should be sent directly
        jsonData = event.json;
        [SentryLog logWithMessage:@"Using event->json attribute instead of serializing event" andLevel:kSentryLogLevelVerbose];
    } else {
        NSDictionary *serialized = [event serialize];
        if (![NSJSONSerialization isValidJSONObject:serialized]) {
            if (error) {
                *error = NSErrorFromSentryError(kSentryErrorJsonConversionError, @"Event cannot be converted to JSON");
            }
            return nil;
        }
        
        jsonData = [NSJSONSerialization dataWithJSONObject:serialized
                                                           options:SentryClient.logLevel == kSentryLogLevelVerbose ? NSJSONWritingPrettyPrinted : 0
                                                             error:error];
    }
    
    if (SentryClient.logLevel == kSentryLogLevelVerbose) {
        [SentryLog logWithMessage:@"Sending JSON -------------------------------" andLevel:kSentryLogLevelVerbose];
        [SentryLog logWithMessage:[NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]] andLevel:kSentryLogLevelVerbose];
        [SentryLog logWithMessage:@"--------------------------------------------" andLevel:kSentryLogLevelVerbose];
    }
    return [self initStoreRequestWithDsn:dsn andData:jsonData didFailWithError:error];
}

- (_Nullable instancetype)initStoreRequestWithDsn:(SentryDsn *)dsn
                                          andData:(NSData *)data
                                 didFailWithError:(NSError *_Nullable *_Nullable)error {
    NSURL *apiURL = [self.class getStoreUrlFromDsn:dsn];
    self = [super initWithURL:apiURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:SentryRequestTimeout];
    if (self) {
        NSString *authHeader = newAuthHeader(dsn.url);

        self.HTTPMethod = @"POST";
        [self setValue:authHeader forHTTPHeaderField:@"X-Sentry-Auth"];
        [self setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [self setValue:@"sentry-cocoa" forHTTPHeaderField:@"User-Agent"];
        [self setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        self.HTTPBody = [data sentry_gzippedWithCompressionLevel:-1 error:error];
    }
    return self;
}

+ (NSURL *)getStoreUrlFromDsn:(SentryDsn *)dsn {
    NSURL *url = dsn.url;
    NSString *projectId = url.lastPathComponent;
    NSMutableArray *paths = [url.pathComponents mutableCopy];
    // [0] = /
    // [1] = projectId
    // If there are more than two, that means someone wants to have an additional path
    // ref: https://github.com/getsentry/sentry-cocoa/issues/236
    NSString *path = @"";
    if ([paths count] > 2) {
        [paths removeObjectAtIndex:0]; // We remove the leading /
        [paths removeLastObject]; // We remove projectId since we add it later
        path = [NSString stringWithFormat:@"/%@", [paths componentsJoinedByString:@"/"]]; // We put together the path
    }
    NSURLComponents *components = [NSURLComponents new];
    components.scheme = url.scheme;
    components.host = url.host;
    components.port = url.port;
    components.path = [NSString stringWithFormat:@"%@/api/%@/store/", path, projectId];
    return components.URL;
}

static NSString *newHeaderPart(NSString *key, id value) {
    return [NSString stringWithFormat:@"%@=%@", key, value];
}

static NSString *newAuthHeader(NSURL *url) {
    NSMutableString *string = [NSMutableString stringWithString:@"Sentry "];
    [string appendFormat:@"%@,", newHeaderPart(@"sentry_version", SentryServerVersionString)];
    [string appendFormat:@"%@,", newHeaderPart(@"sentry_client", [NSString stringWithFormat:@"sentry-cocoa/%@", SentryClient.versionString])];
    [string appendFormat:@"%@,", newHeaderPart(@"sentry_timestamp", @((NSInteger) [[NSDate date] timeIntervalSince1970]))];
    [string appendFormat:@"%@", newHeaderPart(@"sentry_key", url.user)];
    if (nil != url.password) {
        [string appendFormat:@",%@", newHeaderPart(@"sentry_secret", url.password)];
    }
    return string;
}

@end

NS_ASSUME_NONNULL_END
