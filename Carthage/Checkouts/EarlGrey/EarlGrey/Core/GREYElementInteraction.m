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

#import "Core/GREYElementInteraction.h"

#import "Action/GREYAction.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Assertion/GREYAssertion.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Assertion/GREYAssertions+Internal.h"
#import "Assertion/GREYAssertions.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYDefines.h"
#import "Common/GREYError+Internal.h"
#import "Common/GREYError.h"
#import "Common/GREYErrorConstants.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYLogger.h"
#import "Common/GREYObjectFormatter.h"
#import "Common/GREYStopwatch.h"
#import "Common/GREYThrowDefines.h"
#import "Core/GREYElementFinder.h"
#import "Core/GREYElementInteraction+Internal.h"
#import "Core/GREYInteractionDataSource.h"
#import "Exception/GREYFrameworkException.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYMatcher.h"
#import "Matcher/GREYMatchers.h"
#import "Provider/GREYElementProvider.h"
#import "Provider/GREYUIWindowProvider.h"
#import "Synchronization/GREYUIThreadExecutor.h"

@interface GREYElementInteraction() <GREYInteractionDataSource>
@end

@implementation GREYElementInteraction {
  id<GREYMatcher> _rootMatcher;
  id<GREYMatcher> _searchActionElementMatcher;
  id<GREYMatcher> _elementMatcher;
  id<GREYAction> _searchAction;
  // If _index is set to NSUIntegerMax, then it is unassigned.
  NSUInteger _index;
}

@synthesize dataSource;

- (instancetype)initWithElementMatcher:(id<GREYMatcher>)elementMatcher {
  GREYThrowOnNilParameter(elementMatcher);

  self = [super init];
  if (self) {
    _elementMatcher = elementMatcher;
    _index = NSUIntegerMax;
    [self setDataSource:self];
  }
  return self;
}

- (instancetype)inRoot:(id<GREYMatcher>)rootMatcher {
  _rootMatcher = rootMatcher;
  return self;
}

- (instancetype)atIndex:(NSUInteger)index {
  _index = index;
  return self;
}

#pragma mark - Package Internal

- (NSArray *)matchedElementsWithTimeout:(CFTimeInterval)timeout error:(__strong NSError **)error {
  GREYFatalAssert(error);

  GREYLogVerbose(@"Scanning for element matching: %@", _elementMatcher);
  id<GREYInteractionDataSource> strongDataSource = [self dataSource];
  GREYFatalAssertWithMessage(strongDataSource,
                             @"strongDataSource must be set before fetching UI elements");

  GREYElementProvider *entireRootHierarchyProvider =
      [GREYElementProvider providerWithRootProvider:[strongDataSource rootElementProvider]];
  id<GREYMatcher> elementMatcher = _elementMatcher;
  if (_rootMatcher) {
    elementMatcher = grey_allOf(elementMatcher, grey_ancestor(_rootMatcher), nil);
  }
  GREYElementFinder *elementFinder = [[GREYElementFinder alloc] initWithMatcher:elementMatcher];
  NSError *searchActionError = nil;
  CFTimeInterval timeoutTime = CACurrentMediaTime() + timeout;
  // We want the search action to be performed at least once.
  static unsigned short kMinimumIterationAttempts = 1;
  unsigned short numIterations = 0;
  BOOL timedOut = NO;
  while (YES) {
    @autoreleasepool {
      // Find the element in the current UI hierarchy.
      GREYStopwatch *elementFinderStopwatch = [[GREYStopwatch alloc] init];
      [elementFinderStopwatch start];
      NSArray *elements = [elementFinder elementsMatchedInProvider:entireRootHierarchyProvider];
      [elementFinderStopwatch stop];
      GREYLogVerbose(@"Element found for matcher: %@\n with time: %f seconds",
                     _elementMatcher,
                     [elementFinderStopwatch elapsedTime]);
      if (elements.count > 0) {
        return elements;
      } else if (!_searchAction) {
        NSString *description =
            @"Interaction cannot continue because the desired element was not found.";
        GREYPopulateErrorOrLog(error,
                               kGREYInteractionErrorDomain,
                               kGREYInteractionElementNotFoundErrorCode,
                               description);
        return nil;
      } else if (searchActionError) {
        break;
      }

      // After a lookup, we should check if we have timed out. This is so that we can quit
      // appropriately after a timeout.
      timedOut = (timeoutTime - CACurrentMediaTime()) < 0;
      if (timedOut && numIterations >= kMinimumIterationAttempts) {
        break;
      }

      // Try to uncover the element by applying the search action.
      id<GREYInteraction> interaction =
          [[GREYElementInteraction alloc] initWithElementMatcher:_searchActionElementMatcher];
      // Don't fail if this interaction error's out. It might still have revealed the element
      // we're looking for.
      [interaction performAction:_searchAction error:&searchActionError];

      // After a search action, if we have timed out, then we drain the thread by passing 0.
      // Otherwise, passing negative will throw an exception.
      CFTimeInterval timeRemaining = timeoutTime - CACurrentMediaTime();
      if (timeRemaining < 0) {
        timeRemaining = 0;
      }
      // Drain here so that search at the beginning of the loop looks at stable UI.
      BOOL successful =
          [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:timeRemaining];
      // If not @c successful, then quit.
      if (!successful) {
        timedOut = YES;
        break;
      }
      ++numIterations;
    }
  }

  if (searchActionError) {
    GREYPopulateNestedErrorOrLog(error,
                                 kGREYInteractionErrorDomain,
                                 kGREYInteractionElementNotFoundErrorCode,
                                 @"Search action failed",
                                 searchActionError);
  } else if (timedOut) {
    CFTimeInterval interactionTimeout =
        GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    NSString *description = [NSString stringWithFormat:@"Interaction timed out after %g seconds "
                                                       @"while searching for element.",
                                                       interactionTimeout];

    NSError *timeoutError = GREYErrorMake(kGREYInteractionErrorDomain,
                                          kGREYInteractionTimeoutErrorCode,
                                          description);

    GREYPopulateNestedErrorOrLog(error,
                                 kGREYInteractionErrorDomain,
                                 kGREYInteractionElementNotFoundErrorCode,
                                 @"",
                                 timeoutError);
  }

  return nil;
}

