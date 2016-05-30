//
//  KIFTester+UI.h
//  KIF
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "KIFTestActor.h"
#import <UIKit/UIKit.h>
#import "UIView-KIFAdditions.h"

#define tester KIFActorWithClass(KIFUITestActor)

/*!
 @enum KIFSwipeDirection
 @abstract Directions in which to swipe.
 @constant KIFSwipeDirectionRight Swipe to the right.
 @constant KIFSwipeDirectionLeft Swipe to the left.
 @constant KIFSwipeDirectionUp Swipe up.
 @constant KIFSwipeDirectionDown Swipe down.
 */
typedef NS_ENUM(NSUInteger, KIFSwipeDirection) {
    KIFSwipeDirectionRight,
    KIFSwipeDirectionLeft,
    KIFSwipeDirectionUp,
    KIFSwipeDirectionDown
};

/*!
 @enum KIFPickerType
 @abstract Picker type to select values from.
 @constant KIFUIPickerView UIPickerView type
 @constant KIFUIDatePicker UIDatePicker type
 */
typedef NS_ENUM(NSUInteger, KIFPickerType) {
    KIFUIPickerView,
    KIFUIDatePicker
};

/*!
 @enum KIFStepperDirection
 @abstract Direction in which to increment or decrement the stepper.
 @constant KIFStepperDirectionIncrement Increment the stepper
 @constant KIFUIDatePicker Decrement the stepper
 */
typedef NS_ENUM(NSUInteger, KIFStepperDirection) {
	KIFStepperDirectionIncrement,
	KIFStepperDirectionDecrement
};

/*!
 @enum KIFPullToRefreshTiming
 @discussion The approximate time in which the pull to refresh travels downward.
 @abstract Timing in which to perform the pull down before release.
 @constant KIFPullToRefreshInAboutAHalfSecond about half a second
 @constant KIFPullToRefreshInAboutOneSecond about one second
 @constant KIFPullToRefreshInAboutTwoSeconds about two seconds
 @constant KIFPullToRefreshInAboutThreeSeconds about three seconds.
 */
typedef NS_ENUM(NSUInteger, KIFPullToRefreshTiming) {
	KIFPullToRefreshInAboutAHalfSecond = 20, //faster
	KIFPullToRefreshInAboutOneSecond = 100,
	KIFPullToRefreshInAboutTwoSeconds = 150,
	KIFPullToRefreshInAboutThreeSeconds = 200, //slower
};

#define kKIFMajorSwipeDisplacement 200
#define kKIFMinorSwipeDisplacement 5

static inline KIFDisplacement KIFDisplacementForSwipingInDirection(KIFSwipeDirection direction)
{
    switch (direction)
    {
            // As discovered on the Frank mailing lists, it won't register as a
            // swipe if you move purely horizontally or vertically, so need a
            // slight orthogonal offset too.
        case KIFSwipeDirectionRight:
            return CGPointMake(kKIFMajorSwipeDisplacement, kKIFMinorSwipeDisplacement);
        case KIFSwipeDirectionLeft:
            return CGPointMake(-kKIFMajorSwipeDisplacement, kKIFMinorSwipeDisplacement);
        case KIFSwipeDirectionUp:
            return CGPointMake(kKIFMinorSwipeDisplacement, -kKIFMajorSwipeDisplacement);
        case KIFSwipeDirectionDown:
            return CGPointMake(kKIFMinorSwipeDisplacement, kKIFMajorSwipeDisplacement);
    }
}

@interface KIFUITestActor : KIFTestActor

/*!
 @abstract Waits until a view or accessibility element is present.
 @discussion The view or accessibility element with the given label is found in the view hierarchy. If the element isn't found, then the step will attempt to wait until it is. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 
 If the view you want to wait for is tappable, use the -waitForTappableViewWithAccessibilityLabel: methods instead as they provide a more strict test.
 @param label The accessibility label of the element to wait for.
 */
- (UIView *)waitForViewWithAccessibilityLabel:(NSString *)label;

/*!
 @abstract Waits until a view or accessibility element is present.
 @discussion The view or accessibility element with the given label is found in the view hierarchy. If the element isn't found, then the step will attempt to wait until it is. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 
 If the view you want to wait for is tappable, use the -waitForTappableViewWithAccessibilityLabel: methods instead as they provide a more strict test.
 @param label The accessibility label of the element to wait for.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (UIView *)waitForViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits;


/*!
 @abstract Waits until a view or accessibility element is present.
 @discussion The view or accessibility element with the given label is found in the view hierarchy. If the element isn't found, then the step will attempt to wait until it is. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 
 If the view you want to wait for is tappable, use the -waitForTappableViewWithAccessibilityLabel: methods instead as they provide a more strict test.
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 @result A configured test step.
 */
