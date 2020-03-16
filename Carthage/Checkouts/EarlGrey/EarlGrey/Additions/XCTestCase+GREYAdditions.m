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

#import "Additions/XCTestCase+GREYAdditions.h"

#include <objc/runtime.h>

#import "Common/GREYFatalAsserts.h"
#import "Common/GREYSwizzler.h"
#import "Common/GREYTestCaseInvocation.h"
#import "Core/GREYAutomationSetup.h"
#import "Exception/GREYFrameworkException.h"

/**
 *  Stack of XCTestCase objects being being executed. This enables the tracking of different nested
 *  tests that have been invoked. If empty, then the run is outside the context of a running test.
 */
static NSMutableArray<XCTestCase *> *gExecutingTestCaseStack;

/**
 *  Name of the exception that's thrown to interrupt current test execution.
 */
static NSString *const kInternalTestInterruptException = @"EarlGreyInternalTestInterruptException";

// Extern constants.
NSString *const kGREYXCTestCaseInstanceWillSetUp = @"GREYXCTestCaseInstanceWillSetUp";
NSString *const kGREYXCTestCaseInstanceDidSetUp = @"GREYXCTestCaseInstanceDidSetUp";
NSString *const kGREYXCTestCaseInstanceWillTearDown = @"GREYXCTestCaseInstanceWillTearDown";
NSString *const kGREYXCTestCaseInstanceDidTearDown = @"GREYXCTestCaseInstanceDidTearDown";
NSString *const kGREYXCTestCaseInstanceDidPass = @"GREYXCTestCaseInstanceDidPass";
NSString *const kGREYXCTestCaseInstanceDidFail = @"GREYXCTestCaseInstanceDidFail";
NSString *const kGREYXCTestCaseInstanceDidFinish = @"GREYXCTestCaseInstanceDidFinish";
NSString *const kGREYXCTestCaseNotificationKey = @"GREYXCTestCaseNotificationKey";

@implementation XCTestCase (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    BOOL swizzleSuccess = [swizzler swizzleClass:self
                           replaceInstanceMethod:@selector(invokeTest)
                                      withMethod:@selector(grey_invokeTest)];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle XCTestCase::invokeTest");

    SEL recordFailSEL = @selector(recordFailureWithDescription:inFile:atLine:expected:);
    SEL grey_recordFailSEL = @selector(grey_recordFailureWithDescription:inFile:atLine:expected:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:recordFailSEL
                                 withMethod:grey_recordFailSEL];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle "
                               @"XCTestCase::recordFailureWithDescription:inFile:atLine:expected:");
    // As soon as XCTest is loaded, we setup the EarlGrey crash handlers so that any issue is
    // tracked at the earliest. Also, we turn on accessibility for the simulator since it needs to
    // be enabled before main is called.
    [[GREYAutomationSetup sharedInstance] prepareOnLoad];
    gExecutingTestCaseStack = [[NSMutableArray alloc] init];
  }
}

+ (XCTestCase *)grey_currentTestCase {
  return [gExecutingTestCaseStack lastObject];
}

- (void)grey_recordFailureWithDescription:(NSString *)description
                                   inFile:(NSString *)filePath
                                   atLine:(NSUInteger)lineNumber
                                 expected:(BOOL)expected {
  [self grey_setStatus:kGREYXCTestCaseStatusFailed];
  INVOKE_ORIGINAL_IMP4(void,
                       @selector(grey_recordFailureWithDescription:inFile:atLine:expected:),
                       description,
                       filePath,
                       lineNumber,
                       expected);
}

