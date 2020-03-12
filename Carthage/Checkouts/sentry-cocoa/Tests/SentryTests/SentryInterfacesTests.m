//
//  SentryInterfacesTests.m
//  Sentry
//
//  Created by Daniel Griesser on 10/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Sentry/Sentry.h>
#import "SentryContext.h"
#import "SentryFileManager.h"
#import "NSDate+SentryExtras.h"

@interface SentryInterfacesTests : XCTestCase

@end

@implementation SentryInterfacesTests

// TODO test event

- (void)testDebugMeta {
    SentryDebugMeta *debugMeta = [[SentryDebugMeta alloc] init];
    debugMeta.uuid = @"abcd";
    XCTAssertNotNil(debugMeta.uuid);
    NSDictionary *serialized = @{@"uuid": @"abcd"};
    XCTAssertEqualObjects([debugMeta serialize], serialized);

    SentryDebugMeta *debugMeta2 = [[SentryDebugMeta alloc] init];
    debugMeta2.uuid = @"abcde";
    debugMeta2.imageAddress = @"0x0000000100034000";
    debugMeta2.type = @"1";
    debugMeta2.cpuSubType = @(2);
    debugMeta2.cpuType = @(3);
    debugMeta2.imageVmAddress = @"0x01";
    debugMeta2.imageSize = @(4);
    debugMeta2.name = @"name";
    debugMeta2.revisionVersion = @(10);
    debugMeta2.minorVersion = @(20);
    debugMeta2.majorVersion = @(30);
    NSDictionary *serialized2 = @{@"image_addr": @"0x0000000100034000",
                                  @"image_vmaddr": @"0x01",
                                  @"image_addr": @"0x02",
                                  @"image_size": @(4),
                                  @"type": @"1",
                                  @"name": @"name",
                                  @"cpu_subtype": @(2),
                                  @"cpu_type": @(3),
                                  @"revision_version": @(10),
                                  @"minor_version": @(20),
                                  @"major_version": @(30),
                                  @"uuid": @"abcde"};
    XCTAssertEqualObjects([debugMeta2 serialize], serialized2);
}

- (void)testFrame {
    SentryFrame *frame = [[SentryFrame alloc] init];
    frame.symbolAddress = @"0x01";
    XCTAssertNotNil(frame.symbolAddress);
    NSDictionary *serialized = @{@"symbol_addr": @"0x01", @"function": @"<redacted>"};
    XCTAssertEqualObjects([frame serialize], serialized);

    SentryFrame *frame2 = [[SentryFrame alloc] init];
    frame2.symbolAddress = @"0x01";
    XCTAssertNotNil(frame2.symbolAddress);

    frame2.fileName = @"file://b.swift";
    frame2.function = @"[hey2 alloc]";
    frame2.module = @"b";
    frame2.lineNumber = @(100);
    frame2.columnNumber = @(200);
    frame2.package = @"package";
    frame2.imageAddress = @"image_addr";
    frame2.instructionAddress = @"instruction_addr";
    frame2.symbolAddress = @"symbol_addr";
    frame2.platform = @"platform";
    NSDictionary *serialized2 = @{@"filename": @"file://b.swift",
                                  @"function": @"[hey2 alloc]",
                                  @"module": @"b",
                                  @"package": @"package",
                                  @"image_addr": @"image_addr",
                                  @"instruction_addr": @"instruction_addr",
                                  @"symbol_addr": @"symbol_addr",
                                  @"platform": @"platform",
                                  @"lineno": @(100),
                                  @"colno": @(200)};
    XCTAssertEqualObjects([frame2 serialize], serialized2);
}

