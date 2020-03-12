//
//  SentryBreadcrumbs.m
//  Sentry
//
//  Created by Daniel Griesser on 22/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Sentry/Sentry.h>
#import "SentryBreadcrumbStore.h"
#import "SentryFileManager.h"
#import "NSDate+SentryExtras.h"
#import "SentryDsn.h"

@interface SentryBreadcrumbTests : XCTestCase

@property (nonatomic, strong) SentryFileManager *fileManager;

@end

@implementation SentryBreadcrumbTests

- (void)setUp {
    [super setUp];
    NSError *error = nil;
    self.fileManager = [[SentryFileManager alloc] initWithDsn:[[SentryDsn alloc] initWithString:@"https://username:password@app.getsentry.com/12345" didFailWithError:nil] didFailWithError:&error];
    XCTAssertNil(error);
}

- (void)tearDown {
    [super tearDown];
    SentryClient.logLevel = kSentryLogLevelError;
    [self.fileManager deleteAllStoredEvents];
    [self.fileManager deleteAllStoredBreadcrumbs];
    [self.fileManager deleteAllFolders];
}


- (void)testFailAdd {
    SentryBreadcrumbStore *breadcrumbStore = [[SentryBreadcrumbStore alloc] initWithFileManager:self.fileManager];
    [breadcrumbStore addBreadcrumb:[self getBreadcrumb]];
}

- (void)testAddBreadcumb {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"https://username:password@app.getsentry.com/12345" didFailWithError:&error];
    XCTAssertNil(error);
    [client.breadcrumbs clear];
    [client.breadcrumbs addBreadcrumb:[self getBreadcrumb]];
    XCTAssertEqual(client.breadcrumbs.count, (unsigned long)1);
}

- (void)testBreadcumbLimit {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"https://username:password@app.getsentry.com/12345" didFailWithError:&error];
    XCTAssertNil(error);
    [client.breadcrumbs clear];
    for (NSInteger i = 0; i <= 100; i++) {
        [client.breadcrumbs addBreadcrumb:[self getBreadcrumb]];
    }
    XCTAssertEqual(client.breadcrumbs.count, (unsigned long)50);

    [client.breadcrumbs clear];
    for (NSInteger i = 0; i < 49; i++) {
        [client.breadcrumbs addBreadcrumb:[self getBreadcrumb]];
    }
    XCTAssertEqual(client.breadcrumbs.count, (unsigned long)49);
    [client.breadcrumbs serialize];
    XCTAssertEqual(client.breadcrumbs.count, (unsigned long)49);

    [client.breadcrumbs clear];
    for (NSInteger i = 0; i < 51; i++) {
        [client.breadcrumbs addBreadcrumb:[self getBreadcrumb]];
    }
    XCTAssertEqual(client.breadcrumbs.count, (unsigned long)50);

    [client.breadcrumbs clear];
    client.breadcrumbs.maxBreadcrumbs = 75;
    for (NSInteger i = 0; i <= 100; i++) {
        [client.breadcrumbs addBreadcrumb:[self getBreadcrumb]];
    }
    XCTAssertEqual(client.breadcrumbs.count, (unsigned long)75);

    // Hard limit
    [client.breadcrumbs clear];
    client.breadcrumbs.maxBreadcrumbs = 250;
    for (NSInteger i = 0; i <= 250; i++) {
        [client.breadcrumbs addBreadcrumb:[self getBreadcrumb]];
    }
    XCTAssertEqual(client.breadcrumbs.count, (unsigned long)200);

    // Extend Hard limit
    [client.breadcrumbs clear];
    client.breadcrumbs.maxBreadcrumbs = 250;
    client.maxBreadcrumbs = 220;
    for (NSInteger i = 0; i <= 250; i++) {
        [client.breadcrumbs addBreadcrumb:[self getBreadcrumb]];
    }
    XCTAssertEqual(client.breadcrumbs.count, (unsigned long)220);
}

- (void)testClearBreadcumb {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"https://username:password@app.getsentry.com/12345" didFailWithError:&error];
    XCTAssertNil(error);
    [client.breadcrumbs clear];
    [client.breadcrumbs addBreadcrumb:[self getBreadcrumb]];
    [client.breadcrumbs clear];
    XCTAssertTrue(client.breadcrumbs.count == 0);
}

- (void)testSerialize {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"https://username:password@app.getsentry.com/12345" didFailWithError:&error];
    XCTAssertNil(error);
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityDebug category:@"http"];
    NSDate *date = [NSDate date];
    crumb.timestamp = date;
    crumb.data = @{@"data": date, @"dict": @{@"date": date}};
    [client.breadcrumbs addBreadcrumb:crumb];
    NSDictionary *serialized = @{@"breadcrumbs": @[@{
                                 @"category": @"http",
                                 @"data": @{
                                         @"data": [date sentry_toIso8601String],
                                         @"dict": @{
                                                 @"date": [date sentry_toIso8601String]
                                                 }
                                         },
                                 @"level": @"debug",
                                 @"timestamp": [date sentry_toIso8601String]
                                 }]
                                 };
    XCTAssertEqualObjects([client.breadcrumbs serialize], serialized);
}

- (void)testSerializeSorted {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"https://username:password@app.getsentry.com/12345" didFailWithError:&error];
    XCTAssertNil(error);
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityDebug category:@"http"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:10];
    crumb.timestamp = date;
    [client.breadcrumbs addBreadcrumb:crumb];

    SentryBreadcrumb *crumb2 = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityDebug category:@"http"];
    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:899990];
    crumb2.timestamp = date2;
    [client.breadcrumbs addBreadcrumb:crumb2];

    SentryBreadcrumb *crumb3 = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityDebug category:@"http"];
    NSDate *date3 = [NSDate dateWithTimeIntervalSince1970:5];
    crumb3.timestamp = date3;
    [client.breadcrumbs addBreadcrumb:crumb3];

    SentryBreadcrumb *crumb4 = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityDebug category:@"http"];
    NSDate *date4 = [NSDate dateWithTimeIntervalSince1970:11];
    crumb4.timestamp = date4;
    [client.breadcrumbs addBreadcrumb:crumb4];

    NSDictionary *serialized = [client.breadcrumbs serialize];
    NSArray *dates = [serialized valueForKeyPath:@"breadcrumbs.timestamp"];
    XCTAssertTrue([[dates objectAtIndex:0] isEqualToString:[date sentry_toIso8601String]]);
    XCTAssertTrue([[dates objectAtIndex:1] isEqualToString:[date2 sentry_toIso8601String]]);
    XCTAssertTrue([[dates objectAtIndex:2] isEqualToString:[date3 sentry_toIso8601String]]);
    XCTAssertTrue([[dates objectAtIndex:3] isEqualToString:[date4 sentry_toIso8601String]]);
}

- (SentryBreadcrumb *)getBreadcrumb {
    return [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityDebug category:@"http"];
}

@end
