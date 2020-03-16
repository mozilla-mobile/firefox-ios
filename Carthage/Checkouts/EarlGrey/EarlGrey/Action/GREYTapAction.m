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

#import "Action/GREYTapAction.h"

#import "Action/GREYTapper.h"
#import "Additions/CGGeometry+GREYAdditions.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Common/GREYDefines.h"
#import "Common/GREYError.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYThrowDefines.h"
#import "Common/GREYVisibilityChecker.h"
#import "Core/GREYInteraction.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYAnyOf.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"

@implementation GREYTapAction {
  /**
   *  The type of tap action being performed.
   */
  GREYTapType _type;
  /**
   *  The number of taps constituting the action.
   */
  NSUInteger _numberOfTaps;
  /**
   *  The duration of the tap action.
   */
  CFTimeInterval _duration;
  /**
   *  The location for the tap action to happen.
   */
  CGPoint _tapLocation;
}

- (instancetype)initWithType:(GREYTapType)tapType {
  return [self initWithType:tapType numberOfTaps:1 duration:0.0f];
}

- (instancetype)initWithType:(GREYTapType)tapType numberOfTaps:(NSUInteger)numberOfTaps {
  return [self initWithType:tapType numberOfTaps:numberOfTaps duration:0.0f];
}

- (instancetype)initWithType:(GREYTapType)tapType
                numberOfTaps:(NSUInteger)numberOfTaps
                    location:(CGPoint)tapLocation {
  return [self initWithType:tapType numberOfTaps:numberOfTaps duration:0.0f location:tapLocation];
}

- (instancetype)initLongPressWithDuration:(CFTimeInterval)duration {
  return [self initLongPressWithDuration:duration location:GREYCGPointNull];
}

- (instancetype)initLongPressWithDuration:(CFTimeInterval)duration location:(CGPoint)location {
  return [self initWithType:kGREYTapTypeLong numberOfTaps:1 duration:duration location:location];
}

- (instancetype)initWithType:(GREYTapType)tapType
                numberOfTaps:(NSUInteger)numberOfTaps
                    duration:(CFTimeInterval)duration {
  return [self initWithType:tapType
               numberOfTaps:numberOfTaps
                   duration:duration
                   location:GREYCGPointNull];
}

- (instancetype)initWithType:(GREYTapType)tapType
                numberOfTaps:(NSUInteger)numberOfTaps
                    duration:(CFTimeInterval)duration
                    location:(CGPoint)tapLocation {
  GREYThrowOnFailedConditionWithMessage(numberOfTaps > 0,
                                        @"You cannot initialize a tap action with zero taps.");

  NSString *name = [GREYTapAction grey_actionNameWithTapType:tapType
                                                    duration:duration
                                                numberOfTaps:numberOfTaps];
  self = [super initWithName:name
                 constraints:grey_allOf(grey_not(grey_systemAlertViewShown()),
                                        grey_anyOf(grey_accessibilityElement(),
                                                   grey_kindOfClass([UIView class]),
                                                   nil),
                                        grey_enabled(),
                                        // Perform interactable check for non-keyboard keys.
                                        (tapType != kGREYTapTypeKBKey) ? grey_interactable() : nil,
                                        nil)];
  if (self) {
    _type = tapType;
    _numberOfTaps = numberOfTaps;
    _duration = duration;
    _tapLocation = tapLocation;
  }
  return self;
}

#pragma mark - GREYAction protocol

- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil {
  if (![self satisfiesConstraintsForElement:element error:errorOrNil]) {
    return NO;
  }
  switch (_type) {
    case kGREYTapTypeShort:
    case kGREYTapTypeMultiple: {
      return [GREYTapper tapOnElement:element
                         numberOfTaps:_numberOfTaps
                             location:[self grey_resolvedTapLocationForElement:element]
                                error:errorOrNil];
    }
    case kGREYTapTypeKBKey: {
      // Retrieving the accessibility activation point for a keyboard key is tricky due to window
      // transforms. Sending the tap directly to its windows is overall simpler.
      UIWindow *window = [element grey_viewContainingSelf].window;
      if (!window) {
        NSString *description =
            [NSString stringWithFormat:@"Element [E] is not attached to a window."];
        NSDictionary *glossary = @{ @"E" : [element grey_description] };

        GREYPopulateErrorNotedOrLog(errorOrNil,
                                    kGREYInteractionErrorDomain,
                                    kGREYInteractionActionFailedErrorCode,
                                    description,
                                    glossary);

        return NO;
      }
      return [GREYTapper tapOnWindow:window
                        numberOfTaps:_numberOfTaps
                            location:[element grey_accessibilityActivationPointInWindowCoordinates]
                               error:errorOrNil];
    }
    case kGREYTapTypeLong: {
      return [GREYTapper longPressOnElement:element
                                   location:[self grey_resolvedTapLocationForElement:element]
                                   duration:_duration
                                      error:errorOrNil];
    }
  }

  NSString *description =
      [NSString stringWithFormat:@"Unknown tap type: %ld", (long)_type];

  GREYPopulateErrorOrLog(errorOrNil,
                         kGREYInteractionErrorDomain,
                         kGREYInteractionActionFailedErrorCode,
                         description);

  return NO;
}

#pragma mark - Private

+ (NSString *)grey_actionNameWithTapType:(GREYTapType)tapType
                                duration:(CFTimeInterval)duration
                            numberOfTaps:(NSUInteger)numberOfTaps {
  switch (tapType) {
    case kGREYTapTypeShort:
      return @"Tap";
    case kGREYTapTypeMultiple:
      return [NSString stringWithFormat:@"Tap %ld times", (long)numberOfTaps];
    case kGREYTapTypeLong:
      return [NSString stringWithFormat:@"Long Press for %f seconds", duration];
    case kGREYTapTypeKBKey:
      return [NSString stringWithFormat:@"Tap on keyboard key"];
  }
  GREYFatalAssertWithMessage(NO, @"Unknown tapType %ld was provided", (long)tapType);
  return nil;
}

/**
 *  @return A tappable location as usable by this action for the given @c element.
 */
- (CGPoint)grey_resolvedTapLocationForElement:(id)element {
  return CGPointIsNull(_tapLocation) ?
      [GREYVisibilityChecker visibleInteractionPointForElement:element] :
      _tapLocation;
}

@end
