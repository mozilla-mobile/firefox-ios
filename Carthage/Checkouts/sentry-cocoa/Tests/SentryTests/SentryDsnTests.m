//
//  SentryDsnTests.m
//  Sentry
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Sentry/Sentry.h>
#import "SentryError.h"
#import "SentryDsn.h"

@interface SentryNSURLRequest (Private)

+ (NSURL *)getStoreUrlFromDsn:(SentryDsn *)dsn;

@end

@interface SentryDsnTests : XCTestCase

@end

//+ (NSURL *)getStoreUrlFromDsn:(SentryDsn *)dsn

@implementation SentryDsnTests

- (void)testMissingUsernamePassword {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"https://sentry.io" didFailWithError:&error];
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(client);
}

- (void)testDsnHeaderUsernameAndPassword {
    NSError *error = nil;
    SentryDsn *dsn = [[SentryDsn alloc] initWithString:@"https://username:password@sentry.io/1" didFailWithError:&error];
    SentryNSURLRequest *request = [[SentryNSURLRequest alloc] initStoreRequestWithDsn:dsn andData:[NSData data] didFailWithError:&error];
    
    NSDictionary *info = [[NSBundle bundleForClass:[SentryClient class]] infoDictionary];
    NSString *version = [NSString stringWithFormat:@"%@", info[@"CFBundleShortVersionString"]];
    
    NSString *authHeader = [[NSString alloc] initWithFormat: @"Sentry sentry_version=7,sentry_client=sentry-cocoa/%@,sentry_timestamp=%@,sentry_key=username,sentry_secret=password", version, @((NSInteger) [[NSDate date] timeIntervalSince1970])];
    
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"X-Sentry-Auth"], authHeader);
    XCTAssertNil(error);
}

- (void)testDsnHeaderUsername {
    NSError *error = nil;
    SentryDsn *dsn = [[SentryDsn alloc] initWithString:@"https://username@sentry.io/1" didFailWithError:&error];
    SentryNSURLRequest *request = [[SentryNSURLRequest alloc] initStoreRequestWithDsn:dsn andData:[NSData data] didFailWithError:&error];
    
    NSDictionary *info = [[NSBundle bundleForClass:[SentryClient class]] infoDictionary];
    NSString *version = [NSString stringWithFormat:@"%@", info[@"CFBundleShortVersionString"]];
    
    NSString *authHeader = [[NSString alloc] initWithFormat: @"Sentry sentry_version=7,sentry_client=sentry-cocoa/%@,sentry_timestamp=%@,sentry_key=username", version, @((NSInteger) [[NSDate date] timeIntervalSince1970])];
    
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"X-Sentry-Auth"], authHeader);
    XCTAssertNil(error);
}

- (void)testMissingScheme {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"sentry.io" didFailWithError:&error];
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(client);
}

- (void)testMissingHost {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"http:///1" didFailWithError:&error];
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(client);
}

- (void)testUnsupportedProtocol {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"ftp://sentry.io/1" didFailWithError:&error];
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(client);
}
    
- (void)testDsnUrl {
    NSError *error = nil;
    SentryDsn *dsn = [[SentryDsn alloc] initWithString:@"https://username:password@getsentry.net/1" didFailWithError:&error];
    
    XCTAssertEqualObjects([[SentryNSURLRequest getStoreUrlFromDsn:dsn] absoluteString], @"https://getsentry.net/api/1/store/");
    XCTAssertNil(error);
    
    SentryDsn *dsn2 = [[SentryDsn alloc] initWithString:@"https://username:password@sentry.io/foo/bar/baz/1" didFailWithError:&error];
    
    XCTAssertEqualObjects([[SentryNSURLRequest getStoreUrlFromDsn:dsn2] absoluteString], @"https://sentry.io/foo/bar/baz/api/1/store/");
    XCTAssertNil(error);
}

@end