- (UIView *)waitForViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits;

/*!
 @abstract Waits until a view or accessibility element is no longer present.
 @discussion The view or accessibility element with the given label is found in the view hierarchy. If the element is found, then the step will attempt to wait until it isn't. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are considered absent.
 @param label The accessibility label of the element to wait for.
 */
- (void)waitForAbsenceOfViewWithAccessibilityLabel:(NSString *)label;

/*!
 @abstract Waits until a view or accessibility element is no longer present.
 @discussion The view or accessibility element with the given label is found in the view hierarchy. If the element is found, then the step will attempt to wait until it isn't. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are considered absent.
 @param label The accessibility label of the element to wait for.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (void)waitForAbsenceOfViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits;

/*!
 @abstract Waits until a view or accessibility element is no longer present.
 @discussion The view or accessibility element with the given label is found in the view hierarchy. If the element is found, then the step will attempt to wait until it isn't. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are considered absent.
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (void)waitForAbsenceOfViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits;

/*!
 @abstract Waits until a view or accessibility element is present and available for tapping.
 @discussion The view or accessibility element with the given label is found in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Whether or not a view is tappable is based on -[UIView hitTest:].
 @param label The accessibility label of the element to wait for.
 */
- (UIView *)waitForTappableViewWithAccessibilityLabel:(NSString *)label;

/*!
 @abstract Waits until a view or accessibility element is present and available for tapping.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Whether or not a view is tappable is based on -[UIView hitTest:].
 @param label The accessibility label of the element to wait for.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (UIView *)waitForTappableViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits;

/*!
 @abstract Waits until a view or accessibility element is present and available for tapping.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Whether or not a view is tappable is based on -[UIView hitTest:].
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (UIView *)waitForTappableViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits;


/*!
 @abstract Waits for an accessibility element and its containing view based on a variety of criteria.
 @discussion This method provides a more verbose API for achieving what is available in the waitForView/waitForTappableView family of methods, exposing both the found element and its containing view.  The results can be used in other methods such as @c tapAccessibilityElement:inView:
 @param element To be populated with the matching accessibility element when found.  Can be NULL.
 @param view To be populated with the matching view when found.  Can be NULL.
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 @param mustBeTappable If YES, only an element that can be tapped on will be returned.
 */
- (void)waitForAccessibilityElement:(UIAccessibilityElement **)element view:(out UIView **)view withLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable;

/*!
 @abstract Waits for an accessibility element and its containing view based the accessibility identifier.
 @discussion This method provides a more verbose API for achieving what is available in the waitForView/waitForTappableView family of methods, exposing both the found element and its containing view.  The results can be used in other methods such as @c tapAccessibilityElement:inView:
 @param element To be populated with the matching accessibility element when found.  Can be NULL.
 @param view To be populated with the matching view when found.  Can be NULL.
 @param identifier The accessibility identifier of the element to wait for.
 @param mustBeTappable If YES, only an element that can be tapped on will be returned.
 */
- (void)waitForAccessibilityElement:(UIAccessibilityElement **)element view:(out UIView **)view withIdentifier:(NSString *)identifier tappable:(BOOL)mustBeTappable;

/*!
 @abstract Waits for an accessibility element and its containing view based on a predicate.
 @discussion This method provides a more verbose API for achieving what is available in the waitForView/waitForTappableView family of methods, exposing both the found element and its containing view.  The results can be used in other methods such as @c tapAccessibilityElement:inView:
 
 This method provides more flexability than @c waitForAccessibilityElement:view:withLabel:value:traits:tappable: but less precise error messages.  This message will tell you why the method failed but not whether or not the element met some of the criteria.
 @param element To be populated with the matching accessibility element when found.  Can be NULL.
 @param view To be populated with the matching view when found.  Can be NULL.
 @param predicate The predicate to match.
 @param mustBeTappable If YES, only an element that can be tapped on will be returned.
 */
- (void)waitForAccessibilityElement:(UIAccessibilityElement **)element view:(out UIView **)view withElementMatchingPredicate:(NSPredicate *)predicate tappable:(BOOL)mustBeTappable;