#pragma mark - GREYInteractionDataSource

/**
 *  Default data source for this interaction if no datasource is set explicitly.
 */
- (id<GREYProvider>)rootElementProvider {
  return [GREYUIWindowProvider providerWithAllWindows];
}

#pragma mark - GREYInteraction

- (instancetype)performAction:(id<GREYAction>)action {
  return [self performAction:action error:nil];
}

- (instancetype)performAction:(id<GREYAction>)action error:(__strong NSError **)errorOrNil {
  GREYThrowOnNilParameterWithMessage(action, @"action can't be nil.");
  GREYFatalAssertMainThread();

  GREYLogVerbose(@"--Action started--");
  GREYLogVerbose(@"Action to perform: %@", [action name]);
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  [stopwatch start];

  @autoreleasepool {
    NSError *executorError;
    __block NSError *actionError = nil;

    // Create the user info dictionary for any notifications and set it up with the action.
    NSMutableDictionary *actionUserInfo = [[NSMutableDictionary alloc] init];
    [actionUserInfo setObject:action forKey:kGREYActionUserInfoKey];
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];

    CFTimeInterval interactionTimeout =
        GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);

    // Assign a flag that provides info if the interaction being performed failed.
    __block BOOL interactionFailed = NO;
    __weak __typeof__(self) weakSelf = self;

    GREYExecBlock actionExecBlock = ^{
      __typeof__(self) strongSelf = weakSelf;
      GREYFatalAssertWithMessage(strongSelf, @"Must not be nil");

      // Obtain all elements from the hierarchy and populate the passed error in case of
      // an element not being found.
      NSError *elementNotFoundError = nil;
      NSArray *elements = [strongSelf matchedElementsWithTimeout:interactionTimeout
                                                           error:&elementNotFoundError];
      id element = nil;
      if (elements) {
        // Get the uniquely matched element. If this is nil, then it means that there has been
        // an error in finding a unique element, such as multiple matcher error.
        element = [strongSelf grey_uniqueElementInMatchedElements:elements
                                                         andError:&actionError];
        if (element) {
          [actionUserInfo setObject:element forKey:kGREYActionElementUserInfoKey];
        } else {
          interactionFailed = YES;
          [actionUserInfo setObject:actionError forKey:kGREYActionErrorUserInfoKey];
        }
      } else {
        interactionFailed = YES;
        actionError = elementNotFoundError;
        [actionUserInfo setObject:elementNotFoundError forKey:kGREYActionErrorUserInfoKey];
      }
      // Post notification that the action is to be performed on the found element.
      [defaultNotificationCenter postNotificationName:kGREYWillPerformActionNotification
                                               object:nil
                                             userInfo:actionUserInfo];
      GREYLogVerbose(@"Performing action: %@\n with matcher: %@\n with root matcher: %@",
                     [action name], _elementMatcher, _rootMatcher);

      if (element && ![action perform:element error:&actionError]) {
        interactionFailed = YES;
        // Action didn't succeed yet no error was set.
        if (!actionError) {
          actionError = GREYErrorMake(kGREYInteractionErrorDomain,
                                      kGREYInteractionActionFailedErrorCode,
                                      @"Reason for action failure was not provided.");
        }
        // Add the error obtained from the action to the user info notification dictionary.
        [actionUserInfo setObject:actionError forKey:kGREYActionErrorUserInfoKey];
      }
      // Post notification for the process of an action's execution being completed. This
      // notification does not mean that the action was performed successfully.
      [defaultNotificationCenter postNotificationName:kGREYDidPerformActionNotification
                                               object:nil
                                             userInfo:actionUserInfo];

      // If we encounter a failure and going to raise an exception, raise it right away before
      // the main runloop drains any further.
      if (interactionFailed && !errorOrNil) {
        [strongSelf grey_handleFailureOfAction:action
                                   actionError:actionError
                          userProvidedOutError:nil];
      }
    };

    BOOL executionSucceeded =
        [[GREYUIThreadExecutor sharedInstance] executeSyncWithTimeout:interactionTimeout
                                                                block:actionExecBlock
                                                                error:&executorError];

    // Failure to execute due to timeout should be represented as interaction timeout.
    if (!executionSucceeded) {
      if ([executorError.domain isEqualToString:kGREYUIThreadExecutorErrorDomain] &&
          executorError.code == kGREYUIThreadExecutorTimeoutErrorCode) {
        NSString *actionTimeoutDesc =
            [NSString stringWithFormat:@"Failed to perform action within %g seconds.",
             interactionTimeout];
        actionError = GREYNestedErrorMake(kGREYInteractionErrorDomain,
                                          kGREYInteractionTimeoutErrorCode,
                                          actionTimeoutDesc,
                                          executorError);
      }
    }

    // Since we assign all errors found to the @c actionError, if either of these failed then
    // we provide it for error handling.
    BOOL actionFailed = !executionSucceeded || interactionFailed;
    if (actionFailed) {
      [self grey_handleFailureOfAction:action
                           actionError:actionError
                  userProvidedOutError:errorOrNil];
    }
    // Drain once to update idling resources and redraw the screen.
    [[GREYUIThreadExecutor sharedInstance] drainOnce];

    [stopwatch stop];
    if (actionFailed) {
      GREYLogVerbose(@"Action failed: %@ with time: %f seconds",
                     [action name],
                     [stopwatch elapsedTime]);
    } else {
      GREYLogVerbose(@"Action succeeded: %@ with time: %f seconds",
                     [action name],
                     [stopwatch elapsedTime]);
    }
  }
  GREYLogVerbose(@"--Action finished--");
  return self;
}

