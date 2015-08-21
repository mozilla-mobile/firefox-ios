//
//  KIFUITestActor+IdentifierTests.h
//  KIF
//
//  Created by Brian Nickel on 11/6/14.
//
//

#import "KIF.h"

@interface KIFUITestActor (IdentifierTests)

- (UIView *)waitForViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;
- (UIView *)waitForTappableViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;
- (void)tapViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;
- (void)waitForAbsenceOfViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

/*!
 @abstract Performs a long press on a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, touch events are simulated in the center of the view or element.
 @param accessibilityIdentifier The accessibility identifier of the element to tap.
 @param duration The length of time to long press the element.
 */
- (void)longPressViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier duration:(NSTimeInterval)duration;

/*!
 @abstract Enters text into a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element, then text is entered into the view by simulating taps on the appropriate keyboard keys.
 @param text The text to enter.
 @param accessibilityIdentifier The accessibility identifier of the element to type into.
 */
- (void)enterText:(NSString *)text intoViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

/*!
 @abstract Enters text into a particular view in the view hierarchy.
 @discussion The view or accessibility element with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element, then text is entered into the view by simulating taps on the appropriate keyboard keys.
 @param text The text to enter.
 @param accessibilityIdentifier The accessibility identifier of the element to type into.
 @param expectedResult What the text value should be after entry, including any formatting done by the field. If this is nil, the "text" parameter will be used.
 */
- (void)enterText:(NSString *)text intoViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier expectedResult:(NSString *)expectedResult;

- (void)clearTextFromViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

- (void)clearTextFromAndThenEnterText:(NSString *)text intoViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;
- (void)clearTextFromAndThenEnterText:(NSString *)text intoViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier expectedResult:(NSString *)expectedResult;

/*!
 @abstract Toggles a UISwitch into a specified position.
 @discussion The UISwitch with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present, the step will return if it's already in the desired position. If the switch is tappable but not in the desired position, a tap event is simulated in the center of the view or element, toggling the switch into the desired position.
 @param switchIsOn The desired position of the UISwitch.
 @param accessibilityIdentifier The accessibility identifier of the element to switch.
 */
- (void)setOn:(BOOL)switchIsOn forSwitchWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

/*!
 @abstract Slides a UISlider to a specified value.
 @discussion The UISlider with the given label is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present, the step will attempt to drag the slider to the new value.  The step will fail if it finds a view with the given accessibility label that is not a UISlider or if value is outside of the possible values.  Because this step simulates drag events, the value reached may not be the exact value requested and the app may ignore the touch events if the movement is less than the drag gesture recognizer's minimum distance.
 @param value The desired value of the UISlider.
 @param accessibilityIdentifier The accessibility identifier of the element to drag.
 */
- (void)setValue:(float)value forSliderWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

/*!
 @abstract Waits until a view or accessibility element is the first responder.
 @discussion The first responder is found by searching the view hierarchy of the application's
 main window and its accessibility identifier is compared to the given value. If they match, the
 step returns success else it will attempt to wait until they do.
 @param accessibilityIdentifier The accessibility identifier of the element to wait for.
 */
- (void)waitForFirstResponderWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

/*!
 @abstract returns YES or NO if the element is visible.
 @discussion if the element described by the accessibility identifier is visible, the method returns true.
 @param accessibilityIdentifier The accessibility identifier of the element to query for
 */
- (BOOL) tryFindingViewWithAccessibilityIdentifier:(NSString *) accessibilityIdentifier;

@end
