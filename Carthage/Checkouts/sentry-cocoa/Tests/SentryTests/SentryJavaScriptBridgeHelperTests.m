//
//  SentryJavaScriptBridgeHelperTests.m
//  SentryTests
//
//  Created by Daniel Griesser on 23.10.17.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SentryJavaScriptBridgeHelper.h"
#import <Sentry/Sentry.h>

NSString *rnReportPath = @"";

@interface SentryJavaScriptBridgeHelper()

+ (NSArray *)parseJavaScriptStacktrace:(NSString *)stacktrace;
+ (NSArray *)parseRavenFrames:(NSArray *)ravenFrames;
+ (NSArray<SentryFrame *> *)convertReactNativeStacktrace:(NSArray *)stacktrace;
+ (void)addExceptionToEvent:(SentryEvent *)event type:(NSString *)type value:(NSString *)value frames:(NSArray *)frames;
+ (SentrySeverity)sentrySeverityFromLevel:(NSString *)level;

@end

@interface SentryJavaScriptBridgeHelperTests : XCTestCase

@end

@implementation SentryJavaScriptBridgeHelperTests

- (void)testSentrySeverityFromLevel {
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentrySeverityFromLevel:nil], kSentrySeverityError);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentrySeverityFromLevel:@"log"], kSentrySeverityInfo);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentrySeverityFromLevel:@"info"], kSentrySeverityInfo);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentrySeverityFromLevel:@"bla"], kSentrySeverityError);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentrySeverityFromLevel:@"error"], kSentrySeverityError);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentrySeverityFromLevel:@"fatal"], kSentrySeverityFatal);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentrySeverityFromLevel:@"debug"], kSentrySeverityDebug);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentrySeverityFromLevel:@"warning"], kSentrySeverityWarning);
}

- (void)testSanitizeDictionary {
    SentryFrame *frame = [[SentryFrame alloc] init];
    frame.symbolAddress = @"0x01";
    NSDictionary *result =  @{@"yo": [NSString stringWithFormat:@"%@", frame]};
    XCTAssertEqualObjects([SentryJavaScriptBridgeHelper sanitizeDictionary:@{@"yo": frame}], result);
}

- (void)testCreateSentryUser {
    for (NSString *userIdKey in @[@"id", @"userId", @"userID"]) {
        SentryUser *user1 = [SentryJavaScriptBridgeHelper createSentryUserFromJavaScriptUser:@{userIdKey: @"1"}];
        SentryUser *user1Expectation = [[SentryUser alloc] initWithUserId:@"1"];
        XCTAssertEqualObjects(user1.userId, user1Expectation.userId);
        XCTAssertNil(user1.username);
        XCTAssertNil(user1.email);
        XCTAssertNil(user1.extra);
    }
    
    SentryUser *user2 = [SentryJavaScriptBridgeHelper createSentryUserFromJavaScriptUser:@{@"username": @"user"}];
    SentryUser *user2Expectation = [[SentryUser alloc] init];
    user2Expectation.username = @"user";
    XCTAssertEqualObjects(user2.username, user2Expectation.username);
    XCTAssertNil(user2.userId);
    XCTAssertNil(user2.email);
    XCTAssertNil(user2.extra);
    
    SentryUser *user3 = [SentryJavaScriptBridgeHelper createSentryUserFromJavaScriptUser:@{@"email": @"email"}];
    SentryUser *user3Expectation = [[SentryUser alloc] init];
    user3Expectation.email = @"email";
    XCTAssertEqualObjects(user3.email, user3Expectation.email);
    XCTAssertNil(user3.userId);
    XCTAssertNil(user3.username);
    XCTAssertNil(user3.extra);
    
    SentryUser *user4 = [SentryJavaScriptBridgeHelper createSentryUserFromJavaScriptUser:@{@"email": @"email", @"extra":  @{@"yo": @"foo"}}];
    SentryUser *user4Expectation = [[SentryUser alloc] init];
    user4Expectation.email = @"email";
    XCTAssertEqualObjects(user4.email, user4Expectation.email);
    XCTAssertEqualObjects(user4.extra, @{@"yo": @"foo"});
    XCTAssertNil(user4.userId);
    XCTAssertNil(user4.username);
    
    SentryUser *user5 = [SentryJavaScriptBridgeHelper createSentryUserFromJavaScriptUser:@{@"extra":  @{@"yo": @"foo"}}];
    XCTAssertNil(user5);
}

