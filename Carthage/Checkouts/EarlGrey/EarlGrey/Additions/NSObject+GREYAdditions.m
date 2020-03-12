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

#import "Additions/NSObject+GREYAdditions.h"

#include <objc/runtime.h>

#import "Additions/CGGeometry+GREYAdditions.h"
#import "Additions/NSString+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYConstants.h"
#import "Common/GREYElementHierarchy.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYLogger.h"
#import "Common/GREYSwizzler.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYTimedIdlingResource.h"

/**
 *  Class that all Web Accessibility Elements have to be a kind of.
 */
static Class gWebAccessibilityWrapper;

@implementation NSObject (GREYAdditions)

+ (void)load {
  @autoreleasepool {
    gWebAccessibilityWrapper = NSClassFromString(@"WebAccessibilityObjectWrapper");

    GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
    BOOL swizzleSuccess =
        [swizzler swizzleClass:self
            replaceClassMethod:@selector(cancelPreviousPerformRequestsWithTarget:)
                    withMethod:@selector(greyswizzled_cancelPreviousPerformRequestsWithTarget:)];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle NSObject::"
                               @"cancelPreviousPerformRequestsWithTarget:");

    SEL swizzledSEL =
        @selector(greyswizzled_cancelPreviousPerformRequestsWithTarget:selector:object:);
    swizzleSuccess =
        [swizzler swizzleClass:self
            replaceClassMethod:@selector(cancelPreviousPerformRequestsWithTarget:selector:object:)
                    withMethod:swizzledSEL];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle NSObject::"
                               @"cancelPreviousPerformRequestsWithTarget:selector:object:");

    swizzledSEL = @selector(greyswizzled_performSelector:withObject:afterDelay:inModes:);
    swizzleSuccess =
        [swizzler swizzleClass:self
         replaceInstanceMethod:@selector(performSelector:withObject:afterDelay:inModes:)
                    withMethod:swizzledSEL];
    GREYFatalAssertWithMessage(swizzleSuccess,
                               @"Cannot swizzle "
                               @"NSObject::performSelector:withObject:afterDelay:inModes");
  }
}

- (NSString *)grey_recursiveDescription {
  if ([self grey_isWebAccessibilityElement]) {
    return [GREYElementHierarchy hierarchyStringForElement:[self grey_viewContainingSelf]];
  } else if ([self isKindOfClass:[UIView class]] ||
             [self respondsToSelector:@selector(accessibilityContainer)]) {
    return [GREYElementHierarchy hierarchyStringForElement:self];
  } else {
    GREYFatalAssertWithMessage(NO,
                               @"grey_recursiveDescription made on an element that is not a valid "
                               @"UI element: %@", self);
    return nil;
  }
}

- (UIView *)grey_viewContainingSelf {
  if ([self grey_isWebAccessibilityElement]) {
#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
    return [[self grey_containersAssignableFromClass:[UIWebView class]] firstObject];
#endif  // !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
    return nil;
  } else if ([self isKindOfClass:[UIView class]]) {
    return [self grey_container];
  } else if ([self respondsToSelector:@selector(accessibilityContainer)]) {
    id container = [self grey_container];
    if (![container isKindOfClass:[UIView class]]) {
      return [container grey_viewContainingSelf];
    }
    return container;
  }
  return nil;
}

- (id)grey_container {
  if ([self isKindOfClass:[UIView class]]) {
    return [(UIView *)self superview];
  } else if ([self respondsToSelector:@selector(accessibilityContainer)]) {
    return [self performSelector:@selector(accessibilityContainer)];
  } else {
    return nil;
  }
}

- (NSArray *)grey_containersAssignableFromClass:(Class)klass {
  NSMutableArray *containers = [[NSMutableArray alloc] init];

  id container = self;
  do {
    container = [container grey_container];
    if ([container isKindOfClass:klass]) {
      [containers addObject:container];
    }
  } while (container);

  return containers;
}

