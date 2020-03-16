//
//  SentryOptionsTest.m
//  SentryTests
//
//  Created by Daniel Griesser on 12.03.19.
//  Copyright © 2019 Sentry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SentryError.h"
#import "SentryOptions.h"


@interface SentryOptionsTest : XCTestCase

@end

@implementation SentryOptionsTest

- (void)testEmptyDsn {
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithOptions:@{} didFailWithError:&error];
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(options);
}

- (void)testInvalidDsn {
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://sentry.io"} didFailWithError:&error];
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(options);
}

- (void)testInvalidDsnBoolean {
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @YES} didFailWithError:&error];
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(options);
}
    
- (void)testRelease {
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://username:password@sentry.io/1"} didFailWithError:&error];
    XCTAssertNil(error);
    XCTAssertNil(options.releaseName);
    
    options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://username:password@sentry.io/1", @"release": @"abc"} didFailWithError:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(options.releaseName, @"abc");
}
    
- (void)testEnvironment {
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://username:password@sentry.io/1"} didFailWithError:&error];
    XCTAssertNil(error);
    XCTAssertNil(options.environment);
    
    options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://username:password@sentry.io/1", @"environment": @"xxx"} didFailWithError:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(options.environment, @"xxx");
}

- (void)testDist {
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://username:password@sentry.io/1"} didFailWithError:&error];
    XCTAssertNil(error);
    XCTAssertNil(options.dist);
    
    options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://username:password@sentry.io/1", @"dist": @"hhh"} didFailWithError:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(options.dist, @"hhh");
}
    
- (void)testEnabled {
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://username:password@sentry.io/1"} didFailWithError:&error];
    XCTAssertNil(error);
    XCTAssertFalse([options.enabled boolValue]);
    
    options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://username:password@sentry.io/1", @"enabled": @YES} didFailWithError:&error];
    XCTAssertNil(error);
    XCTAssertTrue([options.enabled boolValue]);
    
    options = [[SentryOptions alloc] initWithOptions:@{@"dsn": @"https://username:password@sentry.io/1", @"enabled": @NO} didFailWithError:&error];
    XCTAssertNil(error);
    XCTAssertFalse([options.enabled boolValue]);
}

@end
