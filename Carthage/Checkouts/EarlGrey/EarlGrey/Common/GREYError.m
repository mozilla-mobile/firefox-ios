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

#import "Common/GREYError.h"

#import "Additions/NSError+GREYAdditions.h"
#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYElementHierarchy.h"
#import "Common/GREYError+Internal.h"
#import "Common/GREYObjectFormatter.h"
#import "Common/GREYScreenshotUtil.h"

NSString *const kGREYGenericErrorDomain = @"com.google.earlgrey.GenericErrorDomain";
NSInteger const kGREYGenericErrorCode = 0;
NSString *const kErrorDetailFailureNameKey = @"Failure Name";
NSString *const kErrorDetailActionNameKey = @"Action Name";
NSString *const kErrorDetailAssertCriteriaKey = @"Assertion Criteria";
NSString *const kErrorDetailRecoverySuggestionKey = @"Recovery Suggestion";

NSString *const kErrorDomainKey = @"Error Domain";
NSString *const kErrorCodeKey = @"Error Code";
NSString *const kErrorDescriptionKey = @"Description";
NSString *const kErrorFailureReasonKey = @"Failure Reason";

NSString *const kErrorTestCaseClassNameKey = @"TestCase Class";
NSString *const kErrorTestCaseMethodNameKey = @"TestCase Method";
NSString *const kErrorFilePathKey = @"File Path";
NSString *const kErrorFileNameKey = @"File Name";
NSString *const kErrorLineKey = @"Line";
NSString *const kErrorFunctionNameKey = @"Function Name";
NSString *const kErrorUserInfoKey = @"User Info";
NSString *const kErrorErrorInfoKey = @"Error Info";
NSString *const kErrorBundleIDKey = @"Bundle ID";
NSString *const kErrorStackTraceKey = @"Stack Trace";
NSString *const kErrorAppUIHierarchyKey = @"App UI Hierarchy";
NSString *const kErrorAppScreenShotsKey = @"App Screenshots";
NSString *const kErrorDescriptionGlossaryKey = @"Description Glossary";

GREYError *I_GREYErrorMake(NSString *domain,
                           NSInteger code,
                           NSDictionary *userInfo,
                           NSString *filePath,
                           NSUInteger line,
                           NSString *functionName,
                           NSDictionary *errorInfo,
                           NSArray *stackTrace) {
  GREYError *error = [[GREYError alloc] initWithDomain:domain
                                                  code:code
                                              userInfo:userInfo];

  error.filePath = filePath;
  error.line = line;
  error.functionName = functionName;
  error.bundleID = [[NSBundle mainBundle] bundleIdentifier];
  error.errorInfo = errorInfo;
  error.stackTrace = stackTrace;
  error.appUIHierarchy = [GREYElementHierarchy hierarchyStringForAllUIWindows];
  return error;
}

@implementation GREYError {
  NSString *_testCaseClassName;
  NSString *_testCaseMethodName;
  NSString *_filePath;
  NSUInteger _line;
  NSString *_functionName;
  NSDictionary *_errorInfo;
  NSString *_bundleID;
  NSArray  *_stackTrace;
  NSString *_appUIHierarchy;
  NSDictionary *_appScreenshots;
}

@dynamic nestedError;

- (instancetype)initWithDomain:(NSString *)domain
                          code:(NSInteger)code
                      userInfo:(NSDictionary *)dict {
  return [self initWithDomain:domain
                         code:code
                     userInfo:dict
                     testCase:[XCTestCase grey_currentTestCase]];
}

- (instancetype)initWithDomain:(NSString *)domain
                          code:(NSInteger)code
                      userInfo:(NSDictionary *)dict
                      testCase:(XCTestCase *)testCase {
  self = [super initWithDomain:domain code:code userInfo:dict];
  if (self) {
    _testCaseClassName = [testCase grey_testClassName];
    _testCaseMethodName = [testCase grey_testMethodName];
  }
  return self;
}

- (void)setTestCaseClassName:(NSString *)testCaseClassName {
  _testCaseMethodName = testCaseClassName;
}

- (void)setTestCaseMethodName:(NSString *)testCaseMethodName {
  _testCaseMethodName = testCaseMethodName;
}

- (void)setFilePath:(NSString *)filePath {
  _filePath = filePath;
}

- (void)setLine:(NSUInteger)line {
  _line = line;
}

- (void)setFunctionName:(NSString *)functionName {
  _functionName = functionName;
}

- (void)setErrorInfo:(NSDictionary *)errorInfo {
  _errorInfo = errorInfo;
}

