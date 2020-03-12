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

#import "Additions/NSObject+GREYAdditions.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface NSObject_GREYAdditionsTest : GREYBaseTest
@end

@implementation NSObject_GREYAdditionsTest {
  BOOL _delayedExecution;
  NSUInteger _delayedExecutionCount;
  NSUInteger _delayedExecutionWithParamCount;
  NSUInteger _delayedExecutionWithoutParamCount;
}

- (void)setUp {
  [super setUp];
  _delayedExecution = NO;
  _delayedExecutionCount = 0;
  _delayedExecutionWithParamCount = 0;
  _delayedExecutionWithoutParamCount = 0;
}

- (void)testPerformSelectorAfterDelayOnMainThreadIsTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 1u);
}

- (void)testPerformSelectorAfterDelayWithBlockObjectOnMainThreadIsTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  __block BOOL performed = NO;
  [[self class] performSelector:@selector(grey_delayedExecutionSelectorBlockParam:) withObject:^{
    performed = YES;
  } afterDelay:delay];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(performed);
}

- (void)testPerformSelectorAfterDelayOnMainThreadIsTracked_nilObject {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:delay];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 1u);
}

- (void)testMultiplePerformSelectorAfterDelayOnMainThreadIsTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:0];
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:0];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 4u);
}

- (void)testMultiplePerformSelectorAfterDelayOnMainThreadIsTracked_nilObject {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:delay];
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:delay];
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:0];
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:0];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 4u);
}

- (void)testPerformSelectorAfterDelayOnMainThreadIsNotTrackedAfterCancel {
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:0];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 0u);

  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(grey_delayedExecutionSelector:)
                                             object:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 0u);
}

- (void)testPerformSelectorAfterDelayOnMainThreadIsNotTrackedAfterCancel_nilObject {
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:0];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 0u);

  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(grey_delayedExecutionSelector:)
                                             object:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
  XCTAssertEqual(_delayedExecutionCount, 0u);
}

- (void)testMultiplePerformSelectorAfterDelayOnMainThreadAfterCancel {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  // This will be executed.
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  // This will be executed.
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];
  // This will be cancelled.
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:delay];
  // This will be cancelled.
  [self performSelector:@selector(grey_delayedExecutionSelector) withObject:nil afterDelay:0];
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(grey_delayedExecutionSelector)
                                             object:nil];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(_delayedExecution);
  XCTAssertEqual(_delayedExecutionWithoutParamCount, 0u);
  XCTAssertEqual(_delayedExecutionWithParamCount, 2u);
  XCTAssertEqual(_delayedExecutionCount, 2u);
}

- (void)testCancelPerformSelectorAfterDelayOnMainThread {
  XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self
                                                            selector:@selector(setUp)
                                                              object:self]);
  XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self
                                                            selector:@selector(setUp)
                                                              object:nil]);
  XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self]);
}

- (void)testCancelPerformSelectorAfterDelayOnBackgroundThread {
  NSOperationQueue *backgroundQ = [[NSOperationQueue alloc] init];
  XCTestExpectation *expectation = [self expectationWithDescription:@"backgroundQ finished."];
  [backgroundQ addOperationWithBlock:^{
    XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self
                                                              selector:@selector(setUp)
                                                                object:self]);
    XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self
                                                              selector:@selector(setUp)
                                                                object:nil]);
    XCTAssertNoThrow([NSObject cancelPreviousPerformRequestsWithTarget:self]);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testPerformSelectorAfterMaxDelayOnMainThreadIsNotTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) * 2;
  [self performSelector:@selector(grey_delayedExecutionSelector:) withObject:self afterDelay:delay];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertFalse(_delayedExecution);
}

- (void)testPerformSelectorAfterDelayOnBackgroundThreadIsNotTracked {
  double delay = GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration) / 2;
  NSOperationQueue *backgroundQ = [[NSOperationQueue alloc] init];
  XCTestExpectation *expectation = [self expectationWithDescription:@"backgroundQ finished."];
  [backgroundQ addOperationWithBlock:^{
    [self performSelector:@selector(grey_delayedExecutionSelector:)
               withObject:self
               afterDelay:delay];
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
  XCTAssertFalse(_delayedExecution);
}

- (void)testViewContainingSelfReturnsSuperViewForUIViews {
  UIView *aSubView = [[UIView alloc] init];
  UIView *aView = [[UIView alloc] init];
  [aView addSubview:aSubView];
  XCTAssertEqualObjects([aSubView grey_viewContainingSelf], aView);
}

- (void)testViewContainingSelfReturnsAccessibilityContainerForNonUIViews {
  UIView *containersContainer = [[UIView alloc] init];
  UIAccessibilityElement *container =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:containersContainer];
  UIAccessibilityElement *element =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:container];

  // Set up hierarchy: containersContainer -> container -> element
  element.accessibilityContainer = container;
  container.accessibilityContainer = containersContainer;
  XCTAssertEqualObjects([element grey_viewContainingSelf], containersContainer);
}

- (void)testViewContainingSelfReturnsWebViewForWebAccessibilityObjectWrapper {
  id webAccessibilityWrapper = [[NSClassFromString(@"WebAccessibilityObjectWrapper") alloc] init];
  id element = [OCMockObject partialMockForObject:webAccessibilityWrapper];
  id viewContainer = [OCMockObject mockForClass:NSClassFromString(@"UIView")];
  UIAccessibilityElement *container =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewContainer];
  id webViewContainer = [OCMockObject mockForClass:NSClassFromString(@"UIWebView")];

  // Set up hierarchy: webViewContainer -> viewContainer -> container -> element
  [[[element stub] andReturn:container] grey_container];
  [[[viewContainer stub] andReturn:webViewContainer] grey_container];
  [[[webViewContainer stub] andReturn:nil] grey_container];

  XCTAssertEqualObjects([element grey_viewContainingSelf], webViewContainer);
}

