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

#import "Traversal/GREYTraversalBFS.h"
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface GREYTraversalBFSTest : GREYBaseTest

@end

@implementation GREYTraversalBFSTest

- (void)testHierarchyForSingleViewBFS {
  UIView *viewA = [[UIView alloc] init];
  GREYTraversalBFS *traversal = [GREYTraversalBFS hierarchyForElementWithBFSTraversal:viewA];
  XCTAssertEqual([traversal nextObject], viewA);
}

- (void)testHierachyForViewWithSingleSubviewBFS {
  UIView *viewA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  [viewA addSubview:viewB];
  GREYTraversalBFS *traversal = [GREYTraversalBFS hierarchyForElementWithBFSTraversal:viewA];
  XCTAssertEqual(viewA, [traversal nextObject]);
  XCTAssertEqual(viewB, [traversal nextObject]);
}

- (void)testHierarchyUnrollingForVariousViewsBFS {
  UIView *viewA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  UIView *viewC = [[UIView alloc] init];
  UIView *viewD = [[UIView alloc] init];

  [viewA addSubview:viewB];
  [viewB addSubview:viewC];
  [viewB addSubview:viewD];

  GREYTraversalBFS *traversal = [GREYTraversalBFS hierarchyForElementWithBFSTraversal:viewA];

  XCTAssertEqual(viewA, [traversal nextObject]);
  XCTAssertEqual(viewB, [traversal nextObject]);
  XCTAssertEqual(viewD, [traversal nextObject]);
  XCTAssertEqual(viewC, [traversal nextObject]);
}

- (void)testDeepHierarchyBFS {
  UIView *viewA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  UIView *viewC = [[UIView alloc] init];
  UIView *viewD = [[UIView alloc] init];
  UIView *viewE = [[UIView alloc] init];
  UIView *viewF = [[UIView alloc] init];

  [viewA addSubview:viewB];
  [viewA addSubview:viewC];

  [viewB addSubview:viewD];

  [viewC addSubview:viewE];
  [viewC addSubview:viewF];

  GREYTraversalBFS *traversal = [GREYTraversalBFS hierarchyForElementWithBFSTraversal:viewA];

  NSArray *orderedViews = @[viewA, viewC, viewB, viewF, viewE, viewD];
  for (id view in orderedViews) {
    XCTAssertEqual(view, [traversal nextObject]);
  }
}

@end
