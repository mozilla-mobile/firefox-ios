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

#import "Exception/GREYDefaultFailureHandler.h"

#import <XCTest/XCTest.h>

#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYElementHierarchy.h"
#import "Common/GREYFailureFormatter.h"
#import "Common/GREYFailureScreenshotter.h"
#import "Common/GREYScreenshotUtil+Internal.h"
#import "Common/GREYThrowDefines.h"
#import "Common/GREYVisibilityChecker.h"
#import "Exception/GREYFrameworkException.h"
#import "Provider/GREYUIWindowProvider.h"

// Counter that is incremented each time a failure occurs in an unknown test.
@implementation GREYDefaultFailureHandler {
  NSString *_fileName;
  NSUInteger _lineNumber;
}

#pragma mark - GREYFailureHandler

- (void)setInvocationFile:(NSString *)fileName andInvocationLine:(NSUInteger)lineNumber {
  _fileName = fileName;
  _lineNumber = lineNumber;
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  GREYThrowOnNilParameter(exception);

  // Test case can be nil if EarlGrey is invoked outside the context of an XCTestCase.
  XCTestCase *currentTestCase = [XCTestCase grey_currentTestCase];

  NSMutableArray *logger = [[NSMutableArray alloc] init];
  NSString *reason = exception.reason;

  if (reason.length == 0) {
    reason = @"exception.reason was not provided";
  }

  [logger addObject:[NSString stringWithFormat:@"%@: %@", @"Exception Name", exception.name]];
  [logger addObject:[NSString stringWithFormat:@"%@: %@", @"Exception Reason", reason]];

  if (details.length > 0) {
    [logger addObject:[NSString stringWithFormat:@"%@: %@", @"Exception Details", details]];
  }

  NSString *logMessage = [logger componentsJoinedByString:@"\n"];
  NSString *screenshotPrefix = [NSString stringWithFormat:@"%@_%@",
                                                          [currentTestCase grey_testClassName],
                                                          [currentTestCase grey_testMethodName]];
  NSDictionary *appScreenshots =
      [GREYFailureScreenshotter generateAppScreenshotsWithPrefix:screenshotPrefix
                                                         failure:exception.name];

  NSArray *stackTrace = [NSThread callStackSymbols];
  NSString *log = [GREYFailureFormatter formatFailureForTestCase:currentTestCase
                                                    failureLabel:@"Exception"
                                                     failureName:exception.name
                                                        filePath:_fileName
                                                      lineNumber:_lineNumber
                                                    functionName:nil
                                                      stackTrace:stackTrace
                                                  appScreenshots:appScreenshots
                                                          format:@"%@\n", logMessage];

  if (currentTestCase) {
    [currentTestCase grey_markAsFailedAtLine:_lineNumber
                                      inFile:_fileName
                                 description:log];
  } else {
    // Happens when exception is thrown outside a valid test context (i.e. +setUp, +tearDown, etc.)
    [[GREYFrameworkException exceptionWithName:exception.name
                                        reason:log
                                      userInfo:nil] raise];
  }
}

@end