- (NSString *)grey_testMethodName {
  // XCTest.name is represented as "-[<testClassName> <testMethodName>]"
  NSCharacterSet *charsetToStrip =
      [NSMutableCharacterSet characterSetWithCharactersInString:@"-[]"];

  // Resulting string after stripping: <testClassName> <testMethodName>
  NSString *strippedName = [self.name stringByTrimmingCharactersInSet:charsetToStrip];
  // Split string by whitespace.
  NSArray *testClassAndTestMethods =
      [strippedName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  // Test method name will be 2nd item in the array.
  if (testClassAndTestMethods.count <= 1) {
    return nil;
  } else {
    return [testClassAndTestMethods objectAtIndex:1];
  }
}

- (NSString *)grey_testClassName {
  return NSStringFromClass([self class]);
}

- (GREYXCTestCaseStatus)grey_status {
  id status = objc_getAssociatedObject(self, @selector(grey_status));
  return (GREYXCTestCaseStatus)[status unsignedIntegerValue];
}

- (NSString *)grey_localizedTestOutputsDirectory {
  NSString *localizedTestOutputsDir =
      objc_getAssociatedObject(self, @selector(grey_localizedTestOutputsDirectory));

  if (localizedTestOutputsDir == nil) {
    NSString *testClassName = [self grey_testClassName];
    NSString *testMethodName = [self grey_testMethodName];
    GREYFatalAssertWithMessage(testMethodName,
                               @"There's no current test method for the current test case: %@",
                               self);

    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask,
                                                                 YES);
    GREYFatalAssertWithMessage(documentPaths.count > 0,
                               @"At least one path for the user documents dir should exist.");
    NSString *testOutputsDir =
        [documentPaths.firstObject stringByAppendingPathComponent:@"earlgrey-test-outputs"];

    NSString *testMethodDirName =
        [NSString stringWithFormat:@"%@/%@", testClassName, testMethodName];
    NSString *testSpecificOutputsDir =
        [testOutputsDir stringByAppendingPathComponent:testMethodDirName];

    localizedTestOutputsDir = [testSpecificOutputsDir stringByStandardizingPath];

    objc_setAssociatedObject(self,
                             @selector(grey_localizedTestOutputsDirectory),
                             localizedTestOutputsDir,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  return localizedTestOutputsDir;
}

- (void)grey_markAsFailedAtLine:(NSUInteger)line
                         inFile:(NSString *)file
                    description:(NSString *)description {
  self.continueAfterFailure = NO;
  [self recordFailureWithDescription:description inFile:file atLine:line expected:NO];
  // If the test fails outside of the main thread in a nested runloop it will not be interrupted
  // until it's back in the outer most runloop. Raise an exception to interrupt the test immediately
  [[GREYFrameworkException exceptionWithName:kInternalTestInterruptException
                                      reason:@"Immediately halt execution of testcase"] raise];
}

#pragma mark - Private

- (BOOL)grey_isSwizzled {
  return [objc_getAssociatedObject([self class], @selector(grey_isSwizzled)) boolValue];
}

- (void)grey_markSwizzled {
  objc_setAssociatedObject([self class],
                           @selector(grey_isSwizzled),
                           @(YES),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)grey_invokeTest {
  @autoreleasepool {
    static dispatch_once_t prepareForAutomation;
    dispatch_once(&prepareForAutomation, ^{
      // Accessibility for a device is enabled here since for a device it must be enabled after
      // XCTest has been loaded. We also turn off autocorrect and predictive text to not interfere
      // with EarlGrey's typing.
      [[GREYAutomationSetup sharedInstance] preparePostLoad];
    });
    if (![self grey_isSwizzled]) {
      GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
      Class selfClass = [self class];
      // Swizzle the setUp and tearDown for this test to allow observing different execution states
      // of the test.
      IMP setUpIMP = [self methodForSelector:@selector(grey_setUp)];
      BOOL swizzleSuccess = [swizzler swizzleClass:selfClass
                                 addInstanceMethod:@selector(grey_setUp)
                                withImplementation:setUpIMP
                      andReplaceWithInstanceMethod:@selector(setUp)];
      GREYFatalAssertWithMessage(swizzleSuccess,
                                 @"Cannot swizzle %@ setUp", NSStringFromClass(selfClass));

      // Swizzle tearDown.
      IMP tearDownIMP = [self methodForSelector:@selector(grey_tearDown)];
      swizzleSuccess = [swizzler swizzleClass:selfClass
                            addInstanceMethod:@selector(grey_tearDown)
                           withImplementation:tearDownIMP
                 andReplaceWithInstanceMethod:@selector(tearDown)];
      GREYFatalAssertWithMessage(swizzleSuccess,
                                 @"Cannot swizzle %@ tearDown", NSStringFromClass(selfClass));
      [self grey_markSwizzled];
    }

    // Change invocation type to GREYTestCaseInvocation to set grey_status to failed if the test
    // method throws an exception. This ensure grey_status is accurate in the test case teardown.
    Class originalInvocationClass =
        object_setClass(self.invocation, [GREYTestCaseInvocation class]);

    @try {
      [gExecutingTestCaseStack addObject:self];
      [self grey_setStatus:kGREYXCTestCaseStatusUnknown];
      INVOKE_ORIGINAL_IMP(void, @selector(grey_invokeTest));

      // The test may have been marked as failed if a failure was recorded with the
      // recordFailureWithDescription:... method. In this case, we can't consider the test has
      // passed.
      if ([self grey_status] != kGREYXCTestCaseStatusFailed) {
        [self grey_setStatus:kGREYXCTestCaseStatusPassed];
      }
    } @catch (NSException *exception) {
      [self grey_setStatus:kGREYXCTestCaseStatusFailed];
      if (![exception.name isEqualToString:kInternalTestInterruptException]) {
        @throw;
      }
    } @finally {
      switch ([self grey_status]) {
        case kGREYXCTestCaseStatusFailed:
          [self grey_sendNotification:kGREYXCTestCaseInstanceDidFail];
          break;
        case kGREYXCTestCaseStatusPassed:
          [self grey_sendNotification:kGREYXCTestCaseInstanceDidPass];
          break;
        case kGREYXCTestCaseStatusUnknown:
          self.continueAfterFailure = YES;
          [self recordFailureWithDescription:@"Test has finished with unknown status."
                                      inFile:@__FILE__
                                      atLine:__LINE__
                                    expected:NO];
          break;
      }
      object_setClass(self.invocation, originalInvocationClass);
      [self grey_sendNotification:kGREYXCTestCaseInstanceDidFinish];
      // We only reset the current test case after all possible notifications have been sent.
      [gExecutingTestCaseStack removeLastObject];
    }
  }
}

/**
 *  A swizzled implementation for XCTestCase::setUp.
 *
 *  @remark These methods need to be added to each instance of XCTestCase because we don't expect
 *          test to invoke <tt> [super setUp] </tt>.
 */
- (void)grey_setUp {
  [self grey_sendNotification:kGREYXCTestCaseInstanceWillSetUp];
  INVOKE_ORIGINAL_IMP(void, @selector(grey_setUp));
  [self grey_sendNotification:kGREYXCTestCaseInstanceDidSetUp];
}

/**
 *  A swizzled implementation for XCTestCase::tearDown.
 *
 *  @remark These methods need to be added to each instance of XCTestCase because we don't expect
 *          tests to invoke <tt> [super tearDown] </tt>.
 */
- (void)grey_tearDown {
  [self grey_sendNotification:kGREYXCTestCaseInstanceWillTearDown];
  INVOKE_ORIGINAL_IMP(void, @selector(grey_tearDown));
  [self grey_sendNotification:kGREYXCTestCaseInstanceDidTearDown];
}

/**
 *  Posts a notification with the specified @c notificationName using the default
 *  NSNotificationCenter and with the @c userInfo containing the current test case.
 *
 *  @param notificationName Name of the notification to be posted.
 */
- (void)grey_sendNotification:(NSString *)notificationName {
  NSDictionary *userInfo = @{ kGREYXCTestCaseNotificationKey : self };
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                      object:self
                                                    userInfo:userInfo];
}

#pragma mark - Package Internal

- (void)grey_setStatus:(GREYXCTestCaseStatus)status {
  objc_setAssociatedObject(self,
                           @selector(grey_status),
                           @(status),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
