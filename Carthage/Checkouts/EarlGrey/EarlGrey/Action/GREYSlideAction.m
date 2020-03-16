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

#import "Action/GREYSlideAction.h"

#include <tgmath.h>

#import "Additions/CGGeometry+GREYAdditions.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYConstants.h"
#import "Common/GREYDefines.h"
#import "Common/GREYError.h"
#import "Common/GREYLogger.h"
#import "Core/GREYInteraction.h"
#import "Event/GREYSyntheticEvents.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"

@implementation GREYSlideAction {
  /**
   *  The final value that the slider should be moved to.
   */
  float _finalValue;
}

- (instancetype)initWithSliderValue:(float)value {
  self = [super initWithName:[NSString stringWithFormat:@"Slide to value: %g", value]
                 constraints:grey_allOf(grey_interactable(),
                                        grey_not(grey_systemAlertViewShown()),
                                        grey_kindOfClass([UISlider class]),
                                        nil)];
  if (self) {
    _finalValue = value;
  }
  return self;
}

#pragma mark - GREYAction

- (BOOL)perform:(UISlider *)slider error:(__strong NSError **)errorOrNil {
  if (![self satisfiesConstraintsForElement:slider error:errorOrNil]) {
    return NO;
  }
  if (!islessgreater(slider.value, _finalValue)) {
    return YES;
  }

  if (![self grey_checkEdgeCasesForFinalValueOfSlider:slider error:errorOrNil]) {
    return NO;
  };

  float currentSliderValue = slider.value;

  // Get the center of the thumb in coordinates respective of the slider it is in.
  CGPoint touchPoint = [self grey_centerOfSliderThumbInSliderCoordinates:slider];

  // Begin sliding by injecting touch events.
  GREYSyntheticEvents *eventGenerator = [[GREYSyntheticEvents alloc] init];
  [eventGenerator beginTouchAtPoint:[slider convertPoint:touchPoint toView:nil]
                   relativeToWindow:slider.window
                  immediateDelivery:YES];

  // |slider.value| could have changed, because touch down sometimes moves the thumb.
  float previousSliderValue = currentSliderValue;
  currentSliderValue = slider.value;

  // Get the rectangle width in order to estimate horizonal distance between values.
  CGRect trackBounds = [slider trackRectForBounds:slider.bounds];
  double trackWidth = trackBounds.size.width;

  // Stepsize is hypothesized amount you have to step to get from one value to another. It's
  // hypothesized because the distance between any two given values is not always consistent.
  double stepSize = fabs(trackWidth / ((double)slider.maximumValue - (double)slider.minimumValue));

  double amountToSlide = stepSize * ((double)_finalValue - (double)currentSliderValue);

  // A value could be unattainable, in which case, this algorithm would run forever. From testing,
  // we've seen that it takes anywhere from 2-4 interactions to find a final value that is
  // acceptable (see constants defined above to understand what accepable is). So, we let the
  // algorithm run for at most ten iterations and then halt.
  static const unsigned short kAllowedAttemptsBeforeStopping = 10;
  unsigned short numberOfAttemptsAtGettingFinalValue = 0;

  // Begin moving thumb to the |_finalValue|
  while (islessgreater(slider.value, _finalValue)) {
    @autoreleasepool {
      if (!(numberOfAttemptsAtGettingFinalValue < kAllowedAttemptsBeforeStopping)) {
        NSLog(@"The value you have chosen to move to is probably unattainable. Most likely,"
              @"it is between two pixels.");
        break;
      }

      touchPoint = CGPointMake(touchPoint.x + (CGFloat)amountToSlide, touchPoint.y);
      [eventGenerator continueTouchAtPoint:[slider convertPoint:touchPoint toView:nil]
                         immediateDelivery:YES
                                expendable:NO];

      // For debugging purposes, leave this in.
      GREYLogVerbose(@"Slider value after moving: %f", slider.value);

      // Update |previousSliderValue| and |currentSliderValue| only if slider value actually
      // changed.
      if (islessgreater(slider.value, currentSliderValue)) {
        previousSliderValue = currentSliderValue;
        currentSliderValue = slider.value;
      }

      // changeInSliderValueAfterMoving is how many values we actually moved with the previously
      // calculated |amountToSlide|.
      double changeInSliderValueAfterMoving = currentSliderValue - previousSliderValue;
      if (islessgreater(currentSliderValue, previousSliderValue)) {
        // Adjust the stepSize based upon how many values were actually traversed.
        stepSize = fabs(amountToSlide / changeInSliderValueAfterMoving);
        amountToSlide = stepSize * ((double)_finalValue - (double)currentSliderValue);
      } else {
        // If we didn't move at all and we are still not at the final value, move by twice as much
        // as we did last time to try to get a different value.
        amountToSlide = 2.0 * amountToSlide;
      }
      numberOfAttemptsAtGettingFinalValue++;
    }
  }

  [eventGenerator endTouch];
  return YES;
}

#pragma mark - Private

- (CGPoint)grey_centerOfSliderThumbInSliderCoordinates:(UISlider *)slider {
  CGRect sliderBounds = slider.bounds;
  CGRect trackBounds = [slider trackRectForBounds:sliderBounds];
  CGRect thumbBounds = [slider thumbRectForBounds:sliderBounds
                                        trackRect:trackBounds
                                            value:slider.value];
  return CGPointMake(CGRectGetMidX(thumbBounds), CGRectGetMidY(thumbBounds));
}

- (BOOL)grey_checkEdgeCasesForFinalValueOfSlider:(UISlider *)slider
                                           error:(__strong NSError **)errorOrNil {
  NSString *reason;
  if (isgreater(_finalValue, slider.maximumValue)) {
    reason = @"Value to move to is larger than slider's maximum value";
  } else if (isless(_finalValue, slider.minimumValue)) {
    reason = @"Value to move to is smaller than slider's minimum value";
  } else if (!islessgreater(slider.minimumValue, slider.maximumValue)
             && islessgreater(_finalValue, slider.minimumValue)) {
    reason = @"Slider has the same maximum and minimum, cannot move thumb to desired value";
  } else {
    return YES;
  }

  NSString *description = [NSString stringWithFormat:@"%@: Slider's Minimum is %g, Maximum is %g, "
                                                     @"desired value is %g",
                                                     reason,
                                                     slider.minimumValue,
                                                     slider.maximumValue,
                                                     _finalValue];

  GREYPopulateErrorOrLog(errorOrNil,
                         kGREYInteractionErrorDomain,
                         kGREYInteractionActionFailedErrorCode,
                         description);

  return NO;
}

@end