/*!
 @abstract Tries to guess if there are any unfinished animations and waits for a certain amount of time to let them finish.
 */
- (void)waitForAnimationsToFinish;

/*!
 @abstract Tries to guess if there are any unfinished animations and waits for a certain amount of time to let them finish.
 @param timeout The maximum duration the method waits to let the animations finish.
 */
- (void)waitForAnimationsToFinishWithTimeout:(NSTimeInterval)timeout;

/*!
 @abstract Taps a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element.
 @param label The accessibility label of the element to tap.
 */
- (void)tapViewWithAccessibilityLabel:(NSString *)label;

/*!
 @abstract Taps a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element.
 @param label The accessibility label of the element to tap.
 @param traits The accessibility traits of the element to tap. Elements that do not include at least these traits are ignored.
 */
- (void)tapViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits;

/*!
 @abstract Taps a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element.
 
 This variation allows finding a particular instance of an accessibility element. For example, a table view might have multiple elements with the accessibility label of "Employee", but only one that also has the accessibility value of "Bob".
 @param label The accessibility label of the element to tap.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to tap. Elements that do not include at least these traits are ignored.
 */
- (void)tapViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits;

/*!
 @abstract Taps a particular view in the view heirarchy.
 @discussion Unlike the -tapViewWithAccessibilityLabel: family of methods, this method allows you to tap an arbitrary element.  Combined with -waitForAccessibilityElement:view:withLabel:value:traits:tappable: or +[UIAccessibilityElement accessibilityElement:view:withLabel:value:traits:tappable:error:] this provides an opportunity for more complex logic.
 @param element The accessibility element to tap.
 @param view The view containing the accessibility element.
 */
- (void)tapAccessibilityElement:(UIAccessibilityElement *)element inView:(UIView *)view;

/*!
 @abstract Taps the increment|decrement button of a UIStepper view in the view heirarchy.
 @discussion Unlike the -tapViewWithAccessibilityLabel: family of methods, this method allows you to tap an arbitrary element.  Combined with -waitForAccessibilityElement:view:withLabel:value:traits:tappable: or +[UIAccessibilityElement accessibilityElement:view:withLabel:value:traits:tappable:error:] this provides an opportunity for more complex logic.
 @param element The accessibility element to tap.
 @param view The view containing the accessibility element.
 */
- (void)tapStepperWithAccessibilityElement:(UIAccessibilityElement *)element increment: (KIFStepperDirection) stepperDirection inView:(UIView *)view;

/*!
 @abstract Taps the screen at a particular point.
 @discussion Taps the screen at a specific point. In general you should use the factory steps that tap a view based on its accessibility label, but there are situations where it's not possible to access a view using accessibility mechanisms. This step is more lenient than the steps that use the accessibility label, and does not wait for any particular view to appear, or validate that the tapped view is enabled or has interaction enabled. Because this step doesn't doesn't validate that a view is present before tapping it, it's good practice to precede this step where possible with a -waitForViewWithAccessibilityLabel: with the label for another view that should appear on the same screen.
 
 @param screenPoint The point in screen coordinates to tap. Screen points originate from the top left of the screen.
 */
- (void)tapScreenAtPoint:(CGPoint)screenPoint;

/*!
 @abstract Performs a long press on a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, touch events are simulated in the center of the view or element.
 @param label The accessibility label of the element to tap.
 @param duration The length of time to long press the element.
 */
- (void)longPressViewWithAccessibilityLabel:(NSString *)label duration:(NSTimeInterval)duration;

/*!
 @abstract Performs a long press on a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, touch events are simulated in the center of the view or element.
 
 This variation allows finding a particular instance of an accessibility element. For example, a table view might have multiple elements with the accessibility label of "Employee", but only one that also has the accessibility value of "Bob".
 @param label The accessibility label of the element to tap.
 @param value The accessibility value of the element to tap.
 @param duration The length of time to long press the element.
 */
- (void)longPressViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value duration:(NSTimeInterval)duration;

- (void)longPressAccessibilityElement:(UIAccessibilityElement *)element inView:(UIView *)view duration:(NSTimeInterval)duration;