- (void)testLogLevel {
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentryLogLevelFromJavaScriptLevel:0], kSentryLogLevelNone);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentryLogLevelFromJavaScriptLevel:1], kSentryLogLevelError);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentryLogLevelFromJavaScriptLevel:2], kSentryLogLevelDebug);
    XCTAssertEqual([SentryJavaScriptBridgeHelper sentryLogLevelFromJavaScriptLevel:3], kSentryLogLevelVerbose);
}

- (void)testCreateBreadcrumb {
    SentryBreadcrumb *crumb1 = [SentryJavaScriptBridgeHelper createSentryBreadcrumbFromJavaScriptBreadcrumb:@{
                                                                                                             @"message": @"test",
                                                                                                             @"category": @"action"
                                                                                                             }];
    XCTAssertEqualObjects(crumb1.message, @"test");
    XCTAssertEqualObjects(crumb1.category, @"action");
    XCTAssertNotNil(crumb1.timestamp, @"timestamp");
    
    NSDate *date = [NSDate date];
    SentryBreadcrumb *crumb2 = [SentryJavaScriptBridgeHelper createSentryBreadcrumbFromJavaScriptBreadcrumb:@{
                                                                                                              @"message": @"test",
                                                                                                              @"category": @"action",
                                                                                                              @"timestamp": [NSString stringWithFormat:@"%ld", (long)date.timeIntervalSince1970],
                                                                                                              }];
    XCTAssertEqualObjects(crumb2.message, @"test");
    XCTAssertEqual(crumb2.level, kSentrySeverityInfo);
    XCTAssertEqualObjects(crumb2.category, @"action");
    XCTAssertTrue([crumb2.timestamp compare:date]);
    
    SentryBreadcrumb *crumb3 = [SentryJavaScriptBridgeHelper createSentryBreadcrumbFromJavaScriptBreadcrumb:@{
                                                                                                              @"message": @"test",
                                                                                                              @"category": @"action",
                                                                                                              @"timestamp": @""
                                                                                                              }];
    XCTAssertEqualObjects(crumb3.message, @"test");
    XCTAssertEqualObjects(crumb3.category, @"action");
    XCTAssertNotNil(crumb3.timestamp, @"timestamp");
}

- (NSDictionary *)getCrashReport {
    NSString *jsonPath = [[NSBundle bundleForClass:self.class] pathForResource:rnReportPath ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:jsonPath]];
    return [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
}

- (void)testCreateEvent {
    rnReportPath = @"Resources/raven-sendMessage";
    SentryEvent *sentryEvent1 = [SentryJavaScriptBridgeHelper createSentryEventFromJavaScriptEvent:[self getCrashReport]];
    XCTAssertEqualObjects(sentryEvent1.message, @"TEST message");
    XCTAssertNotNil(sentryEvent1.extra);
    XCTAssertNotNil(sentryEvent1.tags);
    XCTAssertNotNil(sentryEvent1.user);
 
    rnReportPath = @"Resources/raven-rejectedpromise";
    SentryEvent *sentryEvent2 = [SentryJavaScriptBridgeHelper createSentryEventFromJavaScriptEvent:[self getCrashReport]];
    XCTAssertEqualObjects(sentryEvent2.message, @"Boom promise");
    XCTAssertEqualObjects(sentryEvent2.platform, @"cocoa");
    XCTAssertEqualObjects(sentryEvent2.exceptions.firstObject.type, @"Unhandled Promise Rejection");
    XCTAssertEqualObjects(sentryEvent2.exceptions.firstObject.value, @"Boom promise");
    XCTAssertEqual(sentryEvent2.exceptions.firstObject.thread.stacktrace.frames.count, (NSUInteger)11);
    XCTAssertEqualObjects(sentryEvent2.exceptions.firstObject.thread.stacktrace.frames.firstObject.fileName, @"app:///index.bundle");
    XCTAssertNotNil(sentryEvent2.extra);
    XCTAssertNotNil(sentryEvent2.tags);
    XCTAssertNotNil(sentryEvent2.user);
   
    rnReportPath = @"Resources/raven-throwerror";
    SentryEvent *sentryEvent3 = [SentryJavaScriptBridgeHelper createSentryEventFromJavaScriptEvent:[self getCrashReport]];
    XCTAssertEqualObjects(sentryEvent3.exceptions.firstObject.value, @"Sentry: Test throw error");
    XCTAssertEqualObjects(sentryEvent3.exceptions.firstObject.type, @"Error");
    XCTAssertEqual(sentryEvent3.exceptions.firstObject.thread.stacktrace.frames.count, (NSUInteger)30);
    XCTAssertEqualObjects(sentryEvent3.exceptions.firstObject.thread.stacktrace.frames.firstObject.fileName, @"app:///index.bundle");
    XCTAssertNotNil(sentryEvent3.extra);
    XCTAssertNotNil(sentryEvent3.tags);
    XCTAssertNotNil(sentryEvent3.user);
}