/**
 *  @return @c YES if @c self is an accessibility element within a UIWebView, @c NO otherwise.
 */
- (BOOL)grey_isWebAccessibilityElement {
  return [self isKindOfClass:gWebAccessibilityWrapper];
}

- (CGPoint)grey_accessibilityActivationPointInWindowCoordinates {
  UIView *view =
      [self isKindOfClass:[UIView class]] ? (UIView *)self : [self grey_viewContainingSelf];
  GREYFatalAssertWithMessage(view,
                             @"Corresponding UIView could not be found for UI element %@", self);

  // Convert activation point from screen coordinates to window coordinates.
  if ([view isKindOfClass:[UIWindow class]]) {
    return [(UIWindow *)view convertPoint:self.accessibilityActivationPoint fromWindow:nil];
  } else {
    return [view.window convertPoint:self.accessibilityActivationPoint fromWindow:nil];
  }
}

- (CGPoint)grey_accessibilityActivationPointRelativeToFrame {
  CGRect axFrame = [self accessibilityFrame];
  CGPoint axPoint = [self accessibilityActivationPoint];
  return CGPointMake(axPoint.x - axFrame.origin.x, axPoint.y - axFrame.origin.y);
}

- (NSString *)grey_description {
  NSMutableString *description = [[NSMutableString alloc] init];

  // Class information.
  [description appendFormat:@"<%@", NSStringFromClass([self class])];
  [description appendFormat:@":%p", self];

  // IsAccessibilityElement.
  if ([self respondsToSelector:@selector(isAccessibilityElement)]) {
    [description appendFormat:@"; AX=%@", self.isAccessibilityElement ? @"Y" : @"N"];
  }

  // AccessibilityIdentifier from UIAccessibilityIdentification.
  if ([self respondsToSelector:@selector(accessibilityIdentifier)]) {
    NSString *value = [self performSelector:@selector(accessibilityIdentifier)];
    [description appendString:
        [self grey_formattedDescriptionOrEmptyStringForValue:value withPrefix:@"; AX.id="]];
  }

  // Include UIAccessibilityElement properties.

  // Accessibility Label.
  if ([self respondsToSelector:@selector(accessibilityLabel)]) {
    NSString *value = self.accessibilityLabel;
    [description appendString:
        [self grey_formattedDescriptionOrEmptyStringForValue:value withPrefix:@"; AX.label="]];
  }

  // Accessibility hint.
  if ([self respondsToSelector:@selector(accessibilityHint)]) {
    NSString *value = self.accessibilityHint;
    [description appendString:
        [self grey_formattedDescriptionOrEmptyStringForValue:value withPrefix:@"; AX.hint="]];
  }

  // Accessibility value.
  if ([self respondsToSelector:@selector(accessibilityValue)]) {
    NSString *value = self.accessibilityValue;
    [description appendString:
        [self grey_formattedDescriptionOrEmptyStringForValue:value withPrefix:@"; AX.value="]];
  }

  // Accessibility frame.
  if ([self respondsToSelector:@selector(accessibilityFrame)]) {
    [description appendFormat:@"; AX.frame=%@",
        NSStringFromCGRect(self.accessibilityFrame)];
  }

  // Accessibility activation point.
  if ([self respondsToSelector:@selector(accessibilityActivationPoint)]) {
    [description appendFormat:@"; AX.activationPoint=%@",
        NSStringFromCGPoint(self.accessibilityActivationPoint)];
  }

  // Accessibility traits.
  if ([self respondsToSelector:@selector(accessibilityTraits)]) {
    [description appendFormat:@"; AX.traits=\'%@\'",
        NSStringFromUIAccessibilityTraits(self.accessibilityTraits)];
  }

  // Accessibility element is focused from UIAccessibility.
  if ([self respondsToSelector:@selector(accessibilityElementIsFocused)]) {
    [description appendFormat:
        @"; AX.focused=\'%@\'", self.accessibilityElementIsFocused ? @"Y" : @"N"];
  }

  // Values present if view.
  if ([self isKindOfClass:[UIView class]]) {
    UIView *selfAsView = (UIView *)self;

    // View frame.
    [description appendFormat:@"; frame=%@", NSStringFromCGRect(selfAsView.frame)];

    // Visual properties.
    if (selfAsView.isOpaque) {
      [description appendString:@"; opaque"];
    }
    if (selfAsView.isHidden) {
      [description appendString:@"; hidden"];
    }

    [description appendFormat:@"; alpha=%g", selfAsView.alpha];

    if (!selfAsView.isUserInteractionEnabled) {
      [description appendString:@"; UIE=N"];
    }
  }

  // Check if control is enabled.
  if ([self isKindOfClass:[UIControl class]] && !((UIControl *)self).isEnabled) {
    [description appendString:@"; disabled"];
  }

  // Text used for presentation.
  if ([self respondsToSelector:@selector(text)]) {
    // The text method of private class UIWebDocumentView can throw an exception when calling its
    // text method while loading a web page.
    @try {
      NSString *text = [self performSelector:@selector(text)];
      [description appendFormat:@"; text=\'%@\'", !text ? @"" : text];
    } @catch (NSException *exception) {
      NSLog(@"Caught exception when calling text method on %@", [self class]);
    }
  }

  [description appendString:@">"];
  return description;
}