- (instancetype)assert:(id<GREYAssertion>)assertion {
  return [self assert:assertion error:nil];
}

- (instancetype)assert:(id<GREYAssertion>)assertion error:(__strong NSError **)errorOrNil {
  GREYThrowOnNilParameterWithMessage(assertion, @"assertion can't be nil.");
  GREYFatalAssertMainThread();

  GREYLogVerbose(@"--Assertion started--");
  GREYLogVerbose(@"Assertion to perform: %@", [assertion name]);
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  [stopwatch start];

  @autoreleasepool {
    NSError *executorError;
    __block NSError *assertionError = nil;

    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];

    CGFloat interactionTimeout =
        (CGFloat)GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    // Assign a flag that provides info if the interaction being performed failed.
    __block BOOL interactionFailed = NO;
    __weak __typeof__(self) weakSelf = self;

    GREYExecBlock assertionExecBlock = ^{
      __typeof__(self) strongSelf = weakSelf;
      GREYFatalAssertWithMessage(strongSelf, @"strongSelf must not be nil");

      // An error object that holds error due to element not found (if any). It is used only when
      // an assertion fails because element was nil. That's when we surface this error.
      NSError *elementNotFoundError = nil;
      // Obtain all elements from the hierarchy and populate the passed error in case of
      // an element not being found.
      NSArray *elements = [strongSelf matchedElementsWithTimeout:interactionTimeout
                                                           error:&elementNotFoundError];
      id element = (elements.count != 0) ?
      [strongSelf grey_uniqueElementInMatchedElements:elements andError:&assertionError] : nil;

      // Create the user info dictionary for any notifications and set it up with the assertion.
      NSMutableDictionary *assertionUserInfo = [[NSMutableDictionary alloc] init];
      [assertionUserInfo setObject:assertion forKey:kGREYAssertionUserInfoKey];

      // Post notification for the assertion to be checked on the found element.
      // We send the notification for an assert even if no element was found.
      BOOL multipleMatchesPresent = NO;
      if (element) {
        [assertionUserInfo setObject:element forKey:kGREYAssertionElementUserInfoKey];
      } else if (assertionError) {
        // Check for multiple matchers since we don't want the assertion to be checked when this
        // error surfaces.
        multipleMatchesPresent =
            (assertionError.code == kGREYInteractionMultipleElementsMatchedErrorCode ||
             assertionError.code == kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode);
        [assertionUserInfo setObject:assertionError forKey:kGREYAssertionErrorUserInfoKey];
      }
      [defaultNotificationCenter postNotificationName:kGREYWillPerformAssertionNotification
                                               object:nil
                                             userInfo:assertionUserInfo];
      GREYLogVerbose(@"Performing assertion: %@\n with matcher: %@\n with root matcher: %@",
                     [assertion name], _elementMatcher, _rootMatcher);

      // In the case of an assertion, we can have a nil element present as well. For this purpose,
      // we check the assertion directly and see if there was any issue. The only case where we
      // are completely sure we do not need to perform the action is in the case of a multiple
      // matcher.
      if (multipleMatchesPresent) {
        interactionFailed = YES;
      } else if (![assertion assert:element error:&assertionError]) {
        interactionFailed = YES;
        // Set the elementNotFoundError to the assertionError since the error has been utilized
        // already.
        if ([assertionError.domain isEqualToString:kGREYInteractionErrorDomain] &&
            (assertionError.code == kGREYInteractionElementNotFoundErrorCode)) {
          assertionError = elementNotFoundError;
        }
        // Assertion didn't succeed yet no error was set.
        if (!assertionError) {
          assertionError = GREYErrorMake(kGREYInteractionErrorDomain,
                                         kGREYInteractionAssertionFailedErrorCode,
                                         @"Reason for assertion failure was not provided.");
        }
        // Add the error obtained from the action to the user info notification dictionary.
        [assertionUserInfo setObject:assertionError forKey:kGREYAssertionErrorUserInfoKey];
      }

      // Post notification for the process of an assertion's execution on the specified element
      // being completed. This notification does not mean that the assertion was performed
      // successfully.
      [defaultNotificationCenter postNotificationName:kGREYDidPerformAssertionNotification
                                               object:nil
                                             userInfo:assertionUserInfo];

      // If we encounter a failure and going to raise an exception, raise it right away before
      // the main runloop drains any further.
      if (interactionFailed && !errorOrNil) {
        [strongSelf grey_handleFailureOfAssertion:assertion
                                   assertionError:assertionError
                             userProvidedOutError:nil];
      }
    };

    BOOL executionSucceeded =
        [[GREYUIThreadExecutor sharedInstance] executeSyncWithTimeout:interactionTimeout
                                                                block:assertionExecBlock
                                                                error:&executorError];

    // Failure to execute due to timeout should be represented as interaction timeout.
    if (!executionSucceeded) {
      if ([executorError.domain isEqualToString:kGREYUIThreadExecutorErrorDomain] &&
          executorError.code == kGREYUIThreadExecutorTimeoutErrorCode) {
        NSString *assertionTimeoutDesc =
            [NSString stringWithFormat:@"Failed to execute assertion within %g seconds.",
             interactionTimeout];
        assertionError = GREYNestedErrorMake(kGREYInteractionErrorDomain,
                                             kGREYInteractionTimeoutErrorCode,
                                             assertionTimeoutDesc,
                                             executorError);
      }
    }

    BOOL assertionFailed = !executionSucceeded || interactionFailed;
    if (assertionFailed) {
      [self grey_handleFailureOfAssertion:assertion
                           assertionError:assertionError
                     userProvidedOutError:errorOrNil];
    }

    [stopwatch stop];
    if (assertionFailed) {
      GREYLogVerbose(@"Assertion failed: %@ with time: %f seconds",
                     [assertion name],
                     [stopwatch elapsedTime]);
    } else {
      GREYLogVerbose(@"Assertion succeeded: %@ with time: %f seconds",
                     [assertion name],
                     [stopwatch elapsedTime]);    }
  }
  GREYLogVerbose(@"--Assertion finished--");
  return self;
}

