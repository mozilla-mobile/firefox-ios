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

#import "Core/GREYKeyboard.h"

#include <objc/runtime.h>
#include <stdatomic.h>

#import "Action/GREYTapAction.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYAppleInternals.h"
#import "Common/GREYDefines.h"
#import "Common/GREYError.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYLogger.h"
#import "Core/GREYInteraction.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYAppStateTrackerObject.h"
#import "Synchronization/GREYCondition.h"
#import "Synchronization/GREYUIThreadExecutor.h"
#import "Synchronization/GREYRunLoopSpinner.h"

/**
 *  Action for tapping a keyboard key.
 */
static GREYTapAction *gTapKeyAction;

/**
 *  Flag set to @c true when the keyboard is shown, @c false when keyboard is hidden.
 */
static atomic_bool gIsKeyboardShown = false;

/**
 *  A character set for all alphabets present on a keyboard.
 */
static NSMutableCharacterSet *gAlphabeticKeyplaneCharacters;

/**
 *  Possible accessibility label values for the Shift Key.
 */
static NSArray *gShiftKeyLabels;

/**
 *  Accessibility labels for text modification keys, like shift, delete etc.
 */
static NSDictionary *gModifierKeyIdentifierMapping;

/**
 *  A retry time interval in which we re-tap the shift key to ensure
 *  the alphabetic keyplane changed.
 */
static const NSTimeInterval kMaxShiftKeyToggleDuration = 3.0;

/**
 * Time to wait for the keyboard to appear or disappear.
 */
static const NSTimeInterval kKeyboardWillAppearOrDisappearTimeout = 10.0;

/**
 * Time to spin for the keyboard to change layout.
 */
static const NSTimeInterval kKeyboardLayoutChangeTimeout = 0.1;

/**
 *  Identifier for characters that signify a space key.
 */
static NSString *const kSpaceKeyIdentifier = @" ";

/**
 *  Identifier for characters that signify a delete key.
 */
static NSString *const kDeleteKeyIdentifier = @"\b";

/**
 *  Identifier for characters that signify a return key.
 */
static NSString *const kReturnKeyIdentifier = @"\n";

@implementation GREYKeyboard : NSObject

