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

#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"
#import "GREYUTCustomAccessibilityView.h"

@interface GREYTraversalTests : GREYBaseTest

@end

@implementation GREYTraversalTests

- (void)testSortedChildViewsForNilCustomView {
  GREYUTCustomAccessibilityView *view = nil;
  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  XCTAssertThrows([traversal exploreImmediateChildren:view],
                  @"Since the view is nil, the method should throw and assertion");
}

- (void)testSortedChildViewsForNilView {
  UIView *view = nil;
  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  XCTAssertThrows([traversal exploreImmediateChildren:view],
                  @"Since the view is nil, the method should throw and assertion");
}

- (void)testSortedChildViewsForViewWithSingleSubview {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];

  [viewA accessibilityElementCount];
  [viewA addSubview:viewB];
  NSArray *orderedViews = @[viewB];

  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  NSArray *children = [traversal exploreImmediateChildren:viewA];
  XCTAssertEqualObjects(children, orderedViews);
}

- (void)testSortedChildViewsForViewWithSubviews {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewC = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  [viewA addSubview:viewB];
  [viewA addSubview:viewC];
  [viewA addSubview:viewD];
  NSArray *orderedViews = @[ viewD, viewC, viewB ];

  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  NSArray *children = [traversal exploreImmediateChildren:viewA];
  XCTAssertEqualObjects(children, orderedViews);
}

- (void)testSortedChildViewsForCustomViewWithSubviews {
  GREYUTCustomAccessibilityView *viewA =
  [[GREYUTCustomAccessibilityView alloc] initWithFrame:kTestRect];
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewC = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  [viewA addSubview:viewB];
  [viewA addSubview:viewC];
  [viewA addSubview:viewD];
  NSArray *orderedViews = @[ viewD, viewC, viewB ];

  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  NSArray *children = [traversal exploreImmediateChildren:viewA];
  XCTAssertEqualObjects(children, orderedViews);
}

- (void)testSortedChildViewsForCustomViewWithAXViews {
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewC = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  GREYUTCustomAccessibilityView *viewA =
  [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ viewB, viewC, viewD ]];
  NSArray *orderedViews = @[ viewD, viewC, viewB ];

  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  NSArray *children = [traversal exploreImmediateChildren:viewA];
  XCTAssertEqualObjects(children, orderedViews);
}

- (void)testSortedChildViewsForCustomViewWithSingleAXView {
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  GREYUTCustomAccessibilityView *viewA =
  [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[viewB]];
  NSArray *orderedViews = @[viewB];

  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  NSArray *children = [traversal exploreImmediateChildren:viewA];
  XCTAssertEqualObjects(children, orderedViews);
}

- (void)testSortedChildViewsForCustomViewWithBothSubViewsAndAXViews {
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewC = [[UIView alloc] initWithFrame:kTestRect];
  GREYUTCustomAccessibilityView *viewA = [[GREYUTCustomAccessibilityView alloc]
                                          initWithObjects:@[viewB, viewC]];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewE = [[UIView alloc] initWithFrame:kTestRect];
  [viewA addSubview:viewD];
  [viewA addSubview:viewE];
  NSArray *orderedViews = @[viewE, viewD, viewC, viewB];

  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  NSArray *children = [traversal exploreImmediateChildren:viewA];
  XCTAssertEqualObjects(children, orderedViews);
}

- (void)testSortedChildViewsForViewWithATableViewCellAsASubview {
  UITableViewCell *cell = [[UITableViewCell alloc] init];
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  [cell addSubview:viewA];

  // Pre-iOS 8, UITableViewCell holds its views in an internal subview.
  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  NSArray *children = iOS8_0_OR_ABOVE() ? [traversal exploreImmediateChildren:cell] :
  [traversal exploreImmediateChildren:[cell.subviews objectAtIndex:0]];

  XCTAssertTrue([children containsObject:viewA]);
  XCTAssertTrue([children containsObject:viewA],
                @"View to look for: %@\nList: %@", viewA, children);
}

- (void)testSortedChildViewsForViewWithATableViewCellAsAnAXView {
  UITableViewCell *cell = [[UITableViewCell alloc] init];
  GREYUTCustomAccessibilityView *viewA =
  [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ cell ]];
  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  id firstObject = [[traversal exploreImmediateChildren:viewA] firstObject];
  XCTAssertEqualObjects(firstObject, cell);
}

- (void)testChildrenOfLeafElements {
  UIView *viewA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  UIView *viewC = [[UIView alloc] init];
  UIView *viewD = [[UIView alloc] init];

  GREYTraversal *traversal = [[GREYTraversal alloc] init];

  XCTAssertEqual([traversal exploreImmediateChildren:viewA].count, 0u);
  XCTAssertEqual([traversal exploreImmediateChildren:viewB].count, 0u);
  XCTAssertEqual([traversal exploreImmediateChildren:viewC].count, 0u);
  XCTAssertEqual([traversal exploreImmediateChildren:viewD].count, 0u);
}

- (void)testChildrenForSubview {

  UIView *viewA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  UIView *viewC = [[UIView alloc] init];
  UIView *viewD = [[UIView alloc] init];

  [viewA addSubview:viewB];
  [viewB addSubview:viewC];
  [viewB addSubview:viewD];

  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  NSArray *children = @[viewD, viewC];
  XCTAssertEqualObjects(children, [traversal exploreImmediateChildren:viewB]);

  XCTAssertEqualObjects(@[viewB], [traversal exploreImmediateChildren:viewA]);
}

#pragma mark - UITableView

- (void)testNilTableView {
  UITableView *tableView = nil;
  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  XCTAssertThrows([traversal exploreImmediateChildren:tableView]);
}

- (void)testTableView {
  UITableView *tableView = [[UITableView alloc] init];
  const NSUInteger count = 100;
  for (NSUInteger i = 0; i < count; ++i) {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    [tableView addSubview:cell];
  }

  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  // If before iOS 11, we use 'count + 1', because there are 100 cells + UITableViewWrapperView.
  XCTAssertEqual([traversal exploreImmediateChildren:tableView].count,
                 count + (iOS11_OR_ABOVE() ? 0 : 1));
}

#pragma mark - UIPickerView

- (void)testNilPickerView {
  UIPickerView *pickerView = nil;
  GREYTraversal *traversal = [[GREYTraversal alloc] init];
  XCTAssertThrows([traversal exploreImmediateChildren:pickerView]);
}

@end