- (void)testParseJavaScriptStacktrace {
    NSString *jsStacktrace = @"enqueueNativeCall@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:61481:36\n\
    fn@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:1786:38\n\
    nativeCrash@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:61412:21\n\
    nativeCrash@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:58712:75\n\
    _nativeCrash@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:58474:44\n\
    onPress@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:58557:39\n\
    touchableHandlePress@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:38588:45\n\
    touchableHandlePress@[native code]\n\
    _performSideEffectsForTransition@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:38145:34\n\
    _performSideEffectsForTransition@[native code]\n\
    _receiveSignal@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:38082:44\n\
    _receiveSignal@[native code]\n\
    touchableHandleResponderRelease@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:37971:24\n\
    touchableHandleResponderRelease@[native code]\n\
    _invokeGuardedCallback@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:2539:23\n\
    invokeGuardedCallback@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:2513:41\n\
    invokeGuardedCallbackAndCatchFirstError@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:2516:60\n\
    executeDispatch@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:2599:132\n\
    executeDispatchesInOrder@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:2606:52\n\
    executeDispatchesAndRelease@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:6216:62\n\
    forEach@[native code]\n\
    forEachAccumulated@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:6211:41\n\
    processEventQueue@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:6282:147\n\
    runEventQueueInBatch@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:6526:83\n\
    handleTopLevel@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:6530:33\n\
    http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:6558:55\n\
    batchedUpdates@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:5637:26\n\
    batchedUpdatesWithControlledComponents@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:2706:34\n\
    _receiveRootNodeIDEvent@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:6557:50\n\
    receiveTouches@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:6572:249\n\
    __callFunction@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:2072:47\n\
    http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:1888:29\n\
    __guard@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:2043:11\n\
    callFunctionReturnFlushedQueue@http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false:1887:20";
    
    NSArray *frames = [SentryJavaScriptBridgeHelper parseJavaScriptStacktrace:jsStacktrace];
    XCTAssertEqualObjects(frames.firstObject[@"methodName"], @"enqueueNativeCall");
    XCTAssertEqualObjects(frames.firstObject[@"lineNumber"], @61481);
    
    XCTAssertEqualObjects(frames.lastObject[@"methodName"], @"callFunctionReturnFlushedQueue");
    XCTAssertEqualObjects(frames.lastObject[@"lineNumber"], @1887);
    
    XCTAssertEqualObjects([frames objectAtIndex:7][@"file"], @"[native code]");
    XCTAssertEqualObjects([frames objectAtIndex:7][@"methodName"], @"touchableHandlePress");
    XCTAssertNil([frames objectAtIndex:7][@"lineNumber"]);
    
    XCTAssertEqual(frames.count, (NSUInteger)32);
}

- (void)testConvertReactNativeStacktrace {
    NSArray *frames1 = [SentryJavaScriptBridgeHelper convertReactNativeStacktrace:@[@{
                                                                                       @"file": @"file:///index.js",
                                                                                       @"lineNumber": @"11",
                                                                                       @"column": @"1"
                                                                                       }]];
    
    XCTAssertEqual(frames1.count, (NSUInteger)0);
    
    NSArray *frames2 = [SentryJavaScriptBridgeHelper convertReactNativeStacktrace:@[@{
                                                                                        @"methodName": @"1",
                                                                                        @"file": @"file:///index.js",
                                                                                        @"lineNumber": @"1",
                                                                                        @"column": @"1"
                                                                                        }, @{
                                                                                        @"methodName": @"2",
                                                                                        @"file": @"file:///index.js",
                                                                                        @"lineNumber": @"2",
                                                                                        @"column": @"2"
                                                                                        }]];
    
    XCTAssertEqual(frames2.count, (NSUInteger)2);
    XCTAssertEqualObjects(((SentryFrame *)[frames2 objectAtIndex:0]).function, @"2");
    XCTAssertEqualObjects(((SentryFrame *)[frames2 objectAtIndex:0]).fileName, @"app:///index.js");
    XCTAssertEqualObjects(((SentryFrame *)[frames2 objectAtIndex:0]).lineNumber, @"2");
    XCTAssertEqualObjects(((SentryFrame *)[frames2 objectAtIndex:0]).columnNumber, @"2");
}

- (void)testCordovaEvent {
    rnReportPath = @"Resources/cordova-exception";
    SentryEvent *sentryEvent1 = [SentryJavaScriptBridgeHelper createSentryEventFromJavaScriptEvent:[self getCrashReport]];
    XCTAssertNotNil(sentryEvent1.exceptions);
}

@end