- (NSString *)grey_shortDescription {
  NSMutableString *description = [[NSMutableString alloc] init];

  [description appendString:NSStringFromClass([self class])];

  if ([self respondsToSelector:@selector(accessibilityIdentifier)]) {
    NSString *accessibilityIdentifier = [self performSelector:@selector(accessibilityIdentifier)];
    NSString *axIdentifierDescription =
        [self grey_formattedDescriptionOrEmptyStringForValue:accessibilityIdentifier
                                                  withPrefix:@"; AX.id="];
    [description appendString:axIdentifierDescription];
  }

  if ([self respondsToSelector:@selector(accessibilityLabel)]) {
    NSString *axLabelDescription =
        [self grey_formattedDescriptionOrEmptyStringForValue:self.accessibilityLabel
                                                  withPrefix:@"; AX.label="];
    [description appendString:axLabelDescription];
  }

  return description;
}

#pragma mark - Swizzled Implementation

+ (void)greyswizzled_cancelPreviousPerformRequestsWithTarget:(id)aTarget {
  if ([NSThread isMainThread]) {
    [aTarget grey_unmapAllTrackersForAllPerformSelectorArguments];
  }

  SEL swizzledSEL = @selector(greyswizzled_cancelPreviousPerformRequestsWithTarget:);
  INVOKE_ORIGINAL_IMP1(void, swizzledSEL, aTarget);
}

+ (void)greyswizzled_cancelPreviousPerformRequestsWithTarget:(id)aTarget
                                                    selector:(SEL)aSelector
                                                      object:(id)anArgument {
  SEL swizzledSEL =
      @selector(greyswizzled_cancelPreviousPerformRequestsWithTarget:selector:object:);
  if ([NSThread isMainThread]) {
    NSArray *arguments = [self grey_arrayWithSelector:aSelector argument:anArgument];
    [aTarget grey_unmapAllTrackersForPerformSelectorArguments:arguments];

    SEL customPerformSEL = @selector(grey_customPerformSelectorWithParameters:);
    INVOKE_ORIGINAL_IMP3(void, swizzledSEL, aTarget, customPerformSEL, arguments);
  } else {
    INVOKE_ORIGINAL_IMP3(void, swizzledSEL, aTarget, aSelector, anArgument);
  }
}

#pragma mark - Package Internal

