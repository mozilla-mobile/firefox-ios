//
//  AdjustTestLibrary.m
//  AdjustTestLibrary
//
//  Created by Pedro on 18.04.17.
//  Copyright © 2017 adjust. All rights reserved.
//

#import "ATLTestLibrary.h"
#import "ATLUtil.h"
#import "ATLConstants.h"
#import "ATLTestInfo.h"
#import "ATLBlockingQueue.h"
#import "ATLControlWebSocketClient.h"

@interface ATLTestLibrary()

@property (nonatomic, strong) ATLControlWebSocketClient *controlClient;
@property (nonatomic, weak, nullable) NSObject<AdjustCommandDelegate> *commandDelegate;
@property (nonatomic, strong) ATLBlockingQueue *waitControlQueue;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, copy) NSString *currentBasePath;
@property (nonatomic, copy) NSString *currentTestName;
@property (nonatomic, strong) NSMutableString *testNames;
@property (nonatomic, strong) ATLTestInfo *infoToServer;

@end

@implementation ATLTestLibrary

BOOL exitAfterEnd = YES;
static NSURL *_baseUrl = nil;

+ (NSURL *)baseUrl {
    return _baseUrl;
}

+ (ATLTestLibrary *)testLibraryWithBaseUrl:(NSString *)baseUrl
                             andControlUrl:(NSString *)controlUrl
                        andCommandDelegate:(NSObject<AdjustCommandDelegate> *)commandDelegate {
    return [[ATLTestLibrary alloc] initWithBaseUrl:baseUrl
                                     andControlUrl:controlUrl
                                andCommandDelegate:commandDelegate];
}

- (id)initWithBaseUrl:(NSString *)baseUrl
        andControlUrl:(NSString *)controlUrl
   andCommandDelegate:(NSObject<AdjustCommandDelegate> *)commandDelegate;
{
    self = [super init];
    if (self == nil) return nil;
    
    _baseUrl = [NSURL URLWithString:baseUrl];
    self.commandDelegate = commandDelegate;
    self.testNames = [[NSMutableString alloc] init];
    
    self.controlClient = [[ATLControlWebSocketClient alloc] init];
    [self.controlClient initializeWebSocketWithControlUrl:controlUrl andTestLibrary:self];
    
    return self;
}

- (void)addTest:(NSString *)testName {
    [self.testNames appendString:testName];

    if (![testName hasSuffix:@";"]) {
        [self.testNames appendString:@";"];
    }
}

- (void)addTestDirectory:(NSString *)testDirectory {
    [self.testNames appendString:testDirectory];

    if (![testDirectory hasSuffix:@"/"] || ![testDirectory hasSuffix:@"/;"]) {
        [self.testNames appendString:@"/"];
    }

    if (![testDirectory hasSuffix:@";"]) {
        [self.testNames appendString:@";"];
    }
}

- (void)startTestSession:(NSString *)clientSdk {
    // reconnect web socket client if disconnected
    [self.controlClient reconnectIfNeeded];
    [self resetTestLibrary];
    [ATLUtil addOperationAfterLast:self.operationQueue blockWithOperation:^(NSBlockOperation *operation) {
        [self sendTestSessionI:clientSdk];
    }];
}

- (void)resetTestLibrary {
    [self teardown];
    [self initTestLibrary];
}

- (void)teardown {
    if (self.operationQueue != nil) {
        [ATLUtil debug:@"queue cancel test library thread queue"];
        [ATLUtil addOperationAfterLast:self.operationQueue
                                 block:^{
                                     [ATLUtil debug:@"cancel test library thread queue"];
                                     if (self.operationQueue != nil) {
                                         [self.operationQueue cancelAllOperations];
                                     }
                                     self.operationQueue = nil;
                                 }];
        [self.operationQueue cancelAllOperations];
    }
    [self clearTest];
}

- (void)clearTest {
    if (self.waitControlQueue != nil) {
        [self.waitControlQueue teardown];
    }
    self.waitControlQueue = nil;
    if (self.infoToServer != nil) {
        [self.infoToServer teardown];
    }
    self.infoToServer = nil;
}