- (instancetype)assertWithMatcher:(id<GREYMatcher>)matcher {
  return [self assertWithMatcher:matcher error:nil];
}

- (instancetype)assertWithMatcher:(id<GREYMatcher>)matcher error:(__strong NSError **)errorOrNil {
  id<GREYAssertion> assertion = [GREYAssertions grey_createAssertionWithMatcher:matcher];
  return [self assert:assertion error:errorOrNil];
}

- (instancetype)usingSearchAction:(id<GREYAction>)action
             onElementWithMatcher:(id<GREYMatcher>)matcher {
  GREYThrowOnNilParameter(action);
  GREYThrowOnNilParameter(matcher);

  _searchActionElementMatcher = matcher;
  _searchAction = action;
  return self;
}

# pragma mark - Private

/**
 *  From the set of matched elements, obtain one unique element for the provided matcher. In case
 *  there are multiple elements matched, then the one selected by the _@c index provided is chosen
 *  else the provided @c interactionError is populated.
 *
 *  @param[out] interactionError A passed error for populating if multiple elements are found.
 *                               If this is nil then cases like multiple matchers cannot be checked
 *                               for.
 *
 *  @return A uniquely matched element, if any.
 */
- (id)grey_uniqueElementInMatchedElements:(NSArray *)elements
                                 andError:(__strong NSError **)interactionError {
  // If we find that multiple matched elements are present, we narrow them down based on
  // any index passed or populate the passed error if the multiple matches are present and
  // an incorrect index was passed.
  if (elements.count > 1) {
    if (iOS13_OR_ABOVE()) {
      // Temporary fix for Xcode 11 beta 1.
      if (elements.count == 2 &&
          [[elements[0] accessibilityIdentifier]
              isEqualToString:[elements[1] accessibilityIdentifier]] &&
          [elements[0] isKindOfClass:[UITextField class]] &&
          [elements[1] isKindOfClass:NSClassFromString(@"UIAccessibilityTextFieldElement")])
        return elements[0];
    }
    // If the number of matched elements are greater than 1 then we have to use the index for
    // matching. We perform a bounds check on the index provided here and throw an exception if
    // it fails.
    if (_index == NSUIntegerMax) {
      *interactionError = [self grey_errorForMultipleMatchingElements:elements
                                  withMatchedElementsIndexOutOfBounds:NO];
      return nil;
    } else if (_index >= elements.count) {
      *interactionError = [self grey_errorForMultipleMatchingElements:elements
                                  withMatchedElementsIndexOutOfBounds:YES];
      return nil;
    } else {
      return [elements objectAtIndex:_index];
    }
  }
  // If you haven't got a multiple / element not found error then you have one single matched
  // element and can select it directly.
  return [elements firstObject];
}

