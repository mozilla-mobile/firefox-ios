//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <OCMock/OCMock.h>

#import "GREYBaseTest.h"

@interface EarlGreyTest : GREYBaseTest
@end

// Failure handler for EarlGrey unit tests
@interface GREYTestingFailureHandler : NSObject<GREYFailureHandler>
@property NSString *fileName;
@property(assign) NSUInteger lineNumber;
@property GREYFrameworkException *exception;
@property NSString *details;
@end

// Failure handler for EarlGrey unit tests
@implementation GREYTestingFailureHandler

- (void)resetIvars {
  self.exception = nil;
  self.details = nil;
  self.fileName = nil;
  self.lineNumber = 0;
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  self.exception = exception;
  self.details = details;
}

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  self.fileName = fileName;
  self.lineNumber = lineNumber;
}

@end

@implementation EarlGreyTest

- (void)tearDown {
  [EarlGrey setFailureHandler:nil];
  [super tearDown];
}

- (void)testFailureHandlerIsInvokedByEarlGrey {
  GREYTestingFailureHandler *handler = [[GREYTestingFailureHandler alloc] init];
  [EarlGrey setFailureHandler:handler];
  GREYFrameworkException *exception = [GREYFrameworkException exceptionWithName:@"foo"
                                                                         reason:nil];
  NSUInteger lineNumber = __LINE__;
  [EarlGrey handleException:exception details:@"bar"];
  XCTAssertEqualObjects(handler.exception, exception);
  XCTAssertEqualObjects(handler.details, @"bar");
  XCTAssertEqualObjects(handler.fileName, [NSString stringWithUTF8String:__FILE__]);
  XCTAssertEqual(handler.lineNumber, lineNumber + 1 /* failure happens in next line */);
}

- (void)testFailureHandlerIsSet {
  id<GREYFailureHandler> failureHandler = getCurrentFailureHandler();
  XCTAssertNotNil(failureHandler);
}

- (void)testFailureHandlerSetToNewValue {
  id<GREYFailureHandler> handler = [[GREYTestingFailureHandler alloc] init];
  [EarlGrey setFailureHandler:handler];
  XCTAssertEqualObjects(getCurrentFailureHandler(), handler);
}

- (void)testFailureHandlerResetsWhenSetToNil {
  id<GREYFailureHandler> handler = [[GREYTestingFailureHandler alloc] init];
  [EarlGrey setFailureHandler:handler];
  XCTAssertEqualObjects(getCurrentFailureHandler(), handler);

  [EarlGrey setFailureHandler:nil];
  id<GREYFailureHandler> failureHandler = getCurrentFailureHandler();
  XCTAssertNotNil(failureHandler);
  XCTAssertNotEqualObjects(failureHandler, handler);
}

- (void)testEarlGreyIsSingleton {
  id instance1 = EarlGrey;
  id instance2 = EarlGrey;
  XCTAssertEqual(instance1, instance2, @"EarlGrey is singleton so instances much be the same");
}

static inline id<GREYFailureHandler> getCurrentFailureHandler() {
  return [[[NSThread mainThread] threadDictionary] valueForKey:kGREYFailureHandlerKey];
}

@end
