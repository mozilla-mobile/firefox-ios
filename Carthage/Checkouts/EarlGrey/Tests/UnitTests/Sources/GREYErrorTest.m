//
// Copyright 2017 Google Inc.
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

#import <XCTest/XCTest.h>

#import "Common/GREYError.h"
#import "GREYBaseTest.h"

@interface GREYErrorTest : GREYBaseTest
@end

@implementation GREYErrorTest

- (void)testMakeError {
  NSString *className = NSStringFromClass([self class]);
  NSString *filePath = [NSString stringWithUTF8String:__FILE__];
  NSString *fileName = [filePath lastPathComponent];
  NSString *functionName = [NSString stringWithUTF8String:__PRETTY_FUNCTION__];
  NSString *errorDescription = @"Test Format Interaction Timeout Error";
  GREYError *error = GREYErrorMake(kGREYInteractionErrorDomain,
                                   kGREYInteractionTimeoutErrorCode,
                                   errorDescription);

  XCTAssertNotNil(error, @"Error object cannot be generated using GREYErrorMake.");
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain,
                        @"The domain in the error object does not match given domain.");
  XCTAssertEqual(error.code, kGREYInteractionTimeoutErrorCode,
                 @"The error code in the error object does not match given error code.");
  XCTAssertEqualObjects(error.testCaseClassName, className,
                        @"The class name in the error object does not match current class name.");
  XCTAssertEqualObjects(error.functionName, functionName,
                @"The function name in the error object does not match current function name.");
  XCTAssertEqualObjects(error.bundleID, [[NSBundle mainBundle] bundleIdentifier],
                        @"The bundle ID in the error object does not match bundle ID.");

  NSData *jsonData = [error.description dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
  XCTAssertNotNil(parsed, @"Error parse error description.");

  XCTAssertEqualObjects(parsed[kErrorDescriptionKey], errorDescription,
                        @"The description in the error object does not match given description.");

  XCTAssertEqualObjects(parsed[kErrorDomainKey], kGREYInteractionErrorDomain,
                        @"The domain in description in the error object does not "
                        "match given domain.");
  NSString *codeString =
      [NSString stringWithFormat:@"%ld", (long)kGREYInteractionTimeoutErrorCode];
  XCTAssertEqualObjects(parsed[kErrorCodeKey], codeString,
                        @"The code in description in the error object does not match given code.");

  XCTAssertEqualObjects(parsed[@"File Name"], fileName,
                        @"The file name in description in the error object does not "
                        "match given file path.");

  XCTAssertEqualObjects(parsed[@"Function Name"], functionName,
                        @"The function name in description in the error object does not "
                        "match given function name.");

  XCTAssertEqualObjects(parsed[@"Bundle ID"], [[NSBundle mainBundle] bundleIdentifier],
                        @"The bundle ID in description in the error object does not match "
                        "given bundle ID.");

  NSArray *callStack = [NSThread callStackSymbols];
  [parsed[@"StackTrace"] enumerateObjectsUsingBlock:
       ^(NSString * _Nonnull stackItem, NSUInteger idx, BOOL * _Nonnull stop) {
         if (idx == 0) {
           return;
         }

         XCTAssertEqualObjects(stackItem, callStack[idx],
                               @"The stack trace in description in the error object does not "
                               "match given stack trace.");
  }];
}

- (void)testMakeNestedError {
  NSString *nestedErrorDescription = @"Test Format Interaction Timeout Error";
  GREYError *nestedError = GREYErrorMake(kGREYInteractionErrorDomain,
                                         kGREYInteractionTimeoutErrorCode,
                                         nestedErrorDescription);

  NSString *errorDescription = @"Test UI Thread Executor Timeout Error";
  GREYError *error = GREYNestedErrorMake(kGREYInteractionErrorDomain,
                                         kGREYUIThreadExecutorTimeoutErrorCode,
                                         errorDescription,
                                         nestedError);

  XCTAssertEqual(error.nestedError, nestedError,
                 @"The nested error does not match given error");
}
@end