/*!
 @abstract Performs a long press on a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, touch events are simulated in the center of the view or element.
 
 This variation allows finding a particular instance of an accessibility element. For example, a table view might have multiple elements with the accessibility label of "Employee", but only one that also has the accessibility value of "Bob".
 @param label The accessibility label of the element to tap.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to tap. Elements that do not include at least these traits are ignored.
 @param duration The length of time to long press the element.
 */
- (void)longPressViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits duration:(NSTimeInterval)duration;


/*!
 @abstract Waits for the software keyboard to be visible.
 @discussion If input is also possible from a hardare keyboard @c waitForKeyInputReady may be more appropriate.
 */
- (void)waitForSoftwareKeyboard;
- (void)waitForKeyboard KIF_DEPRECATED("Use waitForSoftwareKeyboard or waitForKeyInputReady.");

/*!
 @abstract If present, waits for the software keyboard to dismiss.
 */
- (void)waitForAbsenceOfSoftwareKeyboard;
- (void)waitForAbsenceOfKeyboard KIF_DEPRECATED("Use waitForAbscenseOfSoftwareKeyboard.");

/*!
 @abstract Waits for the keyboard to be ready for input.  This tests whether or not a hardware or software keyboard is available and if the keyboard has a responder to send events to.
 */
- (void)waitForKeyInputReady;

/*!
 @abstract Enters text into a the current first responder.
 @discussion Text is entered into the view by simulating taps on the appropriate keyboard keys if the keyboard is already displayed. Useful to enter text in UIWebViews or components with no accessibility labels.
 @param text The text to enter.
 */
- (void)enterTextIntoCurrentFirstResponder:(NSString *)text;
- (void)enterTextIntoCurrentFirstResponder:(NSString *)text fallbackView:(UIView *)fallbackView;

/*!
 @abstract Enters text into a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element, then text is entered into the view by simulating taps on the appropriate keyboard keys.
 @param text The text to enter.
 @param label The accessibility label of the element to type into.
 */
- (void)enterText:(NSString *)text intoViewWithAccessibilityLabel:(NSString *)label;

/*!
 @abstract Enters text into a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element, then text is entered into the view by simulating taps on the appropriate keyboard keys.
 @param text The text to enter.
 @param label The accessibility label of the element to type into.
 @param traits The accessibility traits of the element to type into. Elements that do not include at least these traits are ignored.
 @param expectedResult What the text value should be after entry, including any formatting done by the field. If this is nil, the "text" parameter will be used.
 */
- (void)enterText:(NSString *)text intoViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits expectedResult:(NSString *)expectedResult;

- (void)clearTextFromFirstResponder;
- (void)clearTextFromViewWithAccessibilityLabel:(NSString *)label;
- (void)clearTextFromViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits;
- (void)clearTextFromElement:(UIAccessibilityElement*)element inView:(UIView*)view;

- (void)clearTextFromAndThenEnterTextIntoCurrentFirstResponder:(NSString *)text;
- (void)clearTextFromAndThenEnterText:(NSString *)text intoViewWithAccessibilityLabel:(NSString *)label;
- (void)clearTextFromAndThenEnterText:(NSString *)text intoViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits expectedResult:(NSString *)expectedResult;

- (void)expectView:(UIView *)view toContainText:(NSString *)expectedResult;

/*!
 @abstract Selects an item from a currently visible picker view.
 @discussion With a picker view already visible, this step will find an item with the given title, select that item, and tap the Done button.
 @param title The title of the row to select.
 */
- (void)selectPickerViewRowWithTitle:(NSString *)title;

/*!
 @abstract Selects an item from a currently visible picker view in specified component.
 @discussion With a picker view already visible, this step will find an item with the given title in given component, select that item, and tap the Done button.
 @param title The title of the row to select.
 @param component The component tester inteds to select the title in.
 */
- (void)selectPickerViewRowWithTitle:(NSString *)title inComponent:(NSInteger)component;

/*!
 @abstract Selects a value from a currently visible date picker view.
 @discussion With a date picker view already visible, this step will select the different rotating weel values in order of how the array parameter is passed in. After it is done it will hide the date picker. It works with all 4 UIDatePickerMode* modes. The input parameter of type NSArray has to match in what order the date picker is displaying the values/columns. So if the locale is changing the input parameter has to be adjusted. Example: Mode: UIDatePickerModeDate, Locale: en_US, Input param: NSArray *date = @[@"June", @"17", @"1965"];. Example: Mode: UIDatePickerModeDate, Locale: de_DE, Input param: NSArray *date = @[@"17.", @"Juni", @"1965".
 @param datePickerColumnValues Each element in the NSArray represents a rotating wheel in the date picker control. Elements from 0 - n are listed in the order of the rotating wheels, left to right.
 */