- (void) initTestLibrary {
    self.waitControlQueue = [[ATLBlockingQueue alloc] init];

    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue setMaxConcurrentOperationCount:1];
}

// reset for each test
- (void)resetForNextTest {
    [self clearTest];
    [self initTest];
}

- (void)initTest {
    self.waitControlQueue = [[ATLBlockingQueue alloc] init];
    self.infoToServer = [[ATLTestInfo alloc] initWithTestLibrary:self];
}

- (void)addInfoToSend:(NSString *)key
                value:(NSString *)value {
    [self.infoToServer addInfoToSend:key value:value];
}

- (void)signalEndWaitWithReason:(NSString *)reason {
    [[self waitControlQueue] enqueue:reason];
}

- (void)cancelTestAndGetNext {
    [self resetTestLibrary];
    [ATLUtil addOperationAfterLast:self.operationQueue blockWithOperation:^(NSBlockOperation *operation) {
        ATLHttpRequest *requestData = [[ATLHttpRequest alloc] init];
        requestData.path = [ATLUtilNetworking appendBasePath:self.currentBasePath path:@"/end_test_read_next"];
        [ATLUtilNetworking sendPostRequest:requestData
                           responseHandler:^(ATLHttpResponse *httpResponse) {
                               [self readResponse:httpResponse];
                           }];
    }];
}

- (void)sendInfoToServer:(NSString *)basePath {
    [self.infoToServer sendInfoToServer:basePath];
}

- (void)sendTestSessionI:(NSString *)clientSdk {
    ATLHttpRequest *requestData = [[ATLHttpRequest alloc] init];
    NSMutableDictionary *headerFields = [NSMutableDictionary dictionaryWithObjectsAndKeys:clientSdk, @"Client-SDK", nil];

    if (self.testNames != nil) {
        [headerFields setObject:self.testNames forKey:@"Test-Names"];
    }

    requestData.headerFields = headerFields;
    requestData.path = @"/init_session";
    
    [ATLUtilNetworking sendPostRequest:requestData
                        responseHandler:^(ATLHttpResponse *httpResponse) {
                            NSString *testSessionId = httpResponse.headerFields[TEST_SESSION_ID_HEADER];
                            [[self controlClient] sendInitTestSessionSignal:testSessionId];
                            [self readResponse:httpResponse];
                        }];
}

- (void)readResponse:(ATLHttpResponse *)httpResponse {
    [ATLUtil addOperationAfterLast:self.operationQueue blockWithOperation:^(NSBlockOperation *operation) {
        [self readResponseI:operation httpResponse:httpResponse];
    }];
}

- (void)readResponseI:(NSBlockOperation *)operation
         httpResponse:(ATLHttpResponse *)httpResponse {
    if (httpResponse == nil) {
        [ATLUtil debug:@"httpResponse is null"];
        return;
    }
    [self execTestCommandsI:operation jsonFoundation:httpResponse.jsonFoundation];
}

