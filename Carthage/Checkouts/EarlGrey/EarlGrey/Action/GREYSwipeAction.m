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

#import "Action/GREYSwipeAction.h"

#import "Action/GREYPathGestureUtils.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/NSString+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Assertion/GREYAssertions+Internal.h"
#import "Common/GREYError.h"
#import "Common/GREYThrowDefines.h"
#import "Event/GREYSyntheticEvents.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYMatcher.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"

@implementation GREYSwipeAction {
  /**
   *  The direction in which the content must be scrolled.
   */
  GREYDirection _direction;
  /**
   *  The duration within which the swipe action must be complete.
   */
  CFTimeInterval _duration;
  /**
   *  Start point for the swipe specified as percentage of swipped element's accessibility frame.
   */
  CGPoint _startPercents;
}

- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                     percentPoint:(CGPoint)percents {
  GREYThrowOnFailedConditionWithMessage(percents.x > 0.0f && percents.x < 1.0f,
                                        @"xOriginStartPercentage must be between 0 and 1, "
                                        @"exclusively");
  GREYThrowOnFailedConditionWithMessage(percents.y > 0.0f && percents.y < 1.0f,
                                        @"yOriginStartPercentage must be between 0 and 1, "
                                        @"exclusively");

  NSString *name =
      [NSString stringWithFormat:@"Swipe %@ for duration %g", NSStringFromGREYDirection(direction),
                                 duration];
  self = [super initWithName:name
                 constraints:grey_allOf(grey_interactable(),
                                        grey_not(grey_systemAlertViewShown()),
                                        grey_kindOfClass([UIView class]),
                                        grey_respondsToSelector(@selector(accessibilityFrame)),
                                        nil)];
  if (self) {
    _direction = direction;
    _duration = duration;
    _startPercents = percents;
  }
  return self;
}

- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration {
  // TODO: Pick a visible point instead of picking the center of the view.
  return [self initWithDirection:direction
                        duration:duration
                    percentPoint:CGPointMake(0.5, 0.5)];
}

- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                    startPercents:(CGPoint)startPercents {
  return [self initWithDirection:direction
                        duration:duration
                    percentPoint:startPercents];
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil {
  if (![self satisfiesConstraintsForElement:element error:errorOrNil]) {
    return NO;
  }
  CGRect accessibilityFrame = [element accessibilityFrame];
  CGPoint startPoint =
      CGPointMake(accessibilityFrame.origin.x + accessibilityFrame.size.width * _startPercents.x,
                  accessibilityFrame.origin.y + accessibilityFrame.size.height * _startPercents.y);

  UIWindow *window = [element window];
  if (!window) {
    if ([element isKindOfClass:[UIWindow class]]) {
      window = (UIWindow *)element;
    } else {
      NSString *errorDescription =
          [NSString stringWithFormat:@"Cannot swipe on view [V], as it has no window and "
                                     @"it isn't a window itself."];
      NSDictionary *glossary = @{ @"V" : [element grey_description]};
      GREYError *error;
      error = GREYErrorMake(kGREYSyntheticEventInjectionErrorDomain,
                            kGREYOrientationChangeFailedErrorCode,
                            errorDescription);
      error.descriptionGlossary = glossary;
      if (errorOrNil) {
        *errorOrNil = error;
      } else {
        [GREYAssertions grey_raiseExceptionNamed:kGREYGenericFailureException
                                exceptionDetails:@""
                                       withError:error];
      }

      return NO;
    }
  }
  NSArray *touchPath = [GREYPathGestureUtils touchPathForGestureWithStartPoint:startPoint
                                                                  andDirection:_direction
                                                                   andDuration:_duration
                                                                      inWindow:window];
  [GREYSyntheticEvents touchAlongPath:touchPath
                     relativeToWindow:window
                          forDuration:_duration
                           expendable:YES];
  return YES;
}

@end
