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

/*!
 @abstract Swipes a particular view in the view hierarchy in the given direction.
 @discussion This step will get the view with the specified accessibility identifier and swipe the screen in the given direction from the view's center.
 @param identifier The accessibility identifier of the view to swipe.
 @param direction The direction in which to swipe.
 */
- (void)swipeViewWithAccessibilityIdentifier:(NSString *)identifier inDirection:(KIFSwipeDirection)direction;

/*!
 @abstract Pulls down on the view that enables the pull to refresh.
 @discussion This will enact the pull to refresh by pulling down the distance of 1/2 the height of the view found by the accessibility identifier.
 @param identifierThe accessibility label of the view to perform the pull down on.
 */
- (void)pullToRefreshViewWithAccessibilityIdentifier:(NSString *)identifier;

/*!
 @abstract Pulls down on the view that enables the pull to refresh.
 @discussion This will enact the pull to refresh by pulling down the distance of 1/2 the height of the view found by the accessibility identifier.
 @param identifierThe accessibility label of the view to perform the pull down on.
 @param pullDownDuration The enum describing the approximate time for the pull down to travel the entire distance
 */
- (void)pullToRefreshViewWithAccessibilityIdentifier:(NSString *)identifier pullDownDuration:(KIFPullToRefreshTiming) pullDownDuration;

/*!
 @abstract Taps a stepper to either increment or decrement the stepper. Presumed that - (minus) to decrement is on the left.
 @discussion This will locate the left or right half of the stepper and perform a calculated click.
 @param identifier The accessibility identifier of the view to interact with.
 @param stepperDirection The direction in which to change the value of the stepper (KIFStepperDirectionIncrement | KIFStepperDirectionDecrement)
 */
-(void) tapStepperWithAccessibilityIdentifier: (NSString *)identifier increment: (KIFStepperDirection) stepperDirection;
@end