- (void)testEvent {
    NSDate *date = [NSDate date];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    event.timestamp = date;
    event.environment = @"bla";
    event.infoDict = @{@"CFBundleIdentifier": @"a", @"CFBundleShortVersionString": @"b", @"CFBundleVersion": @"c"};
    event.extra = @{@"__sentry_stacktrace": @"f", @"date": date};
    NSDictionary *serialized = @{@"contexts": [[[SentryContext alloc] init] serialize],
                                 @"event_id": event.eventId,
                                 @"extra": @{@"date": [date sentry_toIso8601String]},
                                 @"level": @"info",
                                 @"environment": @"bla",
                                 @"platform": @"cocoa",
                                 @"release": @"a-b",
                                 @"dist": @"c",
                                 @"sdk": @{@"name": @"sentry-cocoa", @"version": SentryClient.versionString},
                                 @"timestamp": [date sentry_toIso8601String]};
    XCTAssertEqualObjects([event serialize], serialized);

    SentryEvent *event2 = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    event2.timestamp = date;
    NSDictionary *serialized2 = @{@"contexts": [[[SentryContext alloc] init] serialize],
                                 @"event_id": event2.eventId,
                                 @"level": @"info",
                                 @"platform": @"cocoa",
                                 @"sdk": @{@"name": @"sentry-cocoa", @"version": SentryClient.versionString},
                                 @"timestamp": [date sentry_toIso8601String]};
    XCTAssertEqualObjects([event2 serialize], serialized2);

    SentryEvent *event3 = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    event3.timestamp = date;
    event3.sdk = @{@"version": @"0.15.2", @"name": @"sentry-react-native", @"integrations": @[@"sentry-cocoa"]};
    NSDictionary *serialized3 = @{@"contexts": [[[SentryContext alloc] init] serialize],
                                  @"event_id": event3.eventId,
                                  @"level": @"info",
                                  @"platform": @"cocoa",
                                  @"sdk": @{@"name": @"sentry-react-native", @"version": @"0.15.2",
                                            @"integrations": @[@"sentry-cocoa"]},
                                  @"timestamp": [date sentry_toIso8601String]};
    XCTAssertEqualObjects([event3 serialize], serialized3);
}

- (void)testTransactionEvent {
    NSDate *date = [NSDate date];

    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    event.timestamp = date;
    event.extra = @{@"__sentry_transaction": @"yoyoyo"};
    event.sdk = @{@"version": @"0.15.2", @"name": @"sentry-react-native", @"integrations": @[@"sentry-cocoa"]};
    NSDictionary *serialized = @{@"contexts": [[[SentryContext alloc] init] serialize],
                                 @"event_id": event.eventId,
                                 @"level": @"info",
                                 @"extra": @{},
                                 @"transaction": @"yoyoyo",
                                 @"platform": @"cocoa",
                                 @"sdk": @{@"name": @"sentry-react-native", @"version": @"0.15.2",
                                           @"integrations": @[@"sentry-cocoa"]},
                                 @"timestamp": [date sentry_toIso8601String]};
    XCTAssertEqualObjects([event serialize], serialized);

    SentryEvent *event3 = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    event3.timestamp = date;
    event3.transaction = @"UIViewControllerTest";
    event3.sdk = @{@"version": @"0.15.2", @"name": @"sentry-react-native", @"integrations": @[@"sentry-cocoa"]};
    NSDictionary *serialized3 = @{@"contexts": [[[SentryContext alloc] init] serialize],
                                  @"event_id": event3.eventId,
                                  @"level": @"info",
                                  @"transaction": @"UIViewControllerTest",
                                  @"platform": @"cocoa",
                                  @"sdk": @{@"name": @"sentry-react-native", @"version": @"0.15.2",
                                            @"integrations": @[@"sentry-cocoa"]},
                                  @"timestamp": [date sentry_toIso8601String]};
    XCTAssertEqualObjects([event3 serialize], serialized3);
}

- (void)testSetDistToNil {
    SentryEvent *eventEmptyDist = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    eventEmptyDist.infoDict = @{@"CFBundleIdentifier": @"a", @"CFBundleShortVersionString": @"b", @"CFBundleVersion": @"c"};
    eventEmptyDist.releaseName = @"abc";
    XCTAssertNil([[eventEmptyDist serialize] objectForKey:@"dist"]);
    XCTAssertEqualObjects([[eventEmptyDist serialize] objectForKey:@"release"], @"abc");
}

- (void)testEventDataStoring {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"id": @"1234"}
                                                       options:0
                                                         error:nil];
    SentryEvent *event = [[SentryEvent alloc] initWithJSON:jsonData];
    XCTAssertNil([[event serialize] objectForKey:@"json"]);
}

