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

#import <EarlGrey/GREYDefines.h>
#import "Provider/GREYElementProvider.h"
#import "Provider/GREYUIWindowProvider.h"
#import "GREYBaseTest.h"
#import "GREYUTAccessibilityViewContainerView.h"
#import "GREYUTCustomAccessibilityView.h"

@interface GREYElementProviderTest : GREYBaseTest<UITableViewDataSource, UITableViewDelegate>
@end

@implementation GREYElementProviderTest {
  UITableView *_tableView;
  UITableViewCell *_cellA1;
}

- (void)setUp {
  [super setUp];

  _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 500, 200)];
  [_tableView setDelegate:self];
  [_tableView setDataSource:self];

  _cellA1 = [[UITableViewCell alloc] init];
}

- (void)testTableViewCellsIncludedOnlyOnce {
  UIView *cellSubview = [[UIView alloc] init];
  [_cellA1 addSubview:cellSubview];

  // Explicit call that loads the cells.
  [_tableView layoutSubviews];

  GREYElementProvider *provider = [GREYElementProvider providerWithRootElements:@[ _tableView ]];
  NSArray *actual = [[provider dataEnumerator] allObjects];

  BOOL foundCell = NO;
  BOOL foundCellSubview = NO;
  BOOL foundCellContentView = NO;

  for (UIView *view in actual) {
    if (view == _cellA1) {
      XCTAssertFalse(foundCell,
                     @"Looks like there is a duplicate cell: %@ in provider list: %@",
                     view, actual);
      foundCell = YES;
    } else if (view == cellSubview) {
      XCTAssertFalse(foundCellSubview,
                     @"Looks like there is a duplicate cell subview: %@ in provider list: %@",
                     view, actual);
      foundCellSubview = YES;
    } else if (view == _cellA1.contentView) {
      XCTAssertFalse(foundCellContentView,
                     @"Looks like there is a duplicate cell contentview: %@ in provider list: %@",
                     view, actual);
      foundCellContentView = YES;
    }
  }
  XCTAssertTrue(foundCell);
  XCTAssertTrue(foundCellSubview);
  XCTAssertTrue(foundCellContentView);
}

- (void)testTableViewCellSubviewIncluded {
  UIView *cellSubview = [[UIView alloc] init];
  UITableViewCell *cell = [[UITableViewCell alloc] init];
  [cell addSubview:cellSubview];

  GREYElementProvider *provider = [GREYElementProvider providerWithRootElements:@[ cell ]];
  // At least the following should be present in order in which they are specified.
  NSArray *expected = @[ cell, cellSubview, cell.contentView ];
  NSArray *actual = [[provider dataEnumerator] allObjects];
  // actual could contain intermediate views we don't care about. We filter them out.
  NSPredicate *filterViewsNotInExpected =
      [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [expected containsObject:evaluatedObject];
      }];
  actual = [actual filteredArrayUsingPredicate:filterViewsNotInExpected];
  XCTAssertEqualObjects(expected, actual);
}

- (void)testEmpty {
  GREYUIWindowProvider *windowProvider = [GREYUIWindowProvider providerWithWindows:@[ ]];
  GREYElementProvider *provider = [GREYElementProvider providerWithRootProvider:windowProvider];
  XCTAssertEqual(0u, [[provider dataEnumerator] allObjects].count, @"Should be empty");
}

- (void)testFullHierarchyShown {
  UIWindow *window = [[UIWindow alloc] init];
  UIView *viewA = [[UIView alloc] init];
  UIView *viewAA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  [viewA addSubview:viewAA];
  [window addSubview:viewA];
  [window addSubview:viewB];
  NSArray *expected = @[ window, viewB, viewA, viewAA ];
  GREYUIWindowProvider *windowProvider = [GREYUIWindowProvider providerWithWindows:@[ window ]];
  GREYElementProvider *provider = [GREYElementProvider providerWithRootProvider:windowProvider];
  XCTAssertEqualObjects(expected,
                        [[provider dataEnumerator] allObjects],
                        @"Should contain full window hierarchy");
}

- (void)testViewsWithRootView {
  UIWindow *window = [[UIWindow alloc] init];
  UIView *viewA = [[UIView alloc] init];
  UIView *viewAA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  [viewA addSubview:viewAA];
  [window addSubview:viewA];
  [window addSubview:viewB];
  NSArray *expected = @[ window, viewB, viewA, viewAA ];
  GREYElementProvider *provider = [GREYElementProvider providerWithRootElements:@[ window ]];
  XCTAssertEqualObjects(expected,
                        [[provider dataEnumerator] allObjects],
                        @"Should contain full window hierarchy");
}

