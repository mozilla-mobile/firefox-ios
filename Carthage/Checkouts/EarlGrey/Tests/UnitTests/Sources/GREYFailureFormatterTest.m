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

#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYError.h"
#import "Common/GREYFailureFormatter.h"
#import "GREYBaseTest.h"

@interface GREYFailureFormatterTest : GREYBaseTest
@end

@implementation GREYFailureFormatterTest

- (void)testFormatFailureWithUserSpecificData {
  NSString *filePath = [NSString stringWithUTF8String:__FILE__];
  NSString *functionName = [NSString stringWithUTF8String:__PRETTY_FUNCTION__];
  NSUInteger mockLineNumber = 32;
  NSArray *mockStackTrace = @[ @"Line1", @"Line2", @"Line3", @"Line4", @"Line5", @"Line6" ];
  NSString *failureString = @"Test Failure String";
  NSString *failureLabel = @"TestFailureLabel";
  NSString *failureName = @"TestFailureName";
  XCTestCase *currentTestCase = [XCTestCase grey_currentTestCase];
  NSString *failure = [GREYFailureFormatter formatFailureForTestCase:currentTestCase
                                                        failureLabel:failureLabel
                                                         failureName:failureName
                                                            filePath:filePath
                                                          lineNumber:mockLineNumber
                                                        functionName:functionName
                                                          stackTrace:mockStackTrace
                                                      appScreenshots:@{}
                                                              format:@"%@", failureString];
  XCTAssertNotNil(failure, @"Error format failure.");
  NSArray *failureLines = [failure componentsSeparatedByString:@"\n"];
  NSString *expected = [NSString stringWithFormat:@"%@: %@", failureLabel, failureName];
  XCTAssertTrue([failureLines[0] isEqualToString:expected],
                @"Error format failure with error.");
  expected = [NSString stringWithFormat:@"%@: %@", @"Function", functionName];
  XCTAssertTrue([failureLines[2] isEqualToString:expected],
                @"Error format failure with error.");
  expected = [NSString stringWithFormat:@"%@", failureString];
  XCTAssertTrue([failureLines[4] isEqualToString:expected],
                @"Error format failure with error.");
  expected = [NSString stringWithFormat:@"%@: %@", @"Bundle ID",
              [[NSBundle mainBundle] bundleIdentifier]];
  XCTAssertTrue([failureLines[5] isEqualToString:expected],
                @"Error format failure with error.");
  expected = [NSString stringWithFormat:@"%@: %@", @"Stack Trace", @"("];
  XCTAssertTrue([failureLines[7] isEqualToString:expected],
                @"Error format failure with error.");
  NSUInteger index, stackTraceIndex;
  index = 8;
  stackTraceIndex = 0;
  while (index < [failureLines count]) {
    if ([failureLines[index] isEqualToString:@")"]) {
      break;
    }
    expected = [self grey_trimmingLeadingWhitespaceFromString:failureLines[index]];
    expected = [self grey_trimmingTailingCommaFromString:expected];
    XCTAssertTrue([expected isEqualToString:mockStackTrace[stackTraceIndex]],
                  @"Error format failure with error.");
    index++;
    stackTraceIndex++;
  }
  XCTAssertLessThan(index,
                    [failureLines count],
                    @"Error format failure with error.");
}

- (void)testFormatFailureWithError {
  NSString *filePath = [NSString stringWithUTF8String:__FILE__];
  NSString *functionName = [NSString stringWithUTF8String:__PRETTY_FUNCTION__];
  NSString *errorDescription = @"Test Format Interaction Timeout Error";
  NSString *failureLabel = @"TestFailureLabel";
  NSString *failureName = @"TestFailureName";
  GREYError *error = GREYErrorMake(kGREYInteractionErrorDomain,
                                   kGREYInteractionTimeoutErrorCode,
                                   errorDescription);
  NSString *failure = [GREYFailureFormatter formatFailureForError:error
                                                        excluding:nil
                                                     failureLabel:@"TestFailureLabel"
                                                      failureName:@"TestFailureName"
                                                           format:@"%@", @"Test Failure String"];

  XCTAssertNotNil(failure, @"Error format failure.");
  NSArray *failureLines = [failure componentsSeparatedByString:@"\n"];
  NSString *expected = [NSString stringWithFormat:@"%@: %@", failureLabel, failureName];
  XCTAssertTrue([failureLines[0] isEqualToString:expected],
                @"Error format failure with error.");
  expected = [NSString stringWithFormat:@"%@: %@", @"File", filePath];
  XCTAssertTrue([failureLines[2] isEqualToString:expected],
                @"Error format failure with error.");
  expected = [NSString stringWithFormat:@"%@: %@", @"Function", functionName];
  XCTAssertTrue([failureLines[6] isEqualToString:expected],
                @"Error format failure with error.");
  expected = [NSString stringWithFormat:@"%@", @"Test Failure String"];
  XCTAssertTrue([failureLines[8] isEqualToString:expected],
                @"Error format failure with error.");
  expected = [NSString stringWithFormat:@"%@: %@", @"Bundle ID",
                  [[NSBundle mainBundle] bundleIdentifier]];
  XCTAssertTrue([failureLines[9] isEqualToString:expected],
                @"Error format failure with error.");
  expected = [NSString stringWithFormat:@"%@: %@", @"Stack Trace", @"("];
  XCTAssertTrue([failureLines[11] isEqualToString:expected],
                @"Error format failure with error.");
  NSUInteger index;
  index = 12;
  while (index < [failureLines count]) {
    if ([failureLines[index] isEqualToString:@")"]) {
      break;
    }
    index++;
  }
  XCTAssertLessThan(index,
                    [failureLines count],
                    @"Error format failure with error.");

  index += 2;
  expected = [NSString stringWithFormat:@"%@: ", @"Screenshots"];
  XCTAssertTrue([failureLines[index] hasPrefix:expected],
                @"Error format failure with error.");
}

#pragma mark - Private

- (NSString *)grey_trimmingLeadingWhitespaceFromString:(NSString *)string {
  if ([string length] == 0) {
    return string;
  }

  NSUInteger index = 0;

  while (index < [string length]) {
    unichar stringChar = [string characterAtIndex:index];
    if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:stringChar]) {
      break;
    }
    index++;
  }

  if (index == [string length]) {
    return @"";
  }

  return [string substringFromIndex:index];
}

- (NSString *)grey_trimmingTailingCommaFromString:(NSString *)string {
  if ([string length] == 0) {
    return string;
  }

  if ([[string substringWithRange:NSMakeRange([string length] - 1, 1)] isEqualToString:@","]) {
    return [string substringWithRange:NSMakeRange(0, [string length] - 1)];
  }

  return string;
}

@end
