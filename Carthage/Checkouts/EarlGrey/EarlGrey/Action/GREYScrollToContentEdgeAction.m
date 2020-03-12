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

#import "Action/GREYScrollToContentEdgeAction.h"

#import "Action/GREYScrollAction.h"
#import "Action/GREYScrollActionError.h"
#import "Additions/CGGeometry+GREYAdditions.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/NSString+GREYAdditions.h"
#import "Additions/UIScrollView+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYVisibilityChecker.h"
#import "Event/GREYSyntheticEvents.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYAnyOf.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"

@implementation GREYScrollToContentEdgeAction {
  /**
   *  The specified edge of the content to be scrolled to.
   */
  GREYContentEdge _edge;
  /**
   *  The point specified as percentage referencing visible scrollable area to be used for fixing
   *  scroll start point. If any of the coordinates are set to NAN the corresponding coordinates of
   *  the scroll start point will be set to achieve maximum scroll.
   */
  CGPoint _startPointPercents;
}

- (instancetype)initWithEdge:(GREYContentEdge)edge startPointPercents:(CGPoint)startPointPercents {
  GREYFatalAssertWithMessage(isnan(startPointPercents.x) ||
                             (startPointPercents.x > 0 && startPointPercents.x < 1),
                             @"startPointPercents must be NAN or in the range (0, 1) exclusive");
  GREYFatalAssertWithMessage(isnan(startPointPercents.y) ||
                             (startPointPercents.y > 0 && startPointPercents.y < 1),
                             @"startPointPercents must be NAN or in the range (0, 1) exclusive");

  NSString *name =
      [NSString stringWithFormat:@"Scroll To %@ content edge", NSStringFromGREYContentEdge(edge)];
  self = [super initWithName:name
                 constraints:grey_allOf(
#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
                     grey_anyOf(grey_kindOfClass([UIScrollView class]),
                                grey_kindOfClass([UIWebView class]),
                                nil),
#else
                     grey_kindOfClass([UIScrollView class]),
#endif  // !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
                     grey_not(grey_systemAlertViewShown()),
                     nil)];
  if (self) {
    _edge = edge;
    _startPointPercents = startPointPercents;
  }
  return self;
}

- (instancetype)initWithEdge:(GREYContentEdge)edge {
  return [self initWithEdge:edge startPointPercents:GREYCGPointNull];
}

#pragma mark - GREYAction

- (BOOL)perform:(UIScrollView *)element error:(__strong NSError **)errorOrNil {
  if (![self satisfiesConstraintsForElement:element error:errorOrNil]) {
    return NO;
  }
#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
  // To scroll UIWebView we must use the UIScrollView in its hierarchy and scroll it.
  if ([element isKindOfClass:[UIWebView class]]) {
    element = [(UIWebView *)element scrollView];
  }
#endif  // !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0

  // Get the maximum scrollable amount in any direction and keep applying it until the edge
  // is reached.
  const CGFloat maxScrollInAnyDirection = MAX([UIScreen mainScreen].bounds.size.width,
                                              [UIScreen mainScreen].bounds.size.height);
  // TODO: This means that we keep scrolling until we reach the top and can take
  // forever if we are operating on a circular scroll view, implement a way to timeout long
  // running actions and make this process timeout.
  GREYScrollAction *scrollAction =
      [[GREYScrollAction alloc] initWithDirection:[GREYConstants directionFromCenterForEdge:_edge]
                                           amount:maxScrollInAnyDirection
                               startPointPercents:_startPointPercents];
  NSError *scrollError;
  while (YES) {
    @autoreleasepool {
      if (![scrollAction perform:element error:&scrollError]) {
        break;
      }
    }
  }

  if (scrollError.code == kGREYScrollReachedContentEdge &&
      [scrollError.domain isEqualToString:kGREYScrollErrorDomain]) {
    // We have reached the content edge.
    return YES;
  } else {
    // Some other error has occurred.
    if (errorOrNil) {
      *errorOrNil = scrollError;
    }
    return NO;
  }
}

@end