- (void)testStacktrace {
    SentryFrame *frame = [[SentryFrame alloc] init];
    frame.symbolAddress = @"0x01";
    SentryStacktrace *stacktrace = [[SentryStacktrace alloc] initWithFrames:@[frame] registers:@{@"a": @"1"}];
    XCTAssertNotNil(stacktrace.frames);
    XCTAssertNotNil(stacktrace.registers);
    [stacktrace fixDuplicateFrames];
    NSDictionary *serialized = @{@"frames": @[@{@"symbol_addr": @"0x01", @"function": @"<redacted>"}],
                                 @"registers": @{@"a": @"1"}};
    XCTAssertEqualObjects([stacktrace serialize], serialized);
}

- (void)testThread {
    SentryThread *thread = [[SentryThread alloc] initWithThreadId:@(1)];
    XCTAssertNotNil(thread.threadId);
    NSDictionary *serialized = @{@"id": @(1)};
    XCTAssertEqualObjects([thread serialize], serialized);

    SentryThread *thread2 = [[SentryThread alloc] initWithThreadId:@(2)];
    XCTAssertNotNil(thread2.threadId);
    thread2.crashed = @(YES);
    thread2.current = @(NO);
    thread2.name = @"name";
    SentryFrame *frame = [[SentryFrame alloc] init];
    frame.symbolAddress = @"0x01";
    thread2.stacktrace = [[SentryStacktrace alloc] initWithFrames:@[frame] registers:@{@"a": @"1"}];
    NSDictionary *serialized2 = @{
                                  @"id": @(2),
                                  @"crashed": @(YES),
                                  @"current": @(NO),
                                  @"name": @"name",
                                  @"stacktrace": @{@"frames": @[@{@"symbol_addr": @"0x01", @"function": @"<redacted>"}],
                                                   @"registers": @{@"a": @"1"}}
                                  };
    XCTAssertEqualObjects([thread2 serialize], serialized2);
}

- (void)testUser {
    SentryUser *user = [[SentryUser alloc] init];
    user.userId = @"1";
    XCTAssertNotNil(user.userId);
    NSDictionary *serialized = @{@"id": @"1"};
    XCTAssertEqualObjects([user serialize], serialized);

    SentryUser *user2 = [[SentryUser alloc] init];
    user2.userId = @"1";
    XCTAssertNotNil(user2.userId);
    user2.email = @"a@b.com";
    user2.username = @"tony";
    user2.extra = @{@"test": @"a"};
    NSDictionary *serialized2 = @{
                                  @"id": @"1",
                                  @"email": @"a@b.com",
                                  @"username": @"tony",
                                  @"extra": @{@"test": @"a"}
                                  };
    XCTAssertEqualObjects([user2 serialize], serialized2);
}

- (void)testException {
    SentryException *exception = [[SentryException alloc] initWithValue:@"value" type:@"type"];
    XCTAssertNotNil(exception.value);
    XCTAssertNotNil(exception.type);
    NSDictionary *serialized = @{
                                 @"value": @"value",
                                 @"type": @"type",
                                 };
    XCTAssertEqualObjects([exception serialize], serialized);

    SentryException *exception2 = [[SentryException alloc] initWithValue:@"value" type:@"type"];
    XCTAssertNotNil(exception2.value);
    XCTAssertNotNil(exception2.type);

    SentryThread *thread2 = [[SentryThread alloc] initWithThreadId:@(2)];
    XCTAssertNotNil(thread2.threadId);
    thread2.crashed = @(YES);
    thread2.current = @(NO);
    thread2.name = @"name";
    SentryFrame *frame = [[SentryFrame alloc] init];
    frame.symbolAddress = @"0x01";
    thread2.stacktrace = [[SentryStacktrace alloc] initWithFrames:@[frame] registers:@{@"a": @"1"}];

    exception2.thread = thread2;
    exception2.mechanism = [[SentryMechanism alloc] initWithType:@"test"];
    exception2.module = @"module";
    NSDictionary *serialized2 = @{
                                 @"value": @"value",
                                 @"type": @"type",
                                 @"thread_id": @(2),
                                 @"stacktrace": @{@"frames": @[@{@"symbol_addr": @"0x01", @"function": @"<redacted>"}],
                                                  @"registers": @{@"a": @"1"}},
                                 @"module": @"module",
                                 @"mechanism": @{@"type": @"test"}
                                 };

    XCTAssertEqualObjects([exception2 serialize], serialized2);
}

- (void)testContext {
    SentryContext *context = [[SentryContext alloc] init];
    XCTAssertNotNil(context);
    XCTAssertEqual([context serialize].count, (unsigned long)3);
}