/**
 *  Handles failure of an @c action.
 *
 *  @param action                 The action that failed.
 *  @param actionError            Contains the reason for failure.
 *  @param[out] userProvidedError The out error (or nil) provided by the user.
 *  @throws NSException to denote the failure of an action, thrown if the @c userProvidedError
 *          is nil on test failure.
 *
 *  @return Junk boolean value to suppress xcode warning to have "a non-void return
 *          value to indicate an error occurred"
 */
- (BOOL)grey_handleFailureOfAction:(id<GREYAction>)action
                       actionError:(NSError *)actionError
              userProvidedOutError:(__strong NSError **)userProvidedError {
  GREYFatalAssert(actionError);

  // Throw an exception if the user did not provide an out error.
  if (!userProvidedError) {
    // First check errors that can happen at the inner most level such as timeouts.
    NSDictionary * errorDescriptions =
        [[GREYError grey_nestedErrorDictionariesForError:actionError] objectAtIndex:0];

    if (errorDescriptions != nil) {
      NSString *errorDomain = errorDescriptions[kErrorDomainKey];
      NSInteger errorCode = [errorDescriptions[kErrorCodeKey] integerValue];
      if (([errorDomain isEqualToString:kGREYInteractionErrorDomain]) &&
          (errorCode == kGREYInteractionTimeoutErrorCode)) {
        NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

        errorDetails[kErrorDetailActionNameKey] = action.name;
        errorDetails[kErrorDetailRecoverySuggestionKey] = @"Increase timeout for matching element";
        errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
        NSArray *keyOrder = @[ kErrorDetailActionNameKey,
                               kErrorDetailElementMatcherKey,
                               kErrorDetailRecoverySuggestionKey ];

        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:kGREYObjectFormatIndent
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];
        NSString *reason = [NSString stringWithFormat:@"Matching element timed out.\n"
                                                      @"Exception with Action: %@\n",
                                                      reasonDetail];
        I_GREYTimeout(reason,
                      @"Error Trace: %@",
                      [GREYError grey_nestedDescriptionForError:actionError]);
        return NO;
      } else if (([errorDomain isEqualToString:kGREYUIThreadExecutorErrorDomain]) &&
                 (errorCode == kGREYUIThreadExecutorTimeoutErrorCode)) {
        NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

        errorDetails[kErrorDetailActionNameKey] = action.name;
        errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;

        NSArray *keyOrder = @[ kErrorDetailActionNameKey, kErrorDetailElementMatcherKey ];
        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:kGREYObjectFormatIndent
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];
        NSString *reason =
            [NSString stringWithFormat:@"Timed out while waiting to perform action.\n"
                                       @"Exception with Action: %@\n", reasonDetail];

        if ([actionError isKindOfClass:[GREYError class]]) {
          [(GREYError *)actionError setErrorInfo:errorDetails];
        }

        I_GREYTimeout(reason, @"Error Trace: %@",
                      [GREYError grey_nestedDescriptionForError:actionError]);
        return NO;
      }
    }

    // Second, check for errors with less specific reason (such as interaction error).
    if ([actionError.domain isEqualToString:kGREYInteractionErrorDomain]) {
      NSString *searchAPIInfo = [self grey_searchActionDescription];

      switch (actionError.code) {
        case kGREYInteractionElementNotFoundErrorCode: {
          NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

          errorDetails[kErrorDetailActionNameKey] = action.name;
          errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
          errorDetails[kErrorDetailRecoverySuggestionKey] =
              @"Check if the element exists in the UI hierarchy printed below. If it exists, "
              @"adjust the matcher so that it accurately matches element.";

          NSArray *keyOrder = @[ kErrorDetailActionNameKey,
                                 kErrorDetailElementMatcherKey,
                                 kErrorDetailRecoverySuggestionKey ];
          NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                  indent:kGREYObjectFormatIndent
                                                               hideEmpty:YES
                                                                keyOrder:keyOrder];
          NSString *reason = [NSString stringWithFormat:@"Cannot find UI element.\n"
                                                        @"Exception with Action: %@\n",
                                                        reasonDetail];

          if ([actionError isKindOfClass:[GREYError class]]) {
            [(GREYError *)actionError setErrorInfo:errorDetails];
          }

          I_GREYElementNotFound(reason,
                                @"%@Error Trace: %@",
                                searchAPIInfo,
                                [GREYError grey_nestedDescriptionForError:actionError]);
          return NO;
        }
        case kGREYInteractionMultipleElementsMatchedErrorCode: {
          NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

          errorDetails[kErrorDetailActionNameKey] = action.name;
          errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
          errorDetails[kErrorDetailRecoverySuggestionKey] =
              @"Create a more specific matcher to uniquely match an element. If that's not "
              @"possible then use atIndex: to select from one of the matched elements but the "
              @"order of elements may change.";

          NSArray *keyOrder = @[ kErrorDetailActionNameKey,
                                 kErrorDetailElementMatcherKey,
                                 kErrorDetailRecoverySuggestionKey ];
          NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                  indent:kGREYObjectFormatIndent
                                                               hideEmpty:YES
                                                                keyOrder:keyOrder];
          NSString *reason = [NSString stringWithFormat:@"Multiple UI elements matched "
                                                        @"for the given criteria.\n"
                                                        @"Exception with Action: %@\n",
                                                        reasonDetail];

          if ([actionError isKindOfClass:[GREYError class]]) {
            [(GREYError *)actionError setErrorInfo:errorDetails];
          }

          I_GREYMultipleElementsFound(reason,
                                      @"%@Error Trace: %@",
                                      searchAPIInfo,
                                      [GREYError grey_nestedDescriptionForError:actionError]);
          return NO;
        }
        case kGREYInteractionConstraintsFailedErrorCode: {
          NSArray *keyOrder = @[ kErrorDetailActionNameKey,
                                 kErrorDetailElementDescriptionKey,
                                 kErrorDetailConstraintRequirementKey,
                                 kErrorDetailConstraintDetailsKey,
                                 kErrorDetailRecoverySuggestionKey ];
          NSDictionary *errorInfo = [(GREYError *)actionError errorInfo];
          NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorInfo
                                                                  indent:kGREYObjectFormatIndent
                                                               hideEmpty:YES
                                                                keyOrder:keyOrder];

          NSString *reason = [NSString stringWithFormat:@"Cannot perform action due to "
                                                        @"constraint(s) failure.\n"
                                                        @"Exception with Action: %@\n",
                                                        reasonDetail];
          NSString *nestedError = [GREYError grey_nestedDescriptionForError:actionError];
          I_GREYConstraintsFailedWithDetails(reason, nestedError);
          return NO;
        }
      }
    }
    // Add unique failure messages for failure with unknown reason.
    NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

    errorDetails[kErrorDetailActionNameKey] = action.name;
    errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;

    NSArray *keyOrder = @[ kErrorDetailActionNameKey,
                           kErrorDetailElementMatcherKey ];
    NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                            indent:kGREYObjectFormatIndent
                                                         hideEmpty:YES
                                                          keyOrder:keyOrder];
    NSString *reason = [NSString stringWithFormat:@"An action failed. "
                                                  @"Please refer to the error trace below.\n"
                                                  @"Exception with Action: %@\n",
                                                  reasonDetail];
    I_GREYActionFail(reason,
                     @"Error Trace: %@",
                     [GREYError grey_nestedDescriptionForError:actionError]);
  } else {
    if ([actionError isKindOfClass:[GREYError class]]) {
      NSMutableDictionary *errorDetails =
          [[NSMutableDictionary alloc] initWithDictionary:((GREYError *)actionError).errorInfo];
      errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
      ((GREYError *)actionError).errorInfo = errorDetails;
    }
    *userProvidedError = actionError;
  }
  return NO;
}