- (void)testViewsWithViews {
  UIView *viewA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  GREYElementProvider *provider = [GREYElementProvider providerWithElements:@[ viewA, viewB ]];
  NSEnumerator *dataEnumerator = [provider dataEnumerator];
  XCTAssertEqualObjects(viewA, [dataEnumerator nextObject], @"viewA should be next");
  NSArray *expectedAfterNext = @[ viewB ];
  XCTAssertEqualObjects(expectedAfterNext,
                        [dataEnumerator allObjects],
                        @"Should contain all views the provider was initialized with");
}

- (void)testMockViewIsReplacedByActualView {
  NSInteger testInteger = 0;
  id view = [OCMockObject mockForClass:[UIView class]];
  id mockView = [OCMockObject mockForClass:NSClassFromString(@"UIAccessibilityElementMockView")];
  [[[view stub] andReturnValue:[NSNumber numberWithInteger:1]] accessibilityElementCount];
  [[[view stub] andReturn:@[]] subviews];
  [[[view stub] andReturn:mockView] accessibilityElementAtIndex:testInteger];
  UIView *viewInMockView = [[UIView alloc] init];
  [[[mockView stub] andReturn:viewInMockView] view];

  GREYElementProvider *provider = [GREYElementProvider providerWithElements:@[ view ]];
  NSEnumerator *dataEnumerator = [provider dataEnumerator];
  XCTAssertEqualObjects(view, [dataEnumerator nextObject], @"view should be first");
  XCTAssertEqualObjects(viewInMockView, [dataEnumerator nextObject],
                        @"viewInMockView should be second");
}

- (void)testAccessibilityElements {
  UIView *viewA = [[UIView alloc] init];
  UIImage *imgA = [[UIImage alloc] init];
  GREYUTAccessibilityViewContainerView *imgView =
      [[GREYUTAccessibilityViewContainerView alloc] initWithImage:imgA];
  imgView.isAccessibilityElement = NO;
  [viewA addSubview:imgView];

  GREYElementProvider *provider = [GREYElementProvider providerWithElements:@[ viewA ]];
  NSEnumerator *dataEnumerator = [provider dataEnumerator];
  XCTAssertEqualObjects(viewA, [dataEnumerator nextObject], @"viewA should be next");
  NSArray *expectedAfterNext = @[ imgView, imgA ];
  XCTAssertEqualObjects(expectedAfterNext,
                        [dataEnumerator allObjects],
                        @"Should contain all views and elements the provider was initialized with");
}

- (void)testAccessibilityElementsOrder {
  UIView *viewA = [[UIView alloc] init];
  UIImage *imgA = [[UIImage alloc] init];
  UIImage *imgB = [[UIImage alloc] init];
  GREYUTAccessibilityViewContainerView *imgView =
      [[GREYUTAccessibilityViewContainerView alloc] initWithElements:@[ imgA, imgB ]];
  imgView.isAccessibilityElement = NO;
  [viewA addSubview:imgView];

  GREYElementProvider *provider = [GREYElementProvider providerWithElements:@[ viewA ]];
  NSEnumerator *dataEnumerator = [provider dataEnumerator];
  XCTAssertEqualObjects(viewA, [dataEnumerator nextObject], @"viewA should be first");
  NSArray *expectedAfterNext = @[ imgView, imgB, imgA ];
  XCTAssertEqualObjects(expectedAfterNext,
                        [dataEnumerator allObjects],
                        @"Should contain all views and elements the provider was initialized with");
}


- (void)testAccessibilityElementWithAccessibilityElement {
  UIView *viewA = [[UIView alloc] init];
  UIImage *imgA = [[UIImage alloc] init];
  GREYUTAccessibilityViewContainerView *imgView =
      [[GREYUTAccessibilityViewContainerView alloc] initWithImage:imgA];
  imgView.isAccessibilityElement = YES;
  [viewA addSubview:imgView];

  GREYElementProvider *provider = [GREYElementProvider providerWithElements:@[ viewA ]];
  NSEnumerator *dataEnumerator = [provider dataEnumerator];
  XCTAssertEqualObjects(viewA, [dataEnumerator nextObject], @"viewA should be next");
  NSArray *expectedAfterNext = @[ imgView, imgA ];
  XCTAssertEqualObjects(expectedAfterNext,
                        [dataEnumerator allObjects],
                        @"Should contain all views and elements the provider was initialized with");
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  switch ([indexPath row]) {
    case 0:
      return _cellA1;
    default:
      return nil;
  }
}

@end