- (void)testNilValuesNotShownInDescription {
  // This test makes sure that no nil attributes show up
  UILabel *label = [[UILabel alloc] init];
  label.isAccessibilityElement = YES;
  label.accessibilityIdentifier = nil;
  label.accessibilityLabel = nil;
  label.text = nil;
  label.frame = CGRectZero;
  label.opaque = YES;
  label.hidden = YES;
  label.alpha = 0.0;
  NSString *expectedDescription = [NSString stringWithFormat:@"<UILabel:%p; AX=Y; "
      @"AX.frame={{0, 0}, {0, 0}}; AX.activationPoint={0, 0}; "
      @"AX.traits='UIAccessibilityTraitStaticText'; AX.focused='N'; "
      @"frame={{0, 0}, {0, 0}}; opaque; hidden; alpha=0; UIE=N; text=''>",
      label];
  XCTAssertEqualObjects(expectedDescription, [label grey_description]);
}

- (void)testNonNilValuesShownInDescription {
  // This test makes sure that all instantiated attributes show up correctly
  UILabel *labelWithNonNilFeatures = [[UILabel alloc] init];
  labelWithNonNilFeatures.accessibilityIdentifier = @"Identifier";
  labelWithNonNilFeatures.accessibilityLabel = @"LabelWithNonNilFeatures";
  labelWithNonNilFeatures.accessibilityFrame = CGRectMake(1, 2, 3, 4);
  labelWithNonNilFeatures.text = @"SampleText";
  labelWithNonNilFeatures.frame = CGRectMake(3, 3, 3, 3);
  labelWithNonNilFeatures.opaque = NO;
  labelWithNonNilFeatures.hidden = NO;
  labelWithNonNilFeatures.userInteractionEnabled = YES;
  labelWithNonNilFeatures.alpha = 0.50;
  labelWithNonNilFeatures.isAccessibilityElement = YES;

  NSString *expectedDescription = [NSString stringWithFormat:@"<UILabel:%p; AX=Y; "
      @"AX.id='Identifier'; AX.label='LabelWithNonNilFeatures'; "
      @"AX.frame={{1, 2}, {3, 4}}; AX.activationPoint={2.5, 4}; "
      @"AX.traits='UIAccessibilityTraitStaticText'; AX.focused='N'; frame={{3, 3}, {3, 3}}; "
      @"alpha=0.5; text='SampleText'>", labelWithNonNilFeatures];

  XCTAssertEqualObjects(expectedDescription, [labelWithNonNilFeatures grey_description]);
}

- (void)testAccessibilityIdentifierIsShownForNonAccessibilityElements {
  UITextField *view = [[UITextField alloc] init];
  view.isAccessibilityElement = NO;
  view.accessibilityIdentifier = @"test.acc.id";
  view.accessibilityLabel = nil;
  view.frame = CGRectZero;
  view.opaque = YES;
  view.hidden = YES;
  view.userInteractionEnabled = YES;
  view.alpha = 0;
  view.enabled = NO;
  view.accessibilityTraits = UIAccessibilityTraitNotEnabled || UIAccessibilityTraitButton;
  NSString *expectedDescription = [NSString stringWithFormat:@"<UITextField:%p; AX=N; "
      @"AX.id='test.acc.id'; AX.frame={{0, 0}, {0, 0}}; AX.activationPoint={0, 0}; "
      @"AX.traits='UIAccessibilityTraitButton,UIAccessibilityTraitNotEnabled'; AX.focused='N'; "
      @"frame={{0, 0}, {0, 0}}; opaque; hidden; alpha=0; disabled; text=''>", view];
  XCTAssertEqualObjects(expectedDescription, [view grey_description]);
}

- (void)testShortDescriptionWithNoAXIdAndLabel {
  UITextField *view = [[UITextField alloc] init];
  NSString *expectedDescription = @"UITextField";
  XCTAssertEqualObjects([view grey_shortDescription], expectedDescription);
}

- (void)testShortDescriptionWithAxId {
  UITextField *view = [[UITextField alloc] init];
  view.accessibilityIdentifier = @"viewAxId";
  NSString *expectedDescription = @"UITextField; AX.id='viewAxId'";
  XCTAssertEqualObjects([view grey_shortDescription], expectedDescription);
}

- (void)testShortDescriptionWithAXLabel {
  UITextField *view = [[UITextField alloc] init];
  view.accessibilityLabel = @"viewAxLabel";
  NSString *expectedDescription = @"UITextField; AX.label='viewAxLabel'";
  XCTAssertEqualObjects([view grey_shortDescription], expectedDescription);
}

- (void)testShortDescriptionWithAXIdAndLabel {
  UITextField *view = [[UITextField alloc] init];
  view.accessibilityIdentifier = @"viewAxId";
  view.accessibilityLabel = @"viewAxLabel";
  NSString *expectedDescription = @"UITextField; AX.id='viewAxId'; AX.label='viewAxLabel'";
  XCTAssertEqualObjects([view grey_shortDescription], expectedDescription);
}

#pragma mark - Private

+ (void)grey_delayedExecutionSelectorBlockParam:(void(^)(void))block {
  block();
}

- (void)grey_delayedExecutionSelector {
  _delayedExecution = YES;
  _delayedExecutionWithoutParamCount++;
  _delayedExecutionCount++;
}

- (void)grey_delayedExecutionSelector:(id)selfParam {
  XCTAssertEqual(selfParam, self, @"Must pass in self as the first param to selector.");
  _delayedExecution = YES;
  _delayedExecutionWithParamCount++;
  _delayedExecutionCount++;
}

@end