- (void)greyswizzled_performSelector:(SEL)aSelector
                          withObject:(id)anArgument
                          afterDelay:(NSTimeInterval)delay
                             inModes:(NSArray *)modes {
  if ([NSThread isMainThread]) {
    NSArray *arguments = [self grey_arrayWithSelector:aSelector argument:anArgument];
    // Track delayed executions on main thread that fall within a trackable duration.
    CFTimeInterval maxDelayToTrack =
        GREY_CONFIG_DOUBLE(kGREYConfigKeyDelayedPerformMaxTrackableDuration);
    if (maxDelayToTrack >= delay) {
      // As a safeguard, track the pending call for twice the amount incase the execution is
      // *really* delayed (due to cpu trashing) for more than the expected execution-time.
      // The custom selector will stop tracking as soon as it is triggered.
      NSString *trackerName = [NSString stringWithFormat:@"performSelector @selector(%@) on %@",
                                  NSStringFromSelector(aSelector), NSStringFromClass([self class])];
      // For negative delays use 0.
      NSTimeInterval nonNegativeDelay = MAX(0, 2 * delay);
      GREYTimedIdlingResource *tracker =
          [GREYTimedIdlingResource resourceForObject:@"Delayed performSelector"
                               thatIsBusyForDuration:nonNegativeDelay
                                                name:trackerName];
      // Setup custom selector to be called after delay.
      [self grey_mapPerformSelectorArguments:arguments toTracker:tracker];
    }
    INVOKE_ORIGINAL_IMP4(void,
                         @selector(greyswizzled_performSelector:withObject:afterDelay:inModes:),
                         @selector(grey_customPerformSelectorWithParameters:),
                         arguments,
                         delay,
                         modes);
  } else {
    INVOKE_ORIGINAL_IMP4(void,
                         @selector(greyswizzled_performSelector:withObject:afterDelay:inModes:),
                         aSelector,
                         anArgument,
                         delay,
                         modes);
  }
}

#pragma mark - Private

/**
 *  A custom performSelector that peforms the selector specified in @c arguments on itself.
 *  @c arguments[0] must be the selector to forward to the call to. If a non @c nil object was
 *  passed to NSObject::performSelector:withObject: @c arguments[2] must point to it.
 *
 *  @param arguments An array of arguments that include a selector, an object (on which to invoke
 *                   the selector) optionally followed by the arguments to be passed to the
 *                   selector.
 */
- (void)grey_customPerformSelectorWithParameters:(NSArray *)arguments {
  GREYFatalAssertWithMessage(arguments.count >= 1,
                             @"at the very least, an entry to selector must be present.");
  SEL selector = [arguments[0] pointerValue];
  id objectParam = (arguments.count > 1) ? arguments[1] : nil;

  [self grey_unmapSingleTrackerForPerformSelectorArguments:arguments];
  NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
  // First two arguments are always self and _cmd.
  if (methodSignature.numberOfArguments > 2) {
    void (*originalFunc)(id, SEL, id) = (void (*)(id, SEL, id))[self methodForSelector:selector];
    originalFunc(self, selector, objectParam);
  } else {
    void (*originalFunc)(id, SEL) = (void (*)(id, SEL))[self methodForSelector:selector];
    originalFunc(self, selector);
  }
}

/**
 *  Returns an array containing @c target, @c selector and @c argumentOrNil combination. Always use
 *  this when adding an entry to the dictionary for consistent key hashing.
 *
 *  @param selector      Selector to be added to the array.
 *  @param argumentOrNil Argument to be added to the array.
 *
 *  @return Array containing @c target, @c selector and @c argumentOrNil combination.
 */
- (NSArray *)grey_arrayWithSelector:(SEL)selector argument:(id)argumentOrNil {
  return [NSArray arrayWithObjects:[NSValue valueWithPointer:selector], argumentOrNil, nil];
}

/**
 *  Creates an entry in the global dictionary with (@c arguments, @c tracker) pair to track a single
 *  NSObject::performSelector:withObject:afterDelay:inModes: call.
 *
 *  @param arguments The arguments that were originally passed to
 *                   NSObject::performSelector:withObject:afterDelay:inModes: call.
 *  @param tracker   The idling resource that is tracking the
 *                   NSObject::performSelector:withObject:afterDelay:inModes: call.
 */