- (void) selectDatePickerValue:(NSArray*)datePickerColumnValues;

/*!
 @abstract Toggles a UISwitch into a specified position.
 @discussion The UISwitch with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present, the step will return if it's already in the desired position. If the switch is tappable but not in the desired position, a tap event is simulated in the center of the view or element, toggling the switch into the desired position.
 @param switchIsOn The desired position of the UISwitch.
 @param label The accessibility label of the element to switch.
 */
- (void)setOn:(BOOL)switchIsOn forSwitchWithAccessibilityLabel:(NSString *)label;

/*!
 @abstract Slides a UISlider to a specified value.
 @discussion The UISlider with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present, the step will attempt to drag the slider to the new value.  The step will fail if it finds a view with the given accessibility label that is not a UISlider or if value is outside of the possible values.  Because this step simulates drag events, the value reached may not be the exact value requested and the app may ignore the touch events if the movement is less than the drag gesture recognizer's minimum distance.
 @param value The desired value of the UISlider.
 @param label The accessibility label of the element to drag.
 */
- (void)setValue:(float)value forSliderWithAccessibilityLabel:(NSString *)label;
- (void)setValue:(float)value forSlider:(UISlider *)slider;

/*!
 @abstract Dismisses a popover on screen.
 @discussion With a popover up, tap at the top-left corner of the screen.
 */
- (void)dismissPopover;

/*!
 @abstract Select a certain photo from the built in photo picker.
 @discussion This set of steps expects that the photo picker has been initiated and that the sheet is up. From there it will tap the "Choose Photo" button and select the desired photo.
 @param albumName The name of the album to select the photo from. (1-indexed)
 @param row The row number in the album for the desired photo. (1-indexed)
 @param column The column number in the album for the desired photo.
 */
- (void)choosePhotoInAlbum:(NSString *)albumName atRow:(NSInteger)row column:(NSInteger)column;

/*!
 @abstract Taps the row at indexPath in a table view with the given label.
 @discussion This step will get the view with the specified accessibility label and tap the row at indexPath.
 
 For cases where you may need to work from the end of a table view rather than the beginning, negative sections count back from the end of the table view (-1 is the last section) and negative rows count back from the end of the section (-1 is the last row for that section).
 
 @param tableViewLabel Accessibility label of the table view.
 @param indexPath Index path of the row to tap.
 */
- (void)tapRowInTableViewWithAccessibilityLabel:(NSString*)tableViewLabel atIndexPath:(NSIndexPath *)indexPath KIF_DEPRECATED("Use tapRowAtIndexPath:inTableViewWithAccessibilityIdentifier:");

/*!
 @abstract Taps the row at indexPath in a table view with the given identifier.
 @discussion This step will get the view with the specified accessibility identifier and tap the row at indexPath.
 
 For cases where you may need to work from the end of a table view rather than the beginning, negative sections count back from the end of the table view (-1 is the last section) and negative rows count back from the end of the section (-1 is the last row for that section).
 
 @param indexPath Index path of the row to tap.
 @param identifier Accessibility identifier of the table view.
 */
- (void)tapRowAtIndexPath:(NSIndexPath *)indexPath inTableViewWithAccessibilityIdentifier:(NSString *)identifier NS_AVAILABLE_IOS(5_0);

/*!
 @abstract Taps the item at indexPath in a collection view with the given identifier.
 @discussion This step will get the view with the specified accessibility identifier and tap the item at indexPath.
 
 For cases where you may need to work from the end of a collection view rather than the beginning, negative sections count back from the end of the collection view (-1 is the last section) and negative items count back from the end of the section (-1 is the last item for that section).
 
 @param indexPath Index path of the item to tap.
 @param identifier Accessibility identifier of the collection view.
 */
- (void)tapItemAtIndexPath:(NSIndexPath *)indexPath inCollectionViewWithAccessibilityIdentifier:(NSString *)identifier;

/*!
 @abstract Taps a stepper to either increment or decrement the stepper. Presumed that - (minus) to decrement is on the left.
 @discussion This will locate the left or right half of the stepper and perform a calculated click.
 @param label The accessibility identifier of the view to interact with.
 @param stepperDirection The direction in which to change the value of the stepper (KIFStepperDirectionIncrement | KIFStepperDirectionDecrement)
 */