- (void)execTestCommandsI:(NSBlockOperation *)operation
           jsonFoundation:(id)jsonFoundation {
    NSArray *jsonArray = (NSArray *)jsonFoundation;
    if (jsonArray == nil) {
        [ATLUtil debug:@"jsonArray is nil"];
        return;
    }
    
    for (NSDictionary *testCommand in jsonArray) {
        if (operation.cancelled) {
            [ATLUtil debug:@"command execution cancelled"];
            return;
        }
        NSString *className = [testCommand objectForKey:@"className"];
        NSString *functionName = [testCommand objectForKey:@"functionName"];
        NSDictionary *params = [testCommand objectForKey:@"params"];
        [ATLUtil debug:@"className: %@, functionName: %@, params: %@", className, functionName, params];

        NSDate *timeBefore = [NSDate date];
        [ATLUtil debug:@"time before %@", [ATLUtil formatDate:timeBefore]];

        if ([className isEqualToString:TEST_LIBRARY_CLASSNAME]) {
            [self execTestLibraryCommandI:functionName params:params];

            NSDate *timeAfter = [NSDate date];
            [ATLUtil debug:@"time after %@", [ATLUtil formatDate:timeAfter]];
            NSTimeInterval timeElapsedSeconds = [timeAfter timeIntervalSinceDate:timeBefore];
            [ATLUtil debug:@"seconds elapsed %f", timeElapsedSeconds];

            continue;
        }

        if (![className isEqualToString:ADJUST_CLASSNAME]) {
            [ATLUtil debug:@"className %@ is not valid", className];
            continue;
        }

        if ([self.commandDelegate respondsToSelector:@selector(executeCommand:methodName:parameters:)]) {
            [self.commandDelegate executeCommand:className methodName:functionName parameters:params];
        } else if ([self.commandDelegate respondsToSelector:@selector(executeCommand:methodName:jsonParameters:)]) {
            NSString *paramsJsonString = [ATLUtil parseDictionaryToJsonString:params];
            [self.commandDelegate executeCommand:className methodName:functionName jsonParameters:paramsJsonString];
        } else if ([self.commandDelegate respondsToSelector:@selector(executeCommandRawJson:)]) {
            NSString *commandJsonString = [ATLUtil parseDictionaryToJsonString:testCommand];
            [self.commandDelegate executeCommandRawJson:commandJsonString];
        }

        NSDate *timeAfter = [NSDate date];
        [ATLUtil debug:@"time after %@", [ATLUtil formatDate:timeAfter]];

        NSTimeInterval timeElapsedSeconds = [timeAfter timeIntervalSinceDate:timeBefore];
        [ATLUtil debug:@"seconds elapsed %f", timeElapsedSeconds];
    }
}

- (void)execTestLibraryCommandI:(NSString *)functionName
                         params:(NSDictionary *)params {
    if ([functionName isEqualToString:@"resetTest"]) {
        [self resetTestI:params];
    } else if ([functionName isEqualToString:@"endTestReadNext"]) {
        [self endTestReadNextI];
    } else if ([functionName isEqualToString:@"endTestSession"]) {
        [self endTestSessionI];
    } else if ([functionName isEqualToString:@"wait"]) {
        [self waitI:params];
    }
}

- (void)resetTestI:(NSDictionary *)params {
    if ([params objectForKey:BASE_PATH_PARAM]) {
        self.currentBasePath = [params objectForKey:BASE_PATH_PARAM][0];
        [ATLUtil debug:@"current base path %@", self.currentBasePath];
    }
    if ([params objectForKey:TEST_NAME_PARAM]) {
        self.currentTestName = [params objectForKey:TEST_NAME_PARAM][0];
        [ATLUtil debug:@"current test name %@", self.currentTestName];
    }
    [self resetForNextTest];
}

- (void)endTestReadNextI {
    ATLHttpRequest *requestData = [[ATLHttpRequest alloc] init];
    requestData.path = [ATLUtilNetworking appendBasePath:self.currentBasePath path:@"/end_test_read_next"];
    [ATLUtilNetworking sendPostRequest:requestData
                       responseHandler:^(ATLHttpResponse *httpResponse) {
                           [self readResponse:httpResponse];
                       }];
}

- (void)endTestSessionI {
    [self teardown];
    if (exitAfterEnd) {
        exit(0);
    }
}

- (void)doNotExitAfterEnd {
    exitAfterEnd = false;
}

- (void)waitI:(NSDictionary *)params {
    if ([params objectForKey:WAIT_FOR_CONTROL]) {
        NSString *waitExpectedReason = [params objectForKey:WAIT_FOR_CONTROL][0];
        [ATLUtil debug:@"wait for %@", waitExpectedReason];
        NSString *endReason = [self.waitControlQueue dequeue];
        [ATLUtil debug:@"wait ended due to %@", endReason];
    }
    if ([params objectForKey:WAIT_FOR_SLEEP]) {
        NSString *millisToSleepS = [params objectForKey:WAIT_FOR_SLEEP][0];
        [ATLUtil debug:@"sleep for %@", millisToSleepS];
        double secondsToSleep = [millisToSleepS intValue] / 1000;
        [NSThread sleepForTimeInterval:secondsToSleep];
        [ATLUtil debug:@"sleep ended"];
    }
}

@end