+ (void)load {
  @autoreleasepool {
    NSObject *keyboardObject = [[NSObject alloc] init];
    // Hooks to keyboard lifecycle notification.
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];
    [defaultNotificationCenter addObserverForName:UIKeyboardWillShowNotification
                                           object:nil
                                            queue:nil
                                       usingBlock:^(NSNotification *note) {
      GREYAppStateTrackerObject *object =
          TRACK_STATE_FOR_OBJECT(kGREYPendingKeyboardTransition, keyboardObject);
      objc_setAssociatedObject(keyboardObject,
                               @selector(grey_keyboardObject),
                               object,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }];
    [defaultNotificationCenter addObserverForName:UIKeyboardDidShowNotification
                                           object:nil
                                            queue:nil
                                       usingBlock:^(NSNotification *note) {
      GREYAppStateTrackerObject *object =
          objc_getAssociatedObject(keyboardObject, @selector(grey_keyboardObject));
      UNTRACK_STATE_FOR_OBJECT(kGREYPendingKeyboardTransition, object);
      // There may be a zero size inputAccessoryView to track keyboard data.
      // This causes UIKeyboardDidShowNotification event to fire even though no keyboard is visible.
      // So intead of relying on keyboard show/hide event to detect the keyboard visibility, it is
      // necessary to double check on the actual frame to determine the true visibility.
      CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
      UIWindow *window = [UIApplication sharedApplication].keyWindow;
      keyboardFrame = [window convertRect:keyboardFrame fromWindow:nil];
      CGRect windowFrame = window.frame;
      CGRect frameIntersection = CGRectIntersection(windowFrame, keyboardFrame);
      bool keyboardVisible = frameIntersection.size.width > 1 && frameIntersection.size.height > 1;
      atomic_store(&gIsKeyboardShown, keyboardVisible);
    }];
    [defaultNotificationCenter addObserverForName:UIKeyboardWillHideNotification
                                           object:nil
                                            queue:nil
                                       usingBlock:^(NSNotification *note) {
      atomic_store(&gIsKeyboardShown, false);
      GREYAppStateTrackerObject *object =
          TRACK_STATE_FOR_OBJECT(kGREYPendingKeyboardTransition, keyboardObject);
      objc_setAssociatedObject(keyboardObject,
                               @selector(grey_keyboardObject),
                               object,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }];
    [defaultNotificationCenter addObserverForName:UIKeyboardDidHideNotification
                                           object:nil
                                            queue:nil
                                       usingBlock:^(NSNotification *note) {
      GREYAppStateTrackerObject *object =
          objc_getAssociatedObject(keyboardObject, @selector(grey_keyboardObject));
      UNTRACK_STATE_FOR_OBJECT(kGREYPendingKeyboardTransition, object);
    }];
  }
}

+ (void)initialize {
  if (self == [GREYKeyboard class]) {
    gTapKeyAction = [[GREYTapAction alloc] initWithType:kGREYTapTypeKBKey];
    // Note: more, numbers label must be after shift and SHIFT labels, because it is also used for
    // the key for switching between keyplanes.
    gShiftKeyLabels =
        @[ @"shift", @"Shift", @"SHIFT", @"more, symbols", @"more, numbers", @"numbers", @"more", @"MORE" ];

    NSCharacterSet *lowerCaseSet = [NSCharacterSet lowercaseLetterCharacterSet];
    gAlphabeticKeyplaneCharacters = [NSMutableCharacterSet uppercaseLetterCharacterSet];
    [gAlphabeticKeyplaneCharacters formUnionWithCharacterSet:lowerCaseSet];

    gModifierKeyIdentifierMapping = @{
        kSpaceKeyIdentifier : @"space",
        kDeleteKeyIdentifier : @"delete",
        kReturnKeyIdentifier : @"return"
    };
  }
}

+ (BOOL)typeString:(NSString *)string
    inFirstResponder:(id)firstResponder
               error:(__strong NSError **)errorOrNil {
  if ([string length] < 1) {
    GREYPopulateErrorOrLog(errorOrNil,
                           kGREYInteractionErrorDomain,
                           kGREYInteractionActionFailedErrorCode,
                           @"Failed to type, because the string provided was empty.");

    return NO;
  } else if (!atomic_load(&gIsKeyboardShown)) {
    NSString *description = [NSString stringWithFormat:@"Failed to type string '%@', "
                                                       @"because keyboard was not shown on screen.",
                             string];

    GREYPopulateErrorOrLog(errorOrNil,
                           kGREYInteractionErrorDomain,
                           kGREYInteractionActionFailedErrorCode,
                           description);

    return NO;
  }

  __block BOOL success = YES;
  for (NSUInteger i = 0; ((i < string.length) && success); i++) {
    NSString *characterAsString = [NSString stringWithFormat:@"%C", [string characterAtIndex:i]];
    NSLog(@"Attempting to type key %@.", characterAsString);

    id key = [GREYKeyboard grey_waitAndfindKeyForCharacter:characterAsString];
    // If key is not on the screen, try looking for it on another keyplane.
    if (!key) {
      unichar currentCharacter = [characterAsString characterAtIndex:0];
      if ([gAlphabeticKeyplaneCharacters characterIsMember:currentCharacter]) {
        GREYLogVerbose(@"Detected an alphabetic key.");
        // Switch to alphabetic keyplane if we are on numbers/symbols keyplane.
        if (![GREYKeyboard grey_isAlphabeticKeyplaneShown]) {
          NSString *moreLettersKeyAxLabel = iOS13_OR_ABOVE() ? @"letters" : @"more, letters";
          id moreLettersKey = [GREYKeyboard grey_waitAndfindKeyForCharacter:moreLettersKeyAxLabel];
          if (!moreLettersKey) {
            return [GREYKeyboard grey_setErrorForkeyNotFoundWithAccessibilityLabel:moreLettersKeyAxLabel
                                                                   forTypingString:string
                                                                             error:errorOrNil];
          }
          [GREYKeyboard grey_tapKey:moreLettersKey error:errorOrNil];
          key = [GREYKeyboard grey_waitAndfindKeyForCharacter:characterAsString];
        }
        // If key is not on the current keyplane, use shift to switch to the other one.
        if (!key) {
          key = [GREYKeyboard grey_toggleShiftAndFindKeyWithAccessibilityLabel:characterAsString
                                                                     withError:errorOrNil];
        }
      } else {
        GREYLogVerbose(@"Detected a non-alphabetic key.");
        // Switch to numbers/symbols keyplane if we are on alphabetic keyplane.
        if ([GREYKeyboard grey_isAlphabeticKeyplaneShown]) {
          NSString *moreNumberKeyAxLabel = iOS13_OR_ABOVE() ? @"numbers" : @"more, numbers";
          id moreNumbersKey = [GREYKeyboard grey_waitAndfindKeyForCharacter:moreNumberKeyAxLabel];
          if (!moreNumbersKey) {
            return
                [GREYKeyboard grey_setErrorForkeyNotFoundWithAccessibilityLabel:moreNumberKeyAxLabel
                                                                forTypingString:string
                                                                          error:errorOrNil];
          }
          [GREYKeyboard grey_tapKey:moreNumbersKey error:errorOrNil];
          key = [GREYKeyboard grey_waitAndfindKeyForCharacter:characterAsString];
        }
        // If key is not on the current keyplane, use shift to switch to the other one.
        if (!key) {
          if (![GREYKeyboard grey_toggleShiftKeyWithError:errorOrNil]) {
            success = NO;
            break;
          }
          key = [GREYKeyboard grey_waitAndfindKeyForCharacter:characterAsString];
        }
        // If key is not on either number or symbols keyplane, it could be on alphabetic keyplane.
        // This is the case for @ _ - on UIKeyboardTypeEmailAddress on iPad.
        if (!key) {
          NSString *moreLettersKeyAxLabel = iOS13_OR_ABOVE() ? @"letters" : @"more, letters";
          id moreLettersKey = [GREYKeyboard grey_waitAndfindKeyForCharacter:moreLettersKeyAxLabel];
          if (!moreLettersKey) {
            return [GREYKeyboard grey_setErrorForkeyNotFoundWithAccessibilityLabel:moreLettersKeyAxLabel
                                                                   forTypingString:string
                                                                             error:errorOrNil];
          }
          [GREYKeyboard grey_tapKey:moreLettersKey error:errorOrNil];
          key = [GREYKeyboard grey_waitAndfindKeyForCharacter:characterAsString];
        }
      }
      // If key is still not shown on screen, show error message.
      if (!key) {
        return [GREYKeyboard grey_setErrorForkeyNotFoundWithAccessibilityLabel:characterAsString
                                                               forTypingString:string
                                                                         error:errorOrNil];
      }
    }
    // A period key for an email UITextField on iOS9 and above types the email domain (.com, .org)
    // by default. That is not the desired behavior so check below disables it.
    BOOL keyboardTypeWasChangedFromEmailType = NO;
    if (iOS9_OR_ABOVE() &&
        [characterAsString isEqualToString:@"."] &&
        [firstResponder respondsToSelector:@selector(keyboardType)] &&
        [firstResponder keyboardType] == UIKeyboardTypeEmailAddress) {
      [firstResponder setKeyboardType:UIKeyboardTypeDefault];
      keyboardTypeWasChangedFromEmailType = YES;
    }

    // Keyboard was found; this action should always succeed.
    [GREYKeyboard grey_tapKey:key error:errorOrNil];

    // When space, delete or uppercase letter is typed, the keyboard will automatically change to
    // lower alphabet keyplane.
    // On iPad the layout changes faster than accessibility, so we need to wait for
    // accessibility change.
    unichar character = [characterAsString characterAtIndex:0];
    if ([characterAsString isEqualToString:kSpaceKeyIdentifier] ||
        [characterAsString isEqualToString:kDeleteKeyIdentifier] ||
        [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:character]) {
      [GREYKeyboard grey_waitAndfindKeyForCharacter:@"e"];
    }

    if (keyboardTypeWasChangedFromEmailType) {
      // Set the keyboard type back to the Email Type.
      [firstResponder setKeyboardType:UIKeyboardTypeEmailAddress];
    }
  }

  return success;
}

+ (BOOL)waitForKeyboardToAppear {
  if (atomic_load(&gIsKeyboardShown)) {
    return YES;
  }
  GREYCondition *keyboardIsShownCondition =
      [[GREYCondition alloc] initWithName:@"Keyboard will appear." block:^BOOL {
        return atomic_load(&gIsKeyboardShown);
      }];
  return [keyboardIsShownCondition waitWithTimeout:kKeyboardWillAppearOrDisappearTimeout];
}

+ (BOOL)isKeyboardShown {
  return atomic_load(&gIsKeyboardShown);
}

#pragma mark - Private

/**
 *  A utility method to continuously toggle the shift key on an alphabet keyplane until
 *  the correct character case is found.
 *
 *  @param      accessibilityLabel The accessibility label of the key for which
 *                                 the case is being changed.
 *  @param[out] errorOrNil         Error populated on failure.
 *
 *  @return The case toggled key for the accessibility label, or @c nil if it isn't found.
 */
+ (id)grey_toggleShiftAndFindKeyWithAccessibilityLabel:(NSString *)accessibilityLabel
                                           withError:(__strong NSError **)errorOrNil {
  __block id key = nil;
  __block NSError *error;
  GREYCondition *shiftToggleSucceded =
      [GREYCondition conditionWithName:@"Shift key toggled keyplane" block:^BOOL() {
     [GREYKeyboard grey_toggleShiftKeyWithError:&error];
     key = [GREYKeyboard grey_waitAndfindKeyForCharacter:accessibilityLabel];
     return (key != nil) || (error != nil);
   }];

  BOOL didTimeOut = ![shiftToggleSucceded waitWithTimeout:kMaxShiftKeyToggleDuration];
  if (didTimeOut) {
    GREYPopulateErrorOrLog(errorOrNil,
                           kGREYInteractionErrorDomain,
                           kGREYInteractionTimeoutErrorCode,
                           @"GREYKeyboard : Shift Key toggling timed out "
                           @"since key with correct case wasn't found");
  }

  return key;
}

/**
 *  Private API to toggle shift, because tapping on the key was flaky and required a 0.35 second
 *  wait due to accidental touch detection. The 0.35 seconds is the value within which, if a second
 *  tap occurs, then a double tap is registered.
 *
 *  @param[out] errorOrNil Error populated on failure.
 *
 *  @return YES if the shift toggle succeeded, else NO.
 */
+ (BOOL)grey_toggleShiftKeyWithError:(__strong NSError **)errorOrNil {
  GREYLogVerbose(@"Tapping on Shift key.");
  UIKeyboardImpl *keyboard = [GREYKeyboard grey_keyboardObject];
  // Clear time Shift key was pressed last to make sure the keyboard will not ignore this event.
  // If we do not reset this value, we would need to wait at least 0.35 seconds after toggling
  // Shift before we could reliably toggle it again. This is likely related to the double-tap
  // gesture used for shift-lock (also called caps-lock).
  [[keyboard _layout] setValue:[NSNumber numberWithDouble:0.0] forKey:@"_shiftLockFirstTapTime"];

  for (NSString *shiftKeyLabel in gShiftKeyLabels) {
    id key = [GREYKeyboard grey_waitAndfindKeyForCharacter:shiftKeyLabel];
    if (key) {
      // Shift key was found; this action should always succeed.
      [GREYKeyboard grey_tapKey:key error:errorOrNil];
      return YES;
    }
  }
  GREYPopulateErrorOrLog(errorOrNil,
                         kGREYInteractionErrorDomain,
                         kGREYInteractionActionFailedErrorCode,
                         @"GREYKeyboard: No known SHIFT key was found in the hierarchy.");
  return NO;
}

/**
 *  Get the key on the keyboard for a character to be typed. Will wait for the character if it is
 *  not on the keyboard layout yet.
 *
 *  @param character The character that needs to be typed.
 *
 *  @return A UI element that signifies the key to be tapped for typing action.
 */
+ (id)grey_waitAndfindKeyForCharacter:(NSString *)character {
  GREYFatalAssert(character);

  BOOL ignoreCase = NO;
  // If the key is a modifier key then we need to do a case-insensitive comparison and change the
  // accessibility label to the corresponding modifier key accessibility label.
  NSString *modifierKeyIdentifier = [gModifierKeyIdentifierMapping objectForKey:character];
  if (modifierKeyIdentifier) {
    // Check for the return key since we can have a different accessibility label
    // depending upon the keyboard.
    UIKeyboardImpl *currentKeyboard = [GREYKeyboard grey_keyboardObject];
    if ([character isEqualToString:kReturnKeyIdentifier]) {
      modifierKeyIdentifier = [currentKeyboard returnKeyDisplayName];
    }
    character = modifierKeyIdentifier;
    ignoreCase = YES;
  }

  // iOS 9 changes & to ampersand.
  if ([character isEqualToString:@"&"] && iOS9_OR_ABOVE()) {
    character = @"ampersand";
  }

  __block id result = nil;
  [GREYKeyboard grey_spinRunloopForKeyboardWithTimeout:kKeyboardLayoutChangeTimeout
                                  andStoppingCondition:^BOOL {
    result = [self grey_keyForCharacterValue:character
         inKeyboardLayoutWithCaseSensitivity:ignoreCase];
    return result != nil;
  }];
  return result;
}

/**
 *  Get the key on the keyboard for the given accessibility label.
 *
 *  @param character  A string identifying the key to be searched.
 *  @param ignoreCase A Boolean that is @c YES if searching for the key requires ignoring
 *                    the case. This is seen in the case of modifier keys that have
 *                    differing cases across iOS versions.
 *
 *  @return A key that has the given accessibility label.
 */
+ (id)grey_keyForCharacterValue:(NSString *)character
    inKeyboardLayoutWithCaseSensitivity:(BOOL)ignoreCase {
  UIKeyboardImpl *keyboard = [GREYKeyboard grey_keyboardObject];
  // Type of layout is private class UIKeyboardLayoutStar, which implements UIAccessibilityContainer
  // Protocol and contains accessibility elements for keyboard keys that it shows on the screen.
  id layout = [keyboard _layout];
  GREYFatalAssertWithMessage(layout, @"Layout instance must not be nil");
  if ([layout accessibilityElementCount] != NSNotFound) {
    for (NSInteger i = 0; i < [layout accessibilityElementCount]; ++i) {
      id key = [layout accessibilityElementAtIndex:i];
      if ((ignoreCase &&
           [[key accessibilityLabel] caseInsensitiveCompare:character] == NSOrderedSame) ||
          (!ignoreCase && [[key accessibilityLabel] isEqualToString:character])) {
        return key;
      }

      if ([key accessibilityIdentifier] &&
          [[key accessibilityIdentifier] isEqualToString:character]) {
        return key;
      }
    }
  }
  return nil;
}

/**
 *  A flag to check if the alphabetic keyplan is currently visible on the keyboard.
 *
 *  @return @c YES if the alphabetic keyplan is being shown on the keyboard, else @c NO.
 */
+ (BOOL)grey_isAlphabeticKeyplaneShown {
  // Arbitrarily choose e/E as the key to look for to determine if alphabetic keyplane is shown.
  return [GREYKeyboard grey_waitAndfindKeyForCharacter:@"e"] != nil
      || [GREYKeyboard grey_waitAndfindKeyForCharacter:@"E"] != nil;
}

/**
 *  Provides the active keyboard instance.
 *
 *  @return The active UIKeyboardImpl instance.
 */
+ (UIKeyboardImpl *)grey_keyboardObject {
  UIKeyboardImpl *keyboard = [UIKeyboardImpl activeInstance];
  GREYFatalAssertWithMessage(keyboard, @"Keyboard instance must not be nil");
  return keyboard;
}

/**
 *  Utility method to tap on a key on the keyboard.
 *
 *  @param      key        The key to be tapped.
 *  @param[out] errorOrNil The error to be populated. If this is @c nil,
 *                         then an error message is logged.
 */
+ (BOOL)grey_tapKey:(id)key error:(__strong NSError **)errorOrNil {
  GREYFatalAssert(key);

  NSLog(@"Tapping on key: %@.", [key accessibilityLabel]);
  BOOL success = [gTapKeyAction perform:key error:errorOrNil];
  [[[GREYKeyboard grey_keyboardObject] taskQueue] waitUntilAllTasksAreFinished];
  [[GREYUIThreadExecutor sharedInstance] drainOnce];
  return success;
}

/**
 *  Populates or prints an error whenever a key with an accessibility label isn't found during
 *  typing a string.
 *
 *  @param accessibilityLabel The accessibility label of the key
 *  @param string             The string being typed when the key was not found
 *  @param[out] errorOrNil    The error to be populated. If this is @c nil,
 *                            then an error message is logged.
 *
 *  @return NO every time since entering the method means an error has happened.
 */
+ (BOOL)grey_setErrorForkeyNotFoundWithAccessibilityLabel:(NSString *)accessibilityLabel
                                          forTypingString:(NSString *)string
                                                    error:(__strong NSError **)errorOrNil {
  NSString *description = [NSString stringWithFormat:@"Failed to type string '%@', "
                                                     @"because key [K] could not be found "
                                                     @"on the keyboard.",
                                                     string];
  NSDictionary *glossary = @{ @"K" : [accessibilityLabel description] };
  GREYPopulateErrorNotedOrLog(errorOrNil,
                              kGREYInteractionErrorDomain,
                              kGREYInteractionElementNotFoundErrorCode,
                              description,
                              glossary);
  return NO;
}

/**
 *  To wait for a keyboard animation or gesture, spin the runloop.
 *
 *  @param timeout            The timeout of the runloop spinner.
 *  @param stopConditionBlock The condition block used to stop the runloop spinner.
 */
+ (void)grey_spinRunloopForKeyboardWithTimeout:(NSTimeInterval)timeout
                          andStoppingCondition:(BOOL (^)(void))stopConditionBlock {
  GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];
  runLoopSpinner.timeout = timeout;
  runLoopSpinner.maxSleepInterval = DBL_MAX;
  [runLoopSpinner spinWithStopConditionBlock:stopConditionBlock];
}

@end