/**
 *  Handles failure of an @c assertion.
 *
 *  @param assertion              The asserion that failed.
 *  @param assertionError         Contains the reason for the failure.
 *  @param[out] userProvidedError Error (or @c nil) provided by the user. When @c nil, an exception
 *                                is thrown to halt further execution of the test case.
 *  @throws NSException to denote an assertion failure, thrown if the @c userProvidedError
 *          is @c nil on test failure.
 *
 *  @return Junk boolean value to suppress xcode warning to have "a non-void return
 *          value to indicate an error occurred"
 */
- (BOOL)grey_handleFailureOfAssertion:(id<GREYAssertion>)assertion
                       assertionError:(NSError *)assertionError
                 userProvidedOutError:(__strong NSError **)userProvidedError {
  GREYFatalAssert(assertionError);

  // Throw an exception if the user did not provide an out error.
  if (!userProvidedError) {
    // first check errors that can happens at the inner most level
    // for example: executor error
    NSDictionary * errorDescriptions =
        [[GREYError grey_nestedErrorDictionariesForError:assertionError] objectAtIndex:0];

    if (errorDescriptions != nil) {
      NSString *errorDomain = errorDescriptions[kErrorDomainKey];
      NSInteger errorCode = [errorDescriptions[kErrorCodeKey] integerValue];
      if (([errorDomain isEqualToString:kGREYInteractionErrorDomain]) &&
          (errorCode == kGREYInteractionTimeoutErrorCode)) {
        NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

        errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
        errorDetails[kErrorDetailRecoverySuggestionKey] = @"Increase timeout for matching element";
        errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
        NSArray *keyOrder = @[ kErrorDetailAssertCriteriaKey,
                               kErrorDetailElementMatcherKey,
                               kErrorDetailRecoverySuggestionKey ];

        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:kGREYObjectFormatIndent
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];
        NSString *reason = [NSString stringWithFormat:@"Matching element timed out.\n"
                                                      @"Exception with Assertion: %@\n",
                                                      reasonDetail];

        if ([assertionError isKindOfClass:[GREYError class]]) {
          [(GREYError *)assertionError setErrorInfo:errorDetails];
        }

        I_GREYTimeout(reason,
                      @"Error Trace: %@",
                      [GREYError grey_nestedDescriptionForError:assertionError]);
        return NO;
      } else if (([errorDomain isEqualToString:kGREYUIThreadExecutorErrorDomain]) &&
                 (errorCode == kGREYUIThreadExecutorTimeoutErrorCode)) {
        NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

        errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
        errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;

        NSArray *keyOrder = @[ kErrorDetailAssertCriteriaKey,
                               kErrorDetailElementMatcherKey ];
        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:kGREYObjectFormatIndent
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];
        NSString *reason =
            [NSString stringWithFormat:@"Timed out while waiting to perform assertion.\n"
                                       @"Exception with Assertion: %@\n", reasonDetail];

        if ([assertionError isKindOfClass:[GREYError class]]) {
          [(GREYError *)assertionError setErrorInfo:errorDetails];
        }

        I_GREYTimeout(reason,
                      @"Error Trace: %@",
                      [GREYError grey_nestedDescriptionForError:assertionError]);
        return NO;
      }
    }

    // second, check for errors with less specific reason (such as interaction error)
    if ([assertionError.domain isEqualToString:kGREYInteractionErrorDomain]) {
      NSString *searchAPIInfo = [self grey_searchActionDescription];

      switch (assertionError.code) {
        case kGREYInteractionElementNotFoundErrorCode: {
          NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

          errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
          errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
          errorDetails[kErrorDetailRecoverySuggestionKey] =
              @"Check if the element exists in the UI hierarchy printed below. If it exists, "
              @"adjust the matcher so that it accurately matches element.";

          NSArray *keyOrder = @[ kErrorDetailAssertCriteriaKey,
                                 kErrorDetailElementMatcherKey,
                                 kErrorDetailRecoverySuggestionKey ];
          NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                  indent:kGREYObjectFormatIndent
                                                               hideEmpty:YES
                                                                keyOrder:keyOrder];
          NSString *reason = [NSString stringWithFormat:@"Cannot find UI Element.\n"
                                                        @"Exception with Assertion: %@\n",
                                                        reasonDetail];

          if ([assertionError isKindOfClass:[GREYError class]]) {
            [(GREYError *)assertionError setErrorInfo:errorDetails];
          }

          I_GREYElementNotFound(reason,
                                @"%@Error Trace: %@",
                                searchAPIInfo,
                                [GREYError grey_nestedDescriptionForError:assertionError]);
          return NO;
        }
        case kGREYInteractionMultipleElementsMatchedErrorCode: {
          NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

          errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
          errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
          errorDetails[kErrorDetailRecoverySuggestionKey] =
              @"Create a more specific matcher to narrow matched element";

          NSArray *keyOrder = @[ kErrorDetailAssertCriteriaKey,
                                 kErrorDetailElementMatcherKey,
                                 kErrorDetailRecoverySuggestionKey ];
          NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                  indent:kGREYObjectFormatIndent
                                                               hideEmpty:YES
                                                                keyOrder:keyOrder];
          NSString *reason = [NSString stringWithFormat:@"Multiple UI elements matched "
                                                        @"for given criteria.\n"
                                                        @"Exception with Assertion: %@\n",
                                                        reasonDetail];

          if ([assertionError isKindOfClass:[GREYError class]]) {
            [(GREYError *)assertionError setErrorInfo:errorDetails];
          }

          I_GREYMultipleElementsFound(reason,
                                      @"%@Error Trace: %@",
                                      searchAPIInfo,
                                      [GREYError grey_nestedDescriptionForError:assertionError]);
          return NO;
        }
      }
    }

    // Add unique failure messages for failure with unknown reason
    NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

    errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
    errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;

    NSArray *keyOrder = @[ kErrorDetailAssertCriteriaKey,
                           kErrorDetailElementMatcherKey ];
    NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                            indent:kGREYObjectFormatIndent
                                                         hideEmpty:YES
                                                          keyOrder:keyOrder];
    NSString *reason = [NSString stringWithFormat:@"An assertion failed.\n"
                                                  @"Exception with Assertion: %@\n",
                                                  reasonDetail];

    I_GREYAssertionFail(reason,
                        @"Error Trace: %@",
                        [GREYError grey_nestedDescriptionForError:assertionError]);
  } else {
    if ([assertionError isKindOfClass:[GREYError class]]) {
      NSMutableDictionary *errorDetails =
          [[NSMutableDictionary alloc] initWithDictionary:((GREYError *)assertionError).errorInfo];
      errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
      ((GREYError *)assertionError).errorInfo = errorDetails;
    }
    *userProvidedError = assertionError;
  }
  return NO;
}

