//
//  SentryRequestTests.m
//  Sentry
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Sentry/Sentry.h>
#import "SentryQueueableRequestManager.h"
#import "SentryFileManager.h"
#import "NSDate+SentryExtras.h"
#import "SentryClient+Internal.h"

NSInteger requestShouldReturnCode = 200;
NSString *dsn = @"https://username:password@app.getsentry.com/12345";

@interface SentryClient (Private)

- (_Nullable instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options
                           requestManager:(id <SentryRequestManager>)requestManager
                         didFailWithError:(NSError *_Nullable *_Nullable)error;

@end

@interface SentryMockNSURLSessionDataTask: NSURLSessionDataTask

@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, copy) void (^completionHandler)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable);

@end

@implementation SentryMockNSURLSessionDataTask

- (instancetype)initWithCompletionHandler:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler {
    self = [super init];
    if (self) {
        self.completionHandler = completionHandler;
        self.isCancelled = NO;
    }
    return self;
}

- (void)resume {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.isCancelled) {
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] initWithString:dsn] statusCode:requestShouldReturnCode HTTPVersion:nil headerFields:nil];
            if (requestShouldReturnCode != 200) {
                self.completionHandler(nil, response, [NSError errorWithDomain:@"" code:requestShouldReturnCode userInfo:nil]);
            } else {
                self.completionHandler(nil, response, nil);
            }
        }
    });
}

- (void)cancel {
    self.isCancelled = YES;
    self.completionHandler(nil, nil, [NSError errorWithDomain:@"" code:1 userInfo:nil]);
}

@end

@interface SentryMockNSURLSession: NSURLSession

@end

@implementation SentryMockNSURLSession

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler {
    return [[SentryMockNSURLSessionDataTask alloc] initWithCompletionHandler:completionHandler];
}
#pragma GCC diagnostic pop

@end

@interface SentryMockRequestManager : NSObject <SentryRequestManager>

@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) SentryMockNSURLSession *session;
@property(nonatomic, strong) SentryRequestOperation *lastOperation;
@property(nonatomic, assign) NSInteger requestsSuccessfullyFinished;
@property(nonatomic, assign) NSInteger requestsWithErrors;

@end

@implementation SentryMockRequestManager

- (instancetype)initWithSession:(SentryMockNSURLSession *)session {
    self = [super init];
    if (self) {
        self.session = session;
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.name = @"io.sentry.SentryMockRequestManager.OperationQueue";
        self.queue.maxConcurrentOperationCount = 3;
        self.requestsWithErrors = 0;
        self.requestsSuccessfullyFinished = 0;
    }
    return self;
}

- (BOOL)isReady {
    return self.queue.operationCount <= 1;
}

- (void)addRequest:(NSURLRequest *)request completionHandler:(_Nullable SentryRequestOperationFinished)completionHandler {
    if (request.allHTTPHeaderFields[@"X-TEST"]) {
        if (completionHandler) {
            completionHandler(nil, [NSError errorWithDomain:@"" code:9898 userInfo:nil]);
            return;
        }
    }

    self.lastOperation = [[SentryRequestOperation alloc] initWithSession:self.session
                                                                                request:request
                                                                      completionHandler:^(NSHTTPURLResponse *_Nullable response, NSError * _Nullable error) {
                                                                          [SentryLog logWithMessage:[NSString stringWithFormat:@"Queued requests: %lu", (unsigned long)(self.queue.operationCount - 1)] andLevel:kSentryLogLevelDebug];
                                                                          if ([response statusCode] != 200) {
                                                                              self.requestsWithErrors++;
                                                                          } else {
                                                                              self.requestsSuccessfullyFinished++;
                                                                          }
                                                                          if (completionHandler) {
                                                                              completionHandler(response, error);
                                                                          }
                                                                      }];
    [self.queue addOperation:self.lastOperation];
    // leave this here, we ask for it because NSOperation isAsynchronous
    // because it needs to be overwritten
    NSLog(@"%d", self.lastOperation.isAsynchronous);
}

- (void)cancelAllOperations {
    [self.queue cancelAllOperations];
}

- (void)restart {
    [self.lastOperation start];
}

@end

@interface SentryRequestTests : XCTestCase

