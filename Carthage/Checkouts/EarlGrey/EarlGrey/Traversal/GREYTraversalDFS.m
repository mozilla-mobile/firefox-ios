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

#import "Common/GREYThrowDefines.h"

@implementation GREYTraversalDFS {
  /**
   *  An array that contains the unrolled hierarchy.
   */
  NSMutableArray *_parsedHierarchy;

  /**
   *  NSUInteger to keep track of the index that is being accessed in the @c _parsedHierarchy array.
   */
  NSUInteger _parsedHierarchyIndex;
}

- (instancetype)init:(id)element {
  self = [super init];
  if (self) {
    _parsedHierarchy = [[NSMutableArray alloc] init];
    _parsedHierarchyIndex = 0;
    [_parsedHierarchy addObject:element];
  }
  return self;
}

+ (instancetype)hierarchyForElementWithDFSTraversal:(id)element {
  GREYThrowOnNilParameter(element);

  // Wrap the @c element in the GREYTraversalDFSObject.
  GREYTraversalObject *object = [[GREYTraversalObject alloc] init];
  object.level = 0;
  object.element = element;

  // Create an instance of GREYTraversalDFS.
  return [[GREYTraversalDFS alloc] init:object];
}

- (id)nextObject {
  GREYTraversalObject *element = [self grey_nextObjectDFS];
  return element.element;
}

- (void)enumerateUsingBlock:(void (^)(id view, NSUInteger level))block {
  GREYThrowOnNilParameter(block);

  // Loop till we have explored each element in the hierarchy.
  GREYTraversalObject *object;
  while ((object = [self grey_nextObjectDFS])) {
    // For each element call the @c block.
    block(object.element, object.level);
  }
}

#pragma mark - Private

/**
 *  The method retrieves the next object in the hierarchy.
 *
 *  @return Returns an instance of GREYTraversalDFSObject.
 */
- (GREYTraversalObject *)grey_nextObjectDFS {
  // If we have explored all elements.
  if (_parsedHierarchyIndex >= [_parsedHierarchy count]) {
    return nil;
  }

  GREYTraversalObject *nextObject = [_parsedHierarchy objectAtIndex:_parsedHierarchyIndex];

  // For the DFS algorithm, we will add to the @c _parsedHierarchy array in a specified order,
  // and we also need to wrap the UI elements into GREYHierarchyObject instance.
  NSArray *children =
      [self exploreImmediateChildren:nextObject.element];

  // Insert the GREYHierarchyObject instance into the front of the array. Here the array is used
  // as a stack, hence front insertions. We could have inserted into the back, however the logic
  // associated with @c _parsedHierarchyIndex facilitated front insertions.
  for (id child in [children reverseObjectEnumerator]) {
    GREYTraversalObject *object = [[GREYTraversalObject alloc] init];
    [object setLevel:nextObject.level + 1];
    [object setElement:child];
    [_parsedHierarchy insertObject:object atIndex:0];
  }

  // Retain the @c nextObject since we are removing it from the array.
  GREYTraversalObject *element = nextObject;
  [_parsedHierarchy removeObject:nextObject];
  return element;
}

@end