-(void) tapStepperWithAccessibilityLabel: (NSString *)accessibilityLabel increment: (KIFStepperDirection) stepperDirection;

#if TARGET_IPHONE_SIMULATOR
/*!
 @abstract If present, dismisses a system alert with the last button, usually 'Allow'. Returns YES if a dialog was dismissed, NO otherwise.
 @discussion Use this to dissmiss a location services authorization dialog or a photos access dialog by tapping the 'Allow' button. No action is taken if no alert is present.
 */
- (BOOL)acknowledgeSystemAlert;
#endif

/*!
 @abstract Swipes a particular view in the view hierarchy in the given direction.
 @discussion The view will get the view with the specified accessibility label and swipe the screen in the given direction from the view's center.
 @param label The accessibility label of the view to swipe.
 @param direction The direction in which to swipe.
 */
- (void)swipeViewWithAccessibilityLabel:(NSString *)label inDirection:(KIFSwipeDirection)direction;

/*!
 @abstract Swipes a particular view in the view hierarchy in the given direction.
 @discussion The view will get the view with the specified accessibility label and swipe the screen in the given direction from the view's center.
 @param label The accessibility label of the view to swipe.
 @param value The accessibility value of the view to swipe.
 @param direction The direction in which to swipe.
 */
- (void)swipeViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value inDirection:(KIFSwipeDirection)direction;

/*!
 @abstract Swipes a particular view in the view hierarchy in the given direction.
 @discussion This step will get the view with the specified accessibility label and swipe the screen in the given direction from the view's center.
 @param label The accessibility label of the view to swipe.
 @param value The accessibility value of the view to swipe.
 @param traits The accessibility traits of the view to swipe. Elements that do not include at least these traits are ignored.
 @param direction The direction in which to swipe.
 */
- (void)swipeViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits inDirection:(KIFSwipeDirection)direction;

/*!
 @abstract Swipes a particular view in the view heirarchy.
 @discussion Unlike the -swipeViewWithAccessibilityLabel: family of methods, this method allows you to swipe an arbitrary element.  Combined with -waitForAccessibilityElement:view:withLabel:value:traits:tappable: or +[UIAccessibilityElement accessibilityElement:view:withLabel:value:traits:tappable:error:] this provides an opportunity for more complex logic.
 @param element The accessibility element to tap.
 @param viewToSwipe The view containing the accessibility element.
 */
- (void)swipeAccessibilityElement:(UIAccessibilityElement *)element inView:(UIView *)viewToSwipe inDirection:(KIFSwipeDirection)direction;

/*!
 @abstract Pulls down on the view that enables the pull to refresh.
 @discussion This will enact the pull to refresh by pulling down the distance of 1/2 the height of the view found by the accessibility label.
 @param label The accessibility label of the view to swipe.
 @param pullDownDuration The enum describing the approximate time for the pull down to travel the entire distance
 */
- (void)pullToRefreshViewWithAccessibilityLabel:(NSString *)label pullDownDuration:(KIFPullToRefreshTiming) pullDownDuration;

/*!
 @abstract Pulls down on the view that enables the pull to refresh.
 @discussion This will enact the pull to refresh by pulling down the distance of 1/2 the height of the view found by the accessibility label.
 @param label The accessibility label of the view to swipe.
 @param value The accessibility value of the view to swipe.
 */
- (void)pullToRefreshViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value;

/*!
 @abstract Pulls down on the view that enables the pull to refresh.
 @discussion This will enact the pull to refresh by pulling down the distance of 1/2 the height of the view found by the accessibility label.
 @param element The accessibility element to perform the pull down on.
 @param viewToSwipe The view containing the accessibility element.
 @param pullDownDuration The enum describing the approximate time for the pull down to travel the entire distance
 */
- (void)pullToRefreshAccessibilityElement:(UIAccessibilityElement *)element inView:(UIView *)viewToSwipe pullDownDuration:(KIFPullToRefreshTiming) pullDownDuration;

/*!
 @abstract Scrolls a particular view in the view hierarchy by an amount indicated as a fraction of its size.
 @discussion The view will get the view with the specified accessibility label and scroll it by the indicated fraction of its size, with the scroll centered on the center of the view.
 @param label The accessibility label of the view to scroll.
 @param horizontalFraction The horizontal displacement of the scroll action, as a fraction of the width of the view.
 @param verticalFraction The vertical displacement of the scroll action, as a fraction of the height of the view.
 */
