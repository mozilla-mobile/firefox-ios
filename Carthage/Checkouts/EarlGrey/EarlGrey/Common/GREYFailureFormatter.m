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

#import "Common/GREYFailureFormatter.h"

#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYElementHierarchy.h"
#import "Common/GREYError+Internal.h"
#import "Common/GREYError.h"
#import "Common/GREYObjectFormatter.h"
#import "Common/GREYVisibilityChecker.h"

@implementation GREYFailureFormatter

+ (NSString *)formatFailureForError:(GREYError *)error
                          excluding:(NSArray *)excluding
                       failureLabel:(NSString *)failureLabel
                        failureName:(NSString *)failureName
                             format:(NSString *)format, ... {
  NSString *errorDescription;
  va_list argList;
  va_start(argList, format);
  errorDescription = [[NSString alloc] initWithFormat:format arguments:argList];
  va_end(argList);

  return [self formatFailureForError:error
                           excluding:excluding
                        failureLabel:failureLabel
                         failureName:failureName
                    errorDescription:errorDescription];
}

+ (NSString *)formatFailureForTestCase:(XCTestCase *)testCase
                          failureLabel:(NSString *)failureLabel
                           failureName:(NSString *)failureName
                              filePath:(NSString *)filePath
                            lineNumber:(NSUInteger)lineNumber
                          functionName:(NSString *)functionName
                            stackTrace:(NSArray *)stackTrace
                        appScreenshots:(NSDictionary *)appScreenshots
                                format:(NSString *)format, ... {
  va_list argList;
  va_start(argList, format);
  NSString *errorDescription = [[NSString alloc] initWithFormat:format arguments:argList];
  va_end(argList);
  GREYError *error = I_GREYErrorMake(kGREYGenericErrorDomain,
                                     kGREYGenericErrorCode,
                                     nil,
                                     filePath,
                                     lineNumber,
                                     functionName,
                                     nil,
                                     stackTrace);

  error.testCaseClassName = [testCase grey_testClassName];
  error.testCaseMethodName = [testCase grey_testMethodName];
  error.appScreenshots = appScreenshots;

  NSArray *excluding = @[ kErrorFilePathKey, kErrorLineKey, kErrorDescriptionGlossaryKey ];
  return [self formatFailureForError:error
                           excluding:excluding
                        failureLabel:failureLabel
                         failureName:failureName
                    errorDescription:errorDescription];
}

+ (NSString *)formatFailureForError:(GREYError *)error
                          excluding:(NSArray *)excluding
                       failureLabel:(NSString *)failureLabel
                        failureName:(NSString *)failureName
                   errorDescription:(NSString *)errorDescription {
  if (failureLabel.length == 0) {
    failureLabel = @"Failure";
  }

  NSMutableArray *logger = [[NSMutableArray alloc] init];
  [logger addObject:[NSString stringWithFormat:@"%@: %@\n", failureLabel, failureName]];

  if (![excluding containsObject:kErrorFilePathKey]) {
    [logger addObject:[NSString stringWithFormat:@"File: %@\n", error.filePath]];
  }
  if (![excluding containsObject:kErrorLineKey]) {
    [logger addObject:[NSString stringWithFormat:@"Line: %lu\n", (unsigned long)error.line]];
  }

  if (![excluding containsObject:kErrorFunctionNameKey]) {
    if (error.functionName) {
      [logger addObject:[NSString stringWithFormat:@"Function: %@\n", error.functionName]];
    }
  }

  if (![excluding containsObject:kErrorDescriptionKey]) {
    [logger addObject:errorDescription];
  }

  // additional info to format
  if (![excluding containsObject:kErrorDescriptionKey]) {
    [logger addObject:[NSString stringWithFormat:@"Bundle ID: %@\n", error.bundleID]];
  }
  if (![excluding containsObject:kErrorStackTraceKey]) {
    [logger addObject:[NSString stringWithFormat:@"Stack Trace: %@\n", error.stackTrace]];
  }

  // Add screenshots.
  if (![excluding containsObject:kErrorAppScreenShotsKey]) {
    NSArray *keyOrder = @[ kScreenshotAtFailure,
                           kScreenshotBeforeImage,
                           kScreenshotExpectedAfterImage,
                           kScreenshotActualAfterImage ];

    NSString *screenshots = [GREYObjectFormatter formatDictionary:error.appScreenshots
                                                           indent:kGREYObjectFormatIndent
                                                        hideEmpty:YES
                                                         keyOrder:keyOrder];

    [logger addObject:[NSString stringWithFormat:@"Screenshots: %@\n", screenshots]];
  }

  // UI hierarchy and legend. Print windows from front to back, formatted for easier readability.
  if (![excluding containsObject:kErrorAppUIHierarchyKey]) {
    [logger addObject:@"UI hierarchy (ordered by window level, front to back as rendered):\n"];

    NSDictionary *legendLabels = @{ @"[Window 1]" : @"Frontmost Window",
                                    @"[AX]" : @"Accessibility",
                                    @"[UIE]" : @"User Interaction Enabled" };
    NSString *legendDescription = [GREYObjectFormatter formatDictionary:legendLabels
                                                                 indent:kGREYObjectFormatIndent
                                                              hideEmpty:NO
                                                               keyOrder:nil];
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", @"Legend", legendDescription]];
    // Append the hierarchy for all UI Windows in the app.
    [logger addObject:error.appUIHierarchy];
    [logger addObject:@"\n"];
  }

  if (![excluding containsObject:kErrorDescriptionGlossaryKey]) {
    NSString *glossary = [GREYObjectFormatter formatDictionary:error.descriptionGlossary
                                                        indent:kGREYObjectFormatIndent
                                                     hideEmpty:YES
                                                      keyOrder:nil];
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n",
                                                 kErrorDescriptionGlossaryKey,
                                                 glossary]];
  }

  return [logger componentsJoinedByString:@"\n"];
}

@end
