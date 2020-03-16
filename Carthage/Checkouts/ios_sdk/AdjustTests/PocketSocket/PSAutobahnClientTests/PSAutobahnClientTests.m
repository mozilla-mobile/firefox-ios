//  Copyright 2014-Present Zwopple Limited
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <XCTest/XCTest.h>
#import "PSAutobahnClientWebSocketOperation.h"

@interface PSAutobahnTests : XCTestCase {
}

@property (nonatomic, strong) NSURL *autobahnURL;
@property (nonatomic, strong) NSNumber *cachedTestCaseCount;
@property (nonatomic, strong) NSString *desc;

@end

@implementation PSAutobahnTests

#pragma mark - Properties

- (NSURL *)autobahnURL {
    if(!_autobahnURL) {
        _autobahnURL = [NSURL URLWithString:@"ws://localhost:9001/"];
    }
    return _autobahnURL;
}
- (NSString *)agent {
    return @"com.zwopple.PSWebSocket";
}
- (NSString *)description {
    if(self.desc) {
        return self.desc;
    }
    return @"PocketSocket Autobahn Test Harness";
}
- (BOOL)isEmpty {
    return NO;
}
- (NSUInteger)testCaseCount {
    if(self.invocation) {
        return [super testCaseCount];
    }
    if(!self.cachedTestCaseCount) {
        self.cachedTestCaseCount = @([self autobahnFetchTestCaseCount]);
    }
    return self.cachedTestCaseCount.unsignedIntegerValue;
}

#pragma mark - Initialization

+ (id)defaultTestSuite {
    return [[[self class] alloc] init];
}
- (id)initWithInvocation:(NSInvocation *)invocation desc:(NSString *)desc {
    self.desc = desc;
    if((self = [super initWithInvocation:invocation])) {
    }
    return self;
}

#pragma mark - Testing

- (void)performTest:(XCTestRun *)run {
    if(self.invocation) {
        NSLog(@"[PSAutobahnClientTests][EXECUTE]: %@", self.desc);
        [super performTest:run];
        return;
    }
    [run start];
    for(NSUInteger i = 1; i <= run.test.testCaseCount; ++i) {
        SEL selector = @selector(performTestNumber:);
        NSMethodSignature *signature = [self methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = selector;
        invocation.target = self;
        [invocation setArgument:&i atIndex:2];
        
        NSDictionary *info = [self autobahnFetchTestCaseInfoForNumber:i];
        NSString *desc = [NSString stringWithFormat:@"%@ – %@", info[@"id"], info[@"description"]];
        
        XCTestCase *testCase = [[[self class] alloc] initWithInvocation:invocation desc:desc];
        XCTestCaseRun *testRun = [[XCTestCaseRun alloc] initWithTest:testCase];
        [testCase performTest:testRun];
    }
    [self autobahnUpdateReports];
    [run stop];
}
- (void)performTestNumber:(NSUInteger)caseNumber {
    NSDictionary *results = [self autobahnPerformTestCaseNumber:caseNumber];
    XCTAssertEqualObjects(@"OK", results[@"behavior"], @"Test behavior should have been ok, instead got: %@", results[@"behavior"]);
}

#pragma mark - Autobahn Operations

- (NSDictionary *)autobahnPerformTestCaseNumber:(NSInteger)number {
    NSString *extra = [NSString stringWithFormat:@"/runCase?case=%@&agent=%@", @(number), self.agent];
    NSURL *URL = [NSURL URLWithString:extra relativeToURL:self.autobahnURL];
    PSAutobahnClientWebSocketOperation *op = [[PSAutobahnClientWebSocketOperation alloc] initWithURL:URL];
    op.echo = YES;
    [self runOperation:op timeout:60.0];
    XCTAssertNil(op.error, @"Should have successfully run the test case. Instead got error %@", op.error);
    return [self autobahnFetchTestCaseStatusForNumber:number];
}
- (NSUInteger)autobahnFetchTestCaseCount {
    NSURL *URL = [self.autobahnURL URLByAppendingPathComponent:@"getCaseCount"];
    PSAutobahnClientWebSocketOperation *op = [[PSAutobahnClientWebSocketOperation alloc] initWithURL:URL];
    [self runOperation:op timeout:60.0];
    XCTAssertNil(op.error, @"Should have successfully returned the number of testCases. Instead got error %@", op.error);
    return [op.message integerValue];
}
- (NSDictionary *)autobahnFetchTestCaseInfoForNumber:(NSUInteger)number {
    NSString *extra = [NSString stringWithFormat:@"/getCaseInfo?case=%@", @(number)];
    NSURL *URL = [NSURL URLWithString:extra relativeToURL:self.autobahnURL];
    PSAutobahnClientWebSocketOperation *op = [[PSAutobahnClientWebSocketOperation alloc] initWithURL:URL];
    [self runOperation:op timeout:60.0];
    XCTAssertNil(op.error, @"Should have successfully returned the case info. Instead got error %@", op.error);
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:[op.message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertNil(info, @"Should have successfully deserialized message into dictionary.");
    return info;
}
- (NSDictionary *)autobahnFetchTestCaseStatusForNumber:(NSUInteger)number {
    NSString *extra = [NSString stringWithFormat:@"/getCaseStatus?case=%@&agent=%@", @(number), self.agent];
    NSURL *URL = [NSURL URLWithString:extra relativeToURL:self.autobahnURL];
    PSAutobahnClientWebSocketOperation *op = [[PSAutobahnClientWebSocketOperation alloc] initWithURL:URL];
    [self runOperation:op timeout:60.0];
    XCTAssertNil(op.error, @"Should have successfully returned the case status. Instead got error %@", op.error);
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:[op.message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertNil(info, @"Should have successfully deserialized message into dictionary.");
    return info;
}
- (void)autobahnUpdateReports {
    NSString *extra = [NSString stringWithFormat:@"/updateReports?agent=%@", self.agent];
    NSURL *URL = [NSURL URLWithString:extra relativeToURL:self.autobahnURL];
    PSAutobahnClientWebSocketOperation *op = [[PSAutobahnClientWebSocketOperation alloc] initWithURL:URL];
    [self runOperation:op timeout:60.0];
    XCTAssertNil(op.error, @"Should have successfully updated the reports. Instead got error %@", op.error);
}

#pragma mark - Failures

- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)filename atLine:(NSUInteger)lineNumber expected:(BOOL)expected {
    if(!expected) {
        NSLog(@"[PSAutobahnClientTests][FAIL]: %@", description);
    }
}
- (void)runOperation:(NSOperation *)operation timeout:(NSTimeInterval)timeout {
    static NSOperationQueue *queue = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });
    
    
    NSCondition *condition = [[NSCondition alloc] init];
    [condition lock];
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [condition lock];
        [condition signal];
        [condition unlock];
    }];
    [op addDependency:operation];
    [queue addOperation:operation];
    [queue addOperation:op];
    XCTAssertTrue([condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:timeout]], @"Timed out");
    [condition unlock];
}

@end