- (void)testBreadcrumb {
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityInfo category:@"http"];
    XCTAssertTrue(crumb.level >= 0);
    XCTAssertNotNil(crumb.category);
    NSDate *date = [NSDate date];
    crumb.timestamp = date;
    NSDictionary *serialized = @{
                                 @"level": @"info",
                                 @"timestamp": [date sentry_toIso8601String],
                                 @"category": @"http",
                                 };
    XCTAssertEqualObjects([crumb serialize], serialized);

    SentryBreadcrumb *crumb2 = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityInfo category:@"http"];
    XCTAssertTrue(crumb2.level >= 0);
    XCTAssertNotNil(crumb2.category);
    crumb2.data = @{@"bla": @"1"};
    crumb2.type = @"type";
    crumb2.timestamp = date;
    crumb2.message = @"message";
    NSDictionary *serialized2 = @{
                                 @"level": @"info",
                                 @"type": @"type",
                                 @"message": @"message",
                                 @"timestamp": [date sentry_toIso8601String],
                                 @"category": @"http",
                                 @"data": @{@"bla": @"1"},
                                 };
    XCTAssertEqualObjects([crumb2 serialize], serialized2);
}

- (void)testBreadcrumbStore {
    SentryBreadcrumbStore *store = [[SentryBreadcrumbStore alloc] initWithFileManager:[[SentryFileManager alloc] initWithDsn:[[SentryDsn alloc] initWithString:@"https://username:password@app.getsentry.com/12345" didFailWithError:nil] didFailWithError:nil]];
    [store clear];
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityInfo category:@"http"];
    [store addBreadcrumb:crumb];
    NSDate *date = [NSDate date];
    crumb.timestamp = date;
    NSDictionary *serialized = @{
                                 @"breadcrumbs": @[
                                        @{
                                            @"level": @"info",
                                            @"category": @"http",
                                            @"timestamp": [date sentry_toIso8601String]
                                            }
                                        ]
                                 };
    XCTAssertEqualObjects([store serialize], serialized);
    [store clear];
}

- (void)testEventSdkIntegrations {
    NSDate *date = [NSDate date];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    event.timestamp = date;
    event.environment = @"bla";
    event.infoDict = @{@"CFBundleIdentifier": @"a", @"CFBundleShortVersionString": @"b", @"CFBundleVersion": @"c"};
    event.extra = @{@"__sentry_stacktrace": @"f", @"__sentry_sdk_integrations": @[@"react-native"]};
    NSDictionary *serialized = @{@"contexts": [[[SentryContext alloc] init] serialize],
                                 @"event_id": event.eventId,
                                 @"extra": [NSDictionary new],
                                 @"level": @"info",
                                 @"environment": @"bla",
                                 @"platform": @"cocoa",
                                 @"release": @"a-b",
                                 @"dist": @"c",
                                 @"sdk": @{@"name": @"sentry-cocoa", @"version": SentryClient.versionString, @"integrations": @[@"react-native"]},
                                 @"timestamp": [date sentry_toIso8601String]};
    XCTAssertEqualObjects([event serialize], serialized);

}

- (void)testEventFingerprint {
    NSDate *date = [NSDate date];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    [event setFingerprint:@[@"test"]];
    event.environment = @"bla";
    event.infoDict = @{@"CFBundleIdentifier": @"a", @"CFBundleShortVersionString": @"b", @"CFBundleVersion": @"c"};
    event.extra = @{@"__sentry_stacktrace": @"f", @"__sentry_sdk_integrations": @[@"react-native"]};
    NSDictionary *serialized = @{@"contexts": [[[SentryContext alloc] init] serialize],
                                 @"event_id": event.eventId,
                                 @"extra": [NSDictionary new],
                                 @"level": @"info",
                                 @"environment": @"bla",
                                 @"fingerprint": @[@"test"],
                                 @"platform": @"cocoa",
                                 @"release": @"a-b",
                                 @"dist": @"c",
                                 @"sdk": @{@"name": @"sentry-cocoa", @"version": SentryClient.versionString, @"integrations": @[@"react-native"]},
                                 @"timestamp": [date sentry_toIso8601String]};
    XCTAssertEqualObjects([event serialize], serialized);

}

@end
