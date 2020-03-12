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

#import "Traversal/GREYTraversal.h"

#import "Common/GREYConstants.h"
#import "Common/GREYThrowDefines.h"

/**
 *  An empty implementation since GREYTraversalObject is a wrapper object.
 */
@implementation GREYTraversalObject

@end

@implementation GREYTraversal

- (NSArray *)exploreImmediateChildren:(id)element {
  GREYThrowOnNilParameter(element);

  NSMutableOrderedSet *immediateChildren = [[NSMutableOrderedSet alloc] init];

  if ([element isKindOfClass:[UIView class]]) {
    // Grab all subviews so that we continue traversing the entire hierarchy.
    // Add the objects in reverse order to make sure that objects on top get matched first.
    NSArray *subviews = [element subviews];
    if ([subviews count] > 0) {
      for (UIView *subview in [subviews reverseObjectEnumerator]) {
        [immediateChildren addObject:subview];
      }
    }
  }

  BOOL nextIsATableView = [element isKindOfClass:[UITableView class]];
  BOOL nextIsATableViewCell = [element isKindOfClass:[UITableViewCell class]];

  // If we encounter an accessibility container, grab all the contained accessibility elements.
  // However, we need to skip a few types of containers:
  // 1) UITableViewCells as they do a lot of custom accessibility work underneath
  //    and the accessibility elements they return are 'mocks' that cause access errors.
  // 2) UITableViews as because they report all their cells, even the ones off-screen as
  //    accessibility elements. We should not consider off-screen cells as there could be
  //    hundreds, even thousands of them and we would be iterating over them unnecessarily.
  //    Worse yet, if the cell isn't visible, calling accessibilityElementAtIndex will create
  //    and initialize them each time.
  if (!nextIsATableViewCell && !nextIsATableView
      && [element respondsToSelector:@selector(accessibilityElementCount)]) {
    NSInteger elementCount = [element accessibilityElementCount];
    if (elementCount != NSNotFound && elementCount > 0) {
      if ([element isKindOfClass:NSClassFromString(@"UIPickerTableView")]) {
        // If we hit a picker table view then we will limit the number of elements to 500 since
        // we don't want to timeout searching through identical views that are created to make
        // it seem like there is an infinite number of items in the picker.
        elementCount = MIN(elementCount, kUIPickerViewMaxAccessibilityViews);
      }
      // Temp holder created by UIKit. What we really want is the underlying element.
      Class accessibilityMockClass = NSClassFromString(@"UIAccessibilityElementMockView");
      //NSUInteger count = [immediateChildren count];
      for (NSInteger i = elementCount - 1; i >= 0; i--) {
        id item = [element accessibilityElementAtIndex:i];
        if ([item isKindOfClass:accessibilityMockClass]) {
          // Replace mock views with the views they encapsulate.
          item = [item view];
        }
        if (item) {
          [immediateChildren addObject:item];
        }
      }
    }
  }

  return [immediateChildren array];
}

@end
