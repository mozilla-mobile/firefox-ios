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

#import "Traversal/GREYTraversalDFS.h"
#import "GREYBaseTest.h"

@interface GREYTraversalDFSTest : GREYBaseTest

@end

@implementation GREYTraversalDFSTest

- (void)testHierarchyForSingleViewDFS {
  UIView *viewA = [[UIView alloc] init];
  GREYTraversalDFS *traversal = [GREYTraversalDFS hierarchyForElementWithDFSTraversal:viewA];
  id element = [traversal nextObject];
  XCTAssertEqual(element, viewA);
}

- (void)testHierachyForViewWithSingleSubviewDFS {
  UIView *viewA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  [viewA addSubview:viewB];

  GREYTraversalDFS *traversal = [GREYTraversalDFS hierarchyForElementWithDFSTraversal:viewA];
  XCTAssertEqual(viewA, [traversal nextObject]);
  XCTAssertEqual(viewB, [traversal nextObject]);
}

- (void)testHierarchyUnrollingForVariousViewsDFS {
  UIView *viewA = [[UIView alloc] init];
  UIView *viewB = [[UIView alloc] init];
  UIView *viewC = [[UIView alloc] init];
  UIView *viewD = [[UIView alloc] init];

  GREYTraversalDFS *traversal = [GREYTraversalDFS hierarchyForElementWithDFSTraversal:viewA];

  [viewA addSubview:viewB];
  [viewB addSubview:viewC];
  [viewB addSubview:viewD];

  XCTAssertEqual(viewA, [traversal nextObject]);
  XCTAssertEqual(viewB, [traversal nextObject]);
  XCTAssertEqual(viewD, [traversal nextObject]);
  XCTAssertEqual(viewC, [traversal nextObject]);
}

- (void)testDeepHierarchyDFS {
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

  GREYTraversalDFS *traversal = [GREYTraversalDFS hierarchyForElementWithDFSTraversal:viewA];

  NSArray *orderedViews = @[viewA, viewC, viewF, viewE, viewB, viewD];
  for (id view in orderedViews) {
    XCTAssertEqual(view, [traversal nextObject]);
  }
}

@end