/**
 *  Provides an error with @c kGREYInteractionMultipleElementsMatchedErrorCode for multiple
 *  elements matching the specified matcher. In case we have multiple matchers and the Index
 *  provided for not matching with it is out of bounds, then we set the error code to
 *  @c kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode.
 *
 *  @param matchingElements A set of matching elements.
 *  @param outOfBounds      A boolean that flags if the index for finding a matching element
 *                          is out of bounds.
 *
 *  @return Error for matching multiple elements.
 */
- (NSError *)grey_errorForMultipleMatchingElements:(NSArray *)matchingElements
               withMatchedElementsIndexOutOfBounds:(BOOL)outOfBounds {

  // Populate an array with the matching elements that are causing the exception.
  NSMutableArray *elementDescriptions =
      [[NSMutableArray alloc] initWithCapacity:matchingElements.count];

  [matchingElements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    [elementDescriptions addObject:[obj grey_description]];
  }];

  // Populate the multiple matching elements error.
  NSString *errorDescription;
  NSInteger errorCode;
  if (outOfBounds) {
    // Populate with an error specifying that the index provided for matching the multiple elements
    // was out of bounds.
    errorDescription = [NSString stringWithFormat:@"Multiple elements were matched: %@ with an "
                                                  @"index that is out of bounds of the number of "
                                                  @"matched elements. Please use an element "
                                                  @"index from 0 to %tu",
                                                  elementDescriptions,
                                                  ([elementDescriptions count] - 1)];
    errorCode = kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode;
  } else {
    // Populate with an error specifying that multiple elements were matched without providing
    // an index.
    errorDescription = [NSString stringWithFormat:@"Multiple elements were matched: %@. Please "
                                                  @"use selection matchers to narrow the "
                                                  @"selection down to single element.",
                                                  elementDescriptions];
    errorCode = kGREYInteractionMultipleElementsMatchedErrorCode;
  }

  // Populate the user info for the multiple matching elements error.
  return GREYErrorMake(kGREYInteractionErrorDomain, errorCode, errorDescription);
}

/**
 *  @return A String description of the current search action.
 */
- (NSString *)grey_searchActionDescription {
  if (_searchAction) {
    return [NSString stringWithFormat:@"Search action: %@. \nSearch action element matcher: %@.\n",
                                      _searchAction, _searchActionElementMatcher];
  } else {
    return @"";
  }
}

@end