- (void)scrollViewWithAccessibilityLabel:(NSString *)label byFractionOfSizeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction KIF_DEPRECATED("Use scrollViewWithAccessibilityIdentifier:byFractionOfSizeHorizontal:vertical:");

/*!
 @abstract Scrolls a particular view in the view hierarchy by an amount indicated as a fraction of its size.
 @discussion The view will get the view with the specified accessibility identifier and scroll it by the indicated fraction of its size, with the scroll centered on the center of the view.
 @param identifier The accessibility identifier of the view to scroll.
 @param horizontalFraction The horizontal displacement of the scroll action, as a fraction of the width of the view.
 @param verticalFraction The vertical displacement of the scroll action, as a fraction of the height of the view.
 */
- (void)scrollViewWithAccessibilityIdentifier:(NSString *)identifier byFractionOfSizeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction NS_AVAILABLE_IOS(5_0);

/*!
 @abstract Waits until a view or accessibility element is the first responder.
 @discussion The first responder is found by searching the view hierarchy of the application's
 main window and its accessibility label is compared to the given value. If they match, the
 step returns success else it will attempt to wait until they do.
 @param label The accessibility label of the element to wait for.
 */
- (void)waitForFirstResponderWithAccessibilityLabel:(NSString *)label;

/*!
 @abstract Waits until a view or accessibility element is the first responder.
 @discussion The first responder is found by searching the view hierarchy of the application's
 main window and its accessibility label is compared to the given value. If they match, the
 step returns success else it will attempt to wait until they do.
 @param label The accessibility label of the element to wait for.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (void)waitForFirstResponderWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits;

- (void)tapStatusBar;

/*!
 @abstract Waits for the cell at indexPath in a table view with the given identifier.
 @discussion This step will get the view with the specified accessibility identifier and then get the cell at the indexPath.
 
 For cases where you may need to work from the end of a table view rather than the beginning, negative sections count back from the end of the table view (-1 is the last section) and negative rows count back from the end of the section (-1 is the last row for that section).
 
 @param indexPath Index path of the cell.
 @param identifier Accessibility identifier of the table view.
 @result Table view cell at index path
 */
- (UITableViewCell *)waitForCellAtIndexPath:(NSIndexPath *)indexPath inTableViewWithAccessibilityIdentifier:(NSString *)identifier;

/*!
 @abstract Waits for the cell at indexPath in a collection view with the given identifier.
 @discussion This step will get the view with the specified accessibility identifier and then get the cell at indexPath.
 
 For cases where you may need to work from the end of a collection view rather than the beginning, negative sections count back from the end of the collection view (-1 is the last section) and negative items count back from the end of the section (-1 is the last item for that section).
 
 @param indexPath Index path of the item to tap.
 @param identifier Accessibility identifier of the collection view.
 @result Collection view cell at index path
 */
- (UICollectionViewCell *)waitForCellAtIndexPath:(NSIndexPath *)indexPath inCollectionViewWithAccessibilityIdentifier:(NSString *)identifier;

/*!
 @abstract Moves the row at sourceIndexPath to destinationIndexPath in a table view with the given identifier.
 @discussion This step will get the view with the specified accessibility identifier and move the row at sourceIndexPath to destinationIndexPath.
 
 For cases where you may need to work from the end of a table view rather than the beginning, negative sections count back from the end of the table view (-1 is the last section) and negative rows count back from the end of the section (-1 is the last row for that section).
 
 @param sourceIndexPath Index path of the row to move.
 @param destinationIndexPath Desired final index path of the row after moving.
 @param identifier Accessibility identifier of the table view.
 */
- (void)moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath inTableViewWithAccessibilityIdentifier:(NSString *)identifier;

/*!
 @abstract Swipes the row at indexPath in the given direction.
 
 @param indexPath Index path of the row to swipe.
 @param tableView Table view to operate on.
 @param direction Direction of the swipe.
 */
- (void)swipeRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView inDirection:(KIFSwipeDirection)direction;

/*!
 @abstract Backgrounds app using UIAutomation command, simulating pressing the Home button
 @param duration Amount of time for a background event before the app becomes active again
 */
- (void)deactivateAppForDuration:(NSTimeInterval)duration;

@end