- (void)grey_mapPerformSelectorArguments:(NSArray *)arguments
                             toTracker:(GREYTimedIdlingResource *)tracker {
  @synchronized(self) {
    NSMutableDictionary *argsToTrackers = [self grey_performSelectorArgumentsToTrackerMap];
    NSMutableArray *trackers = argsToTrackers[arguments];
    if (!trackers) {
      trackers = [[NSMutableArray alloc] init];
    }
    [trackers addObject:tracker];
    argsToTrackers[arguments] = trackers;
  }
}

/**
 *  Removes a single tracker associated with the
 *  NSObject::performSelector:withObject:afterDelay:inModes: call having the given @c arguments.
 *
 *  @param arguments The arguments that whose tracker is to be removed.
 */
- (void)grey_unmapSingleTrackerForPerformSelectorArguments:(NSArray *)arguments {
  @synchronized(self) {
    NSMutableDictionary *argsToTrackers = [self grey_performSelectorArgumentsToTrackerMap];
    NSMutableArray *trackers = argsToTrackers[arguments];
    [[trackers lastObject] stopMonitoring];
    [trackers removeLastObject];
    if (trackers.count > 0) {
      argsToTrackers[arguments] = trackers;
    } else {
      [argsToTrackers removeObjectForKey:arguments];
    }
  }
}

/**
 *  Removes all trackers associated with the
 *  NSObject::performSelector:withObject:afterDelay:inModes: call having the given @c arguments.
 *
 *  @param arguments The arguments that whose tracker is to be removed.
 */
- (void)grey_unmapAllTrackersForPerformSelectorArguments:(NSArray *)arguments {
  @synchronized(self) {
    NSMutableDictionary *argsToTrackers = [self grey_performSelectorArgumentsToTrackerMap];
    NSMutableArray *trackers = argsToTrackers[arguments];
    while (trackers.count > 0) {
      [[trackers lastObject] stopMonitoring];
      [trackers removeLastObject];
    }
    [argsToTrackers removeObjectForKey:arguments];
  }
}

/**
 *  Clears all the performSelector entries tracked for self.
 */
- (void)grey_unmapAllTrackersForAllPerformSelectorArguments {
  @synchronized(self) {
    NSMutableDictionary *argsToTrackers = [self grey_performSelectorArgumentsToTrackerMap];
    for (NSArray *arguments in [[argsToTrackers allKeys] copy]) {
      [self grey_unmapAllTrackersForPerformSelectorArguments:arguments];
    }
    objc_setAssociatedObject(self,
                             @selector(grey_customPerformSelectorWithParameters:),
                             nil,
                             OBJC_ASSOCIATION_ASSIGN);
  }
}

/**
 *  @return A mutable dictionary for storing all tracked performSelector calls.
 */
- (NSMutableDictionary *)grey_performSelectorArgumentsToTrackerMap {
  @synchronized(self) {
    NSMutableDictionary *dictionary =
        objc_getAssociatedObject(self, @selector(grey_customPerformSelectorWithParameters:));
    if (!dictionary) {
      dictionary = [[NSMutableDictionary alloc] init];
      objc_setAssociatedObject(self,
                               @selector(grey_customPerformSelectorWithParameters:),
                               dictionary,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dictionary;
  }
}

/**
 *  Takes a value string, which if non-empty, is returned with a prefix attached, else an empty
 *  string is returned.
 *
 *  @param value  The string representing a value.
 *  @param prefix The prefix to be attached to the value
 *
 *  @return @c prefix appended to the @c value or empty string if @c value is @c nil.
 */
- (NSString *)grey_formattedDescriptionOrEmptyStringForValue:(NSString *)value
                                                  withPrefix:(NSString *)prefix {
  NSMutableString *description = [[NSMutableString alloc] initWithString:@""];
  if (value.length > 0) {
    [description appendString:prefix];
    [description appendFormat:@"\'%@\'", value];
  }
  return description;
}

@end