- (void)setBundleID:(NSString *)bundleID {
  _bundleID = bundleID;
}

- (void)setStackTrace:(NSArray *)stackTrace {
  _stackTrace = stackTrace;
}

- (void)setAppUIHierarchy:(NSString *)appUIHierarchy {
  _appUIHierarchy = appUIHierarchy;
}

- (void)setAppScreenshots:(NSDictionary *)appScreenshots {
  _appScreenshots = appScreenshots;
}

- (NSError *)nestedError {
  return self.userInfo[NSUnderlyingErrorKey];
}

+ (instancetype)errorWithDomain:(NSString *)domain
                           code:(NSInteger)code
                       userInfo:(NSDictionary *)dict
                       testCase:(XCTestCase *)testCase {
  return [self errorWithDomain:domain code:code userInfo:dict testCase:testCase];
}

- (NSString *)description {
  return [GREYObjectFormatter formatDictionary:[self grey_descriptionDictionary]
                                        indent:kGREYObjectFormatIndent
                                     hideEmpty:YES
                                      keyOrder:nil];
}

- (NSDictionary *)grey_descriptionDictionary {
  NSMutableDictionary *descriptionDictionary = [[super grey_descriptionDictionary] mutableCopy];

  if (!descriptionDictionary) {
    return nil;
  }

  descriptionDictionary[kErrorTestCaseClassNameKey] = _testCaseClassName;
  descriptionDictionary[kErrorTestCaseMethodNameKey] = _testCaseMethodName;
  descriptionDictionary[kErrorFileNameKey] = [_filePath lastPathComponent];
  descriptionDictionary[kErrorLineKey] = [NSString stringWithFormat:@"%ld", (unsigned long)_line];
  descriptionDictionary[kErrorFunctionNameKey] = _functionName;
  descriptionDictionary[kErrorUserInfoKey] = self.userInfo;
  descriptionDictionary[kErrorErrorInfoKey] = _errorInfo;
  descriptionDictionary[kErrorBundleIDKey] = _bundleID;
  descriptionDictionary[kErrorStackTraceKey] = _stackTrace;
  descriptionDictionary[kErrorAppUIHierarchyKey] = _appUIHierarchy;
  descriptionDictionary[kErrorAppScreenShotsKey] = _appScreenshots;
  descriptionDictionary[kErrorDescriptionGlossaryKey] = _descriptionGlossary;

  return descriptionDictionary;
}

+ (NSArray *)grey_nestedErrorDictionariesForError:(NSError *)error {
  if (!error) {
    return nil;
  }

  NSMutableArray *errorStack = [[NSMutableArray alloc] init];
  NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
  if (underlyingError) {
    NSArray *errorDescriptions = [GREYError grey_nestedErrorDictionariesForError:underlyingError];
    [errorStack addObjectsFromArray:errorDescriptions];
  }

  NSDictionary *descriptions = [error grey_descriptionDictionary];
  // For GREYError, we need to remove some of the fields.
  if ([error isKindOfClass:[GREYError class]]) {
    NSMutableDictionary *mutableDescriptions = [descriptions mutableCopy];

    [mutableDescriptions removeObjectForKey:kErrorUserInfoKey];
    [mutableDescriptions removeObjectForKey:kErrorErrorInfoKey];
    [mutableDescriptions removeObjectForKey:kErrorBundleIDKey];
    [mutableDescriptions removeObjectForKey:kErrorStackTraceKey];
    [mutableDescriptions removeObjectForKey:kErrorAppUIHierarchyKey];
    [mutableDescriptions removeObjectForKey:kErrorAppScreenShotsKey];
    descriptions = mutableDescriptions;
  }
  [errorStack addObject:descriptions];

  return errorStack;
}

+ (NSString *)grey_nestedDescriptionForError:(NSError *)error {
  NSArray *descriptions = [GREYError grey_nestedErrorDictionariesForError:error];
  if (descriptions.count == 0) {
    return @"";
  }

  NSArray *keyOrder = @[ kErrorDescriptionKey,
                         kErrorDescriptionGlossaryKey,
                         kErrorDomainKey,
                         kErrorCodeKey,
                         kErrorFileNameKey,
                         kErrorFunctionNameKey,
                         kErrorLineKey,
                         kErrorTestCaseClassNameKey,
                         kErrorTestCaseMethodNameKey ];

  return [GREYObjectFormatter formatArray:descriptions
                                   indent:kGREYObjectFormatIndent
                                 keyOrder:keyOrder];
}

@end
