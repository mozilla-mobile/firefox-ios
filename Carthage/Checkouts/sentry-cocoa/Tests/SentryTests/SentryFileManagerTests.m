//
//  SentryFileManagerTests.m
//  Sentry
//
//  Created by Daniel Griesser on 23/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Sentry/Sentry.h>
#import "SentryFileManager.h"
#import "SentryDsn.h"

@interface SentryFileManagerTests : XCTestCase

@property (nonatomic, strong) SentryFileManager *fileManager;

@end

@implementation SentryFileManagerTests

- (void)setUp {
    [super setUp];
    SentryClient.logLevel = kSentryLogLevelDebug;
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

- (void)testEventStoring {
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    [self.fileManager storeEvent:event];
    NSArray<NSDictionary<NSString *, NSData *>*> *events = [self.fileManager getAllStoredEvents];
    XCTAssertTrue(events.count == 1);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[event serialize]
                                                       options:0
                                                         error:nil];
    XCTAssertEqualObjects(((NSDictionary *)events.firstObject)[@"data"], jsonData);
}

- (void)testEventDataStoring {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"id": @"1234"}
                                                       options:0
                                                         error:nil];
    SentryEvent *event = [[SentryEvent alloc] initWithJSON:jsonData];
    [self.fileManager storeEvent:event];
    NSArray<NSDictionary<NSString *, NSData *>*> *events = [self.fileManager getAllStoredEvents];
    XCTAssertTrue(events.count == 1);
    XCTAssertEqualObjects(((NSDictionary *)events.firstObject)[@"data"], jsonData);
}

- (void)testEventStore {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"https://username:password@app.getsentry.com/12345" didFailWithError:&error];
    XCTAssertNil(error);
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    [client storeEvent:event];
    NSArray<NSDictionary<NSString *, NSData *>*> *events = [self.fileManager getAllStoredEvents];
    XCTAssertTrue(events.count == 1);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[event serialize]
                                                       options:0
                                                         error:nil];
    XCTAssertEqualObjects(((NSDictionary *)events.firstObject)[@"data"], jsonData);
}

- (void)testBreadcrumbStoring {
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityInfo category:@"category"];
    [self.fileManager storeBreadcrumb:crumb];
    NSArray<NSDictionary<NSString *, NSData *>*> *crumbs = [self.fileManager getAllStoredBreadcrumbs];
    XCTAssertTrue(crumbs.count == 1);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[crumb serialize]
                                                       options:0
                                                         error:nil];
    XCTAssertEqualObjects(((NSDictionary *)crumbs.firstObject)[@"data"], jsonData);
}

- (void)testCreateDir {
    NSError *error = nil;
    [SentryFileManager createDirectoryAtPath:@"a" withError:&error];
    XCTAssertNil(error);
}

- (void)testAllFilesInFolder {
    NSArray<NSString *> *files = [self.fileManager allFilesInFolder:@"x"];
    XCTAssertTrue(files.count == 0);
}

- (void)testDeleteFileNotExsists {
    XCTAssertFalse([self.fileManager removeFileAtPath:@"x"]);
}

- (void)testFailingStoreDictionary {
    [self.fileManager storeDictionary:@{@"date": [NSDate date]} toPath:@""];
    NSArray<NSString *> *files = [self.fileManager allFilesInFolder:@"x"];
    XCTAssertTrue(files.count == 0);
}

- (void)testEventStoringHardLimit {
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    for (NSInteger i = 0; i <= 20; i++) {
        [self.fileManager storeEvent:event];
    }
    NSArray<NSDictionary<NSString *, NSData *>*> *events = [self.fileManager getAllStoredEvents];
    XCTAssertEqual(events.count, (unsigned long)10);
}

- (void)testBreadcrumbStoringHardLimit {
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityInfo category:@"category"];
    for (NSInteger i = 0; i <= 210; i++) {
        [self.fileManager storeBreadcrumb:crumb];
    }
    NSArray<NSDictionary<NSString *, NSData *>*> *crumbs = [self.fileManager getAllStoredBreadcrumbs];
    XCTAssertEqual(crumbs.count, (unsigned long)200);
}

- (void)testEventStoringHardLimitSet {
    self.fileManager.maxEvents = 15;
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    for (NSInteger i = 0; i <= 20; i++) {
        [self.fileManager storeEvent:event];
    }
    NSArray<NSDictionary<NSString *, NSData *>*> *events = [self.fileManager getAllStoredEvents];
    XCTAssertEqual(events.count, (unsigned long)15);
}

- (void)testBreadcrumbStoringHardLimitSet {
    self.fileManager.maxBreadcrumbs = 205;
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityInfo category:@"category"];
    for (NSInteger i = 0; i <= 210; i++) {
        [self.fileManager storeBreadcrumb:crumb];
    }
    NSArray<NSDictionary<NSString *, NSData *>*> *crumbs = [self.fileManager getAllStoredBreadcrumbs];
    XCTAssertEqual(crumbs.count, (unsigned long)205);
}

- (void)testEventLimitOverClient {
    NSError *error = nil;
    SentryClient *client = [[SentryClient alloc] initWithDsn:@"https://username:password@app.getsentry.com/12345" didFailWithError:&error];
    XCTAssertNil(error);
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    client.maxEvents = 16;
    for (NSInteger i = 0; i <= 20; i++) {
        [client storeEvent:event];
    }
    NSArray<NSDictionary<NSString *, NSData *>*> *events = [self.fileManager getAllStoredEvents];
    XCTAssertEqual(events.count, (unsigned long)16);
}

@end
