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

#import <XCTest/XCTest.h>

#import <EarlGrey/GREYAction.h>
#import <EarlGrey/GREYActionBlock.h>
#import <EarlGrey/GREYActions.h>
#import <EarlGrey/GREYBaseAction.h>
#import <EarlGrey/GREYScrollActionError.h>
#import <EarlGrey/GREYIdlingResource.h>
#import <EarlGrey/GREYAssertion.h>
#import <EarlGrey/GREYAssertionBlock.h>
#import <EarlGrey/GREYAssertionDefines.h>
#import <EarlGrey/GREYAssertions.h>
#import <EarlGrey/GREYConfiguration.h>
#import <EarlGrey/GREYConstants.h>
#import <EarlGrey/GREYDefines.h>
#import <EarlGrey/GREYElementHierarchy.h>
#import <EarlGrey/GREYScreenshotUtil.h>
#import <EarlGrey/GREYTestHelper.h>
#import <EarlGrey/EarlGreyImpl.h>
#import <EarlGrey/GREYElementFinder.h>
#import <EarlGrey/GREYElementInteraction.h>
#import <EarlGrey/GREYInteraction.h>
#import <EarlGrey/GREYFailureHandler.h>
#import <EarlGrey/GREYFrameworkException.h>
#import <EarlGrey/GREYAllOf.h>
#import <EarlGrey/GREYAnyOf.h>
#import <EarlGrey/GREYBaseMatcher.h>
#import <EarlGrey/GREYDescription.h>
#import <EarlGrey/GREYElementMatcherBlock.h>
#import <EarlGrey/GREYLayoutConstraint.h>
#import <EarlGrey/GREYMatcher.h>
#import <EarlGrey/GREYMatchers.h>
#import <EarlGrey/GREYNot.h>
#import <EarlGrey/GREYDataEnumerator.h>
#import <EarlGrey/GREYProvider.h>
#import <EarlGrey/GREYCondition.h>
#import <EarlGrey/GREYDispatchQueueIdlingResource.h>
#import <EarlGrey/GREYManagedObjectContextIdlingResource.h>
#import <EarlGrey/GREYNSTimerIdlingResource.h>
#import <EarlGrey/GREYOperationQueueIdlingResource.h>
#import <EarlGrey/GREYSyncAPI.h>
#import <EarlGrey/GREYUIThreadExecutor.h>

#define OCMOCK_STRUCT(atype, variable) \
  [NSValue valueWithBytes:&variable objCType:@encode(atype)]

// Declare the CGRect variable.
extern const CGRect kTestRect;

// Failure handler for EarlGrey unit tests.
@interface GREYUTFailureHandler : NSObject<GREYFailureHandler>
@end

// Base test class for every unit test.
// Each subclass must call through to super's implementation.
@interface GREYBaseTest : XCTestCase

// Currently active runloop mode.
@property(nonatomic, copy) NSString *activeRunLoopMode;

// Returns mocked shared application.
- (id)mockSharedApplication;
// Returns the real (original, unmocked) shared application.
- (id)realSharedApplication;

// Adds |screenshot| to be returned by GREYScreenshotUtil.
// |screenshot| is added to a list of screenshot that will be returned in-order at each invocation
// of takeScreenshot. After exhausting the screenshot list, subsequent invocations will return nil.
- (void)addToScreenshotListReturnedByScreenshotUtil:(UIImage *)screenshot;

#pragma mark - XCTestCase

- (void)setUp;
- (void)tearDown;

@end

@interface GREYScreenshotUtil (UnitTest)

// Original version of the save image method (for related test)
+ (NSString *)greyswizzled_fakeSaveImageAsPNG:(UIImage *)image
                                       toFile:(NSString *)filename
                                  inDirectory:(NSString *)directoryPath;

@end