@property(nonatomic, strong) SentryClient *client;
@property(nonatomic, strong) SentryMockRequestManager *requestManager;
@property(nonatomic, strong) SentryEvent *event;

@end

@implementation SentryRequestTests

- (void)clearAllFiles {
    NSError *error = nil;
    SentryFileManager *fileManager = [[SentryFileManager alloc] initWithDsn:[[SentryDsn alloc] initWithString:dsn didFailWithError:nil] didFailWithError:&error];
    [fileManager deleteAllStoredEvents];
    [fileManager deleteAllStoredBreadcrumbs];
    [fileManager deleteAllFolders];
}

- (void)tearDown {
    [super tearDown];
    requestShouldReturnCode = 200;
    [self.client clearContext];
    [self clearAllFiles];
    [self.requestManager cancelAllOperations];
}

- (void)setUp {
    [super setUp];
    [self clearAllFiles];
    self.requestManager = [[SentryMockRequestManager alloc] initWithSession:[SentryMockNSURLSession new]];
    self.client = [[SentryClient alloc] initWithOptions:@{@"dsn": dsn}
                                         requestManager:self.requestManager
                                       didFailWithError:nil];
    self.event = [[SentryEvent alloc] initWithLevel:kSentrySeverityDebug];
}

- (void)testRealRequest {
    SentryQueueableRequestManager *requestManager = [[SentryQueueableRequestManager alloc] initWithSession:[SentryMockNSURLSession new]];
    SentryClient *client = [[SentryClient alloc] initWithOptions:@{@"dsn": dsn}
                                                  requestManager:requestManager
                                                didFailWithError:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    [client sendEvent:self.event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testRealRequestWithMock {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    [self.client sendEvent:self.event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testRequestFailed {
    requestShouldReturnCode = 429;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail"];
    [self.client sendEvent:self.event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testRequestFailedSerialization {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Request should finish1"];
    SentryEvent *event1 = [[SentryEvent alloc] initWithLevel:kSentrySeverityError];
    event1.extra = @{@"a": event1};
    [self.client sendEvent:event1 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation1 fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];

}

- (void)testRequestQueueReady {
    SentryQueueableRequestManager *requestManager = [[SentryQueueableRequestManager alloc] initWithSession:[SentryMockNSURLSession new]];
    SentryClient *client = [[SentryClient alloc] initWithOptions:@{@"dsn": dsn}
                                                  requestManager:requestManager
                                                didFailWithError:nil];

    XCTAssertTrue(requestManager.isReady);

    [client sendEvent:self.event withCompletionHandler:NULL];

    for (NSInteger i = 0; i <= 5; i++) {
        [client sendEvent:self.event withCompletionHandler:NULL];
    }

    XCTAssertFalse(requestManager.isReady);
}

- (void)testRequestQueueCancel {
    SentryClient.logLevel = kSentryLogLevelVerbose;
    SentryQueueableRequestManager *requestManager = [[SentryQueueableRequestManager alloc] initWithSession:[SentryMockNSURLSession new]];
    SentryClient *client = [[SentryClient alloc] initWithOptions:@{@"dsn": @"http://a:b@sentry.io/1"}
                                                  requestManager:requestManager
                                                didFailWithError:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail"];
    [client sendEvent:self.event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [requestManager cancelAllOperations];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
    SentryClient.logLevel = kSentryLogLevelError;
}

- (void)testRequestQueueCancelWithMock {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail"];
    [self.client sendEvent:self.event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self.requestManager cancelAllOperations];
    [self.requestManager restart];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testRequestQueueWithDifferentEvents1 {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Request should finish1"];
    SentryEvent *event1 = [[SentryEvent alloc] initWithLevel:kSentrySeverityError];
    [self.client sendEvent:event1 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation1 fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testRequestQueueWithDifferentEvents2 {
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Request should finish2"];
    SentryEvent *event2 = [[SentryEvent alloc] initWithLevel:kSentrySeverityInfo];
    [self.client sendEvent:event2 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testRequestQueueWithDifferentEvents3 {
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"Request should finish3"];
    SentryEvent *event3 = [[SentryEvent alloc] initWithLevel:kSentrySeverityFatal];
    [self.client sendEvent:event3 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation3 fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testRequestQueueWithDifferentEvents4 {
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"Request should finish4"];
    SentryEvent *event4 = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    [self.client sendEvent:event4 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation4 fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testRequestQueueMultipleEvents {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Request should finish1"];
    SentryEvent *event1 = [[SentryEvent alloc] initWithLevel:kSentrySeverityError];
    [self.client sendEvent:event1 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation1 fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];

    XCTestExpectation *expectation4 = [self expectationWithDescription:@"Request should finish4"];
    SentryEvent *event4 = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    [self.client sendEvent:event4 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation4 fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testUseClientProperties {
    self.client.tags = @{@"a": @"b"};
    self.client.extra = @{@"c": @"d"};
    self.client.user = [[SentryUser alloc] initWithUserId:@"XXXXXX"];
    NSDate *date = [NSDate date];
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityInfo category:@"you"];
    crumb.timestamp = date;
    [self.client.breadcrumbs addBreadcrumb:crumb];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish4"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.infoDict = @{@"CFBundleIdentifier": @"a", @"CFBundleShortVersionString": @"b", @"CFBundleVersion": @"c"};
    crumb.timestamp = date;
    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        SentryContext *context = [[SentryContext alloc] init];
        NSDictionary *serialized = @{@"breadcrumbs": @[ @{
                                                            @"category": @"you",
                                                            @"level": @"info",
                                                            @"timestamp": [date sentry_toIso8601String]
                                                            }
                                                        ],
                                     @"user": @{@"id": @"XXXXXX"},
                                     @"contexts": [context serialize],
                                     @"event_id": event.eventId,
                                     @"extra": @{@"c": @"d"},
                                     @"level": @"warning",
                                     @"platform": @"cocoa",
                                     @"release": @"a-b",
                                     @"dist": @"c",
                                     @"sdk": @{@"name": @"sentry-cocoa", @"version": SentryClient.versionString},
                                     @"tags": @{@"a": @"b"},
                                     @"timestamp": [date sentry_toIso8601String]};
        XCTAssertEqualObjects([self.client.lastEvent serialize], serialized);
        [self.client.breadcrumbs clear];
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testUseClientPropertiesMerge {
    self.client.tags = @{@"a": @"b"};
    self.client.extra = @{@"c": @"d"};
    NSDate *date = [NSDate date];
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityInfo category:@"you"];
    crumb.timestamp = date;
    [self.client.breadcrumbs addBreadcrumb:crumb];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish4"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.infoDict = @{@"CFBundleIdentifier": @"a", @"CFBundleShortVersionString": @"b", @"CFBundleVersion": @"c"};
    event.timestamp = date;
    event.tags = @{@"1": @"2"};
    event.extra = @{@"3": @"4"};
    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        SentryContext *context = [[SentryContext alloc] init];
        NSDictionary *serialized = @{@"breadcrumbs": @[ @{
                                                            @"category": @"you",
                                                            @"level": @"info",
                                                            @"timestamp": [date sentry_toIso8601String]
                                                            }
                                                        ],
                                     @"contexts": [context serialize],
                                     @"event_id": event.eventId,
                                     @"extra": @{@"c": @"d", @"3": @"4"},
                                     @"level": @"warning",
                                     @"platform": @"cocoa",
                                     @"release": @"a-b",
                                     @"dist": @"c",
                                     @"sdk": @{@"name": @"sentry-cocoa", @"version": SentryClient.versionString},
                                     @"tags": @{@"a": @"b", @"1": @"2"},
                                     @"timestamp": [date sentry_toIso8601String]};
        XCTAssertEqualObjects([self.client.lastEvent serialize], serialized);
        [self.client.breadcrumbs clear];
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}


- (void)testEventPropsAreStrongerThanClientProperties {
    self.client.tags = @{@"a": @"b"};
    self.client.extra = @{@"c": @"d"};
    NSDate *date = [NSDate date];
    SentryBreadcrumb *crumb = [[SentryBreadcrumb alloc] initWithLevel:kSentrySeverityInfo category:@"you"];
    crumb.timestamp = date;
    [self.client.breadcrumbs addBreadcrumb:crumb];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish4"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.infoDict = @{@"CFBundleIdentifier": @"a", @"CFBundleShortVersionString": @"b", @"CFBundleVersion": @"c"};
    event.timestamp = date;
    event.tags = @{@"a": @"1"};
    event.extra = @{@"c": @"2"};
    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        SentryContext *context = [[SentryContext alloc] init];
        NSDictionary *serialized = @{@"breadcrumbs": @[ @{
                                                            @"category": @"you",
                                                            @"level": @"info",
                                                            @"timestamp": [date sentry_toIso8601String]
                                                            }
                                                        ],
                                     @"contexts": [context serialize],
                                     @"event_id": event.eventId,
                                     @"extra": @{@"c": @"2"},
                                     @"level": @"warning",
                                     @"platform": @"cocoa",
                                     @"release": @"a-b",
                                     @"dist": @"c",
                                     @"sdk": @{@"name": @"sentry-cocoa", @"version": SentryClient.versionString},
                                     @"tags": @{@"a": @"1"},
                                     @"timestamp": [date sentry_toIso8601String]};
        XCTAssertEqualObjects([self.client.lastEvent serialize], serialized);
        [self.client.breadcrumbs clear];
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testRequestQueueWithAndFlushItAfterSuccess {
    requestShouldReturnCode = 429;
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event1 = [[SentryEvent alloc] initWithLevel:kSentrySeverityError];
    [self.client sendEvent:event1 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation1 fulfill];
    }];

    [self waitForExpectations:@[expectation1] timeout:5];
    XCTAssertEqual(self.requestManager.requestsWithErrors, 1);
    requestShouldReturnCode = 200;

    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event2 = [[SentryEvent alloc] initWithLevel:kSentrySeverityError];
    [self.client sendEvent:event2 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation2 fulfill];
    }];

    [self waitForExpectations:@[expectation2] timeout:5];
    XCTAssertEqual(self.requestManager.requestsSuccessfullyFinished, 1);
    XCTAssertEqual(self.requestManager.requestsWithErrors, 1);
    requestShouldReturnCode = 200;

    XCTestExpectation *expectation3 = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event3 = [[SentryEvent alloc] initWithLevel:kSentrySeverityError];
    [self.client sendEvent:event3 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation3 fulfill];
    }];
    [self waitForExpectations:@[expectation3] timeout:5];

    SentryFileManager *fileManager = [[SentryFileManager alloc] initWithDsn:[[SentryDsn alloc] initWithString:dsn didFailWithError:nil] didFailWithError:nil];
    [self waitForExpectations:@[[self waitUntilLocalFileQueueIsFlushed:fileManager]] timeout:5.0];
    XCTAssertEqual(self.requestManager.requestsSuccessfullyFinished, 3);
    XCTAssertEqual(self.requestManager.requestsWithErrors, 1);
}

- (XCTestExpectation *)waitUntilLocalFileQueueIsFlushed:(SentryFileManager *)fileManager {
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait for file queue"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSInteger i = 0; i <= 100; i++) {
            NSLog(@"@@ %lu", (unsigned long)[fileManager getAllStoredEvents].count);
            if ([fileManager getAllStoredEvents].count == 0) {
                [expectation fulfill];
                return;
            }
            sleep(1);
        }
    });
    return expectation;
}

- (void)testBlockBeforeSerializeEvent {
    NSDictionary *tags = @{@"a": @"b"};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    self.client.beforeSerializeEvent = ^(SentryEvent * _Nonnull event) {
        event.tags = tags;
    };
    XCTAssertNil(event.tags);
    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertEqualObjects(self.client.lastEvent.tags, tags);
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testBlockBeforeSendRequest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    self.client.beforeSendRequest = ^(SentryNSURLRequest * _Nonnull request) {
        [request setValue:@"12345" forHTTPHeaderField:@"X-TEST"];
    };

    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, 9898);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testSnapshotStacktrace {
    XCTestExpectation *expectationSnap = [self expectationWithDescription:@"Snapshot"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];

    SentryThread *thread = [[SentryThread alloc] initWithThreadId:@(9999)];
    [self.client startCrashHandlerWithError:nil];
    self.client._snapshotThreads = @[thread];

    self.client._debugMeta = @[[[SentryDebugMeta alloc] init]];

    [self.client snapshotStacktrace:^{
        [self.client appendStacktraceToEvent:event];
        XCTAssertTrue(YES);
        [expectationSnap fulfill];
    }];

    [self waitForExpectations:@[expectationSnap] timeout:5.0];

    __weak id weakSelf = self;
    self.client.beforeSerializeEvent = ^(SentryEvent * _Nonnull event) {
        id self = weakSelf;
        XCTAssertEqualObjects(event.threads.firstObject.threadId, @(9999));
        XCTAssertNotNil(event.debugMeta);
        XCTAssertTrue(event.debugMeta.count > 0);
    };

    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testShouldSendEventNo {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.message = @"abc";
    __weak id weakSelf = self;
    self.client.shouldSendEvent = ^BOOL(SentryEvent * _Nonnull event) {
        id self = weakSelf;
        if ([event.message isEqualToString:@"abc"]) {
            XCTAssertTrue(YES);
        } else {
            XCTAssertTrue(NO);
        }
        return NO;
    };
    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testShouldSendEventYes {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.message = @"abc";
    __weak id weakSelf = self;
    self.client.shouldSendEvent = ^BOOL(SentryEvent * _Nonnull event) {
        id self = weakSelf;
        if ([event.message isEqualToString:@"abc"]) {
            XCTAssertTrue(YES);
        } else {
            XCTAssertTrue(NO);
        }
        return YES;
    };
    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testSamplingZero {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.message = @"abc";
    self.client.sampleRate = 0.0;
    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testSamplingOne {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.message = @"abc";
    self.client.sampleRate = 1.0;
    XCTAssertEqual(self.client.sampleRate, 1.0);
    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testSamplingBogus {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should finish"];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.message = @"abc";
    self.client.sampleRate = -123.0;
    [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"waitForExpectationsWithTimeout errored");
        }
        XCTAssert(YES);
    }];
}

- (void)testLocalFileQueueLimit {
    NSError *error = nil;
    SentryFileManager *fileManager = [[SentryFileManager alloc] initWithDsn:[[SentryDsn alloc] initWithString:dsn didFailWithError:nil] didFailWithError:&error];

    requestShouldReturnCode = 429;

    NSMutableArray *expectations = [NSMutableArray new];
    for (NSInteger i = 0; i <= 20; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Request should fail %ld", (long)i]];
        SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
        event.message = @"abc";
        [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
            XCTAssertNotNil(error);
            [expectation fulfill];
        }];
        [expectations addObject:expectation];
    }
    [self waitForExpectations:expectations timeout:5.0];
    XCTAssertEqual([fileManager getAllStoredEvents].count, (unsigned long)10);
}

- (void)testDoNotRetryEvenOnce {
    NSError *error = nil;
    SentryFileManager *fileManager = [[SentryFileManager alloc] initWithDsn:[[SentryDsn alloc] initWithString:dsn didFailWithError:nil] didFailWithError:&error];

    requestShouldReturnCode = 429;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
    // We overwrite the shouldQueueEvent
    // People could implement their own maxAge or Severity check on the event
    // A simple NO will never ever try again sending a event
    self.client.shouldQueueEvent = ^BOOL(SentryEvent * _Nonnull event, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        return NO;
    };
#pragma GCC diagnostic pop

    NSMutableArray *expectations = [NSMutableArray new];
    for (NSInteger i = 0; i <= 3; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Request should fail %ld", (long)i]];
        SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
        event.message = @"abc";
        [self.client sendEvent:event withCompletionHandler:^(NSError * _Nullable error) {
            XCTAssertNotNil(error);
            [expectation fulfill];
        }];
        [expectations addObject:expectation];
    }
    [self waitForExpectations:expectations timeout:5.0];
    XCTAssertEqual([fileManager getAllStoredEvents].count, (unsigned long)0);
}

- (void)testDisabledClient {
    NSError *error = nil;
    SentryFileManager *fileManager = [[SentryFileManager alloc] initWithDsn:[[SentryDsn alloc] initWithString:dsn didFailWithError:nil] didFailWithError:&error];

    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.message = @"abc";
    SentryClient.logLevel = kSentryLogLevelDebug;
    self.client.enabled = @NO;
    [self.client sendEvent:event withCompletionHandler:nil];

    XCTAssertEqual([fileManager getAllStoredEvents].count, (unsigned long)1);
}

@end
