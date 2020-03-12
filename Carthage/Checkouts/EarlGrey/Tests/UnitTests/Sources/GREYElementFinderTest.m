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

#import <OCMock.h>

#import <EarlGrey/GREYElementFinder.h>
#import <EarlGrey/GREYElementMatcherBlock.h>
#import "Provider/GREYElementProvider.h"
#import "Provider/GREYUIWindowProvider.h"
#import "GREYBaseTest.h"
#import "GREYUTAccessibilityViewContainerView.h"

static NSMutableArray *gAppWindows;

@interface GREYElementFinderTest : GREYBaseTest
@end

@implementation GREYElementFinderTest {
  GREYElementFinder *elementFinder;
  UIWindow *rootWindow;
  UIView *leafA;
  UIView *leafB;
  UIView *leafA1;
  id<GREYMatcher> niceMatcher;
  GREYElementProvider *viewProvider;
}

- (void)setUp {
  [super setUp];

  rootWindow = [[UIWindow alloc] init];
  leafA = [[UIView alloc] init];
  leafB = [[UIButton alloc] init];
  leafA1 = [[UILabel alloc] init];
  [rootWindow addSubview:leafA];
  [rootWindow addSubview:leafB];
  [leafA addSubview:leafA1];
  niceMatcher = [GREYElementMatcherBlock matcherWithMatchesBlock:^BOOL(id item) {
    return YES;
  } descriptionBlock:^(id<GREYDescription> desc) { }];

  viewProvider = [[GREYElementProvider alloc]
                     initWithRootProvider:[GREYUIWindowProvider providerWithAllWindows]];

  gAppWindows = [[NSMutableArray alloc] init];
  [[[self.mockSharedApplication stub] andReturn:gAppWindows] windows];
}

- (void)testEmptyMatcherReturnsAllViews {
  [gAppWindows addObject:rootWindow];
  elementFinder = [[GREYElementFinder alloc] initWithMatcher:niceMatcher];

  NSArray *expectedArray = @[ rootWindow, leafB, leafA, leafA1 ];
  NSArray *resultArray = [elementFinder elementsMatchedInProvider:viewProvider];
  XCTAssertEqualObjects(expectedArray, resultArray, @"Should return the entire view hierarchy");
}

- (void)testNoMatchingViews {
  [gAppWindows addObject:rootWindow];
  id<GREYMatcher> switchMatcher = grey_kindOfClass([UISwitch class]);
  elementFinder = [[GREYElementFinder alloc] initWithMatcher:switchMatcher];
  XCTAssertEqual(0u,
                 [elementFinder elementsMatchedInProvider:viewProvider].count,
                 @"No matching views should return nil");
}

- (void)testMultipleMatchingViewsFromMultipleRoots {
  UIWindow *secondRoot = [[UIWindow alloc] init];
  UILabel *label1 = [[UILabel alloc] init];
  [secondRoot addSubview:label1];

  [gAppWindows addObjectsFromArray:@[ rootWindow, secondRoot ]];
  UILabel *label2 = [[UILabel alloc] init];
  [rootWindow addSubview:label2];
  id<GREYMatcher> labelMatcher = grey_kindOfClass([UILabel class]);
  elementFinder = [[GREYElementFinder alloc] initWithMatcher:labelMatcher];

  // second root should be matched first since it is top-most window.
  NSArray *expectedViews = @[ label1, label2, leafA1 ];
  NSArray *actualViews = [elementFinder elementsMatchedInProvider:viewProvider];
  XCTAssertEqualObjects(actualViews, expectedViews);
}

- (void)testMultipleMatchingViewsFromSingleRoot {
  [gAppWindows addObject:rootWindow];
  UILabel *label = [[UILabel alloc] init];
  [rootWindow addSubview:label];
  id<GREYMatcher> labelMatcher = grey_kindOfClass([UILabel class]);
  elementFinder = [[GREYElementFinder alloc] initWithMatcher:labelMatcher];
  NSArray *expectedViews = @[ label, leafA1 ];
  NSArray *actualViews = [elementFinder elementsMatchedInProvider:viewProvider];
  XCTAssertEqualObjects(actualViews, expectedViews, @"Matching views should be equal");
}

- (void)testElementFinderWorksWithHiddenElements {
  [gAppWindows addObject:rootWindow];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.isAccessibilityElement = YES;
  view.accessibilityLabel = @"hiddenAccessibilityLabel";
  [view setHidden:YES];
  [view setAlpha:1.0];
  [rootWindow addSubview:view];
  id<GREYMatcher> hiddenLabelMatcher = grey_accessibilityLabel(@"hiddenAccessibilityLabel");
  elementFinder = [[GREYElementFinder alloc] initWithMatcher:hiddenLabelMatcher];
  XCTAssertEqual([elementFinder elementsMatchedInProvider:viewProvider].count, 1u);
}

- (void)testDuplicatedViewsAsAccessibilityViewsDoNotAppearTwice {
  // An element may appear more than once in the UI hierarchy when because it can also appear as
  // an accessibility container's elements. To test that, we create an hierarchy where
  // |internalElement| appears twice and check if the enumeration only shows it once.
  UILabel *containerParent = [[UILabel alloc] init];

  UILabel *internalElement = [[UILabel alloc] init];
  GREYUTAccessibilityViewContainerView *container =
  [[GREYUTAccessibilityViewContainerView alloc] initWithElements:@[ internalElement ]];
  [containerParent addSubview:container];

  // |parent| contains both the container's parent and one of the container's
  // accessibility elements.
  UILabel *parent = [[UILabel alloc] init];
  [parent addSubview:containerParent];
  [parent addSubview:internalElement];

  // containerParent also shows in the initial list of elements. To make sure that its presence
  // won't affect the processing of the other elements, include an element after it.
  UIWindow *window = [[UIWindow alloc] init];

  // Mark it as an accessbility element.
  containerParent.accessibilityLabel = @"CP";
  containerParent.isAccessibilityElement = YES;

  // GREYElementFinder to find the @c containerParent.
  id<GREYMatcher> matcher = grey_accessibilityLabel(@"CP");
  GREYElementFinder *finder = [[GREYElementFinder alloc] initWithMatcher:matcher];

  GREYElementProvider *provider =
      [GREYElementProvider providerWithElements:@[ parent, containerParent, window ]];

  // Since @c containerParent is present in the hierarchy twice, it will be returned twice by the
  // GREYTraversalBFS instance, but the GREYElementFinder should only return it once.
  XCTAssertEqual([finder elementsMatchedInProvider:provider].count, 1u);
}

@end
