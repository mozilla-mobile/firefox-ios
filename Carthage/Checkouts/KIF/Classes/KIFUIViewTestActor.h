//
//  KIFUIViewActor.h
//  KIF
//
//  Created by Alex Odawa on 1/21/15.
//
//

#import <KIF/KIF.h>

#define viewTester KIFActorWithClass(KIFUIViewTestActor)


@interface KIFUIViewTestActor : KIFTestActor

@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic, strong, readonly) UIAccessibilityElement *element;
@property (nonatomic, strong, readonly) NSPredicate *predicate;


/*!
 @abstract a static string to use when typing into text fields.
 @discussion Do not change this string to something that would be auto-corrected
 For example, "string-to-test" might be auto-corrected to some other string
 and hence cause a test to fail.
 */
extern NSString *const inputFieldTestString;

#pragma mark - Behavior modifiers

/*!
 @abstract Controls if typing methods will validate the entered text.
 @discussion This method will only impact the functioning of the `enterText:...` method variants.
 
 @param validateEnteredText Whether or not to validate the entered text. Defaults to YES.
 @return The message reciever, these methods are intended to be chained together.
 */
- (instancetype)validateEnteredText:(BOOL)validateEnteredText;

#pragma mark - Searching for Accessibility Elements

/*!
 These methods are used to build the tester's search predicate. they are intended to be chained together allowing for complex searches.
 You can also build constructor methods which return view testers configured to find a specific element.
 Example:
 
 - (KIFUiViewTestActor)saveButton {
    return [[[viewTester usingLabel:@"Save"] usingTraits:UIAccessibilityTraitButton] usingIdentifier:@"exampleSaveButton"];
 }
 
 ... later ...
 
 [self.saveButton tap];
 [self.saveButton waitForAbsenceOfView];

 Note that these methods do not perfom a search. The tester will only search for elements once the search predicate has been built and it recieves an action call.
*/

/*!
 @abstract Adds a check for an accessibility label to the tester's search predicate.
 @discussion The tester will evaluate accessibility elements looking for a matching accessibility label.
 @param accessibilityLabel The accessibility label of an element to match.
 @return The message reciever, these methods are intended to be chained together.
 */
- (instancetype)usingLabel:(NSString *)accessibilityLabel;

/*!
 @abstract Adds a check for an accessibility identifier to the tester's search predicate.
 @discussion The tester will evaluate accessibility elements looking for a matching accessibility identifier.
 @param accessibilityIdentifier The accessibility identifier of an element to match.
 @return The message reciever, these methods are intended to be chained together.
 */
- (instancetype)usingIdentifier:(NSString *)accessibilityIdentifier;

/*!
 @abstract Adds a check for accessibility traits to the tester's search predicate.
 @discussion The tester will evaluate accessibility elements looking for matching accessibility traits.
 Note: You cannot assert the lack of accessibility traits by passing in UIAccessibilityTraitsNone.
 @param accessibilityTraits The accessibility traits of an element to match.
 @return The message reciever, these methods are intended to be chained together.
 */
- (instancetype)usingTraits:(UIAccessibilityTraits)accessibilityTraits;

/*!
 @abstract Adds a check to avoid views with accessibility traits to the tester's search predicate.
 @discussion The tester will evaluate accessibility elements for the purposes of excluding accessibility traits.
 If more than one trait is supplied in the bitmask, none of them may be present in order for this to be true.
 Note: You cannot assert the presence of accessibility traits by passing in UIAccessibilityTraitsNone.

 Example:
 Given a view with the accessibility traits .Button | .Selected, and we request the absence of .KeyboardCommand, this will match.
 Given a view with the accessibility traits .Button | .Selected, and we request the absence of .KeyboardCommand | .PlaysSound, this will match.

 Given a view with the accessibility traits .Button | .Selected, and we request the absence of .Selected, this will not match.
 Given a view with the accessibility traits .Button | .Selected, and we request the absence of .Button | .Selected, this will not match.
 Given a view with the accessibility traits .Button | .Selected, and we request the absence of .KeyboardCommand | .Button, this will not match.

 @return The message reciever, these methods are intended to be chained together.
 */
- (instancetype)usingAbsenceOfTraits:(UIAccessibilityTraits)accessibilityTraits;

/*!
 @abstract Adds a check for an accessibility value to the tester's search predicate.
 @discussion The tester will evaluate accessibility elements looking for a matching accessibility value.
 @param accessibilityValue The accessibility value of an element to match.
 @return The message reciever, these methods are intended to be chained together.
 */
- (instancetype)usingValue:(NSString *)accessibilityValue;

/*!
 @abstract Adds a check to only operate on the current first responder.
 @discussion The tester will evaluate accessibility elements waiting for a first responder.
 @return The message reciever, these methods are intended to be chained together.
 */
- (instancetype)usingFirstResponder;

/*!
 @abstract Adds a given predicate to the tester's search predicate.
 @description The given predicate will be evaluated when searching for a matching view. You likely wont need this method very often, and should rely on the accessibility properties when possibile.
 @param predicate The predicate to add to the tester's search predicate.
 @return The message reciever, these methods are intended to be chained together.
 */
- (instancetype)usingPredicate:(NSPredicate *)predicate;

#pragma mark - Acting on Accessibility Elements

/*!
 These methods are used to perform a search agains the tester's search predicate , then perform a given action on the first match.
 Note that these methods do not define the accessibility element to search for. Calling many of these methods without first specifying a search predicate via the usingXXX methods will result in test failure.
 */

#pragma mark Tapping, Pressing & Swiping

/*!
 @abstract Tap a view matching the tester's search predicate.
 @discussion The tester will evaluate the accessibility hierarchy against it's search predicate and perform a tap on the first match.
 */
- (void)tap;
/*!
 @abstract Long Press a view matching the tester's search predicate.
 @discussion The tester will fist evaluate the accessibility hierarchy against it's search predicate and perform a long press on the first match.
 */
- (void)longPress;
/*!
 @abstract Long Press a view matching the tester's search predicate.
 @discussion The tester will first evaluate the accessibility hierarchy against it's search predicate and perform a long press on the first match.
 @param duration The duration to hold the long press.
 */
- (void)longPressWithDuration:(NSTimeInterval)duration;

/*!
 @abstract Taps the screen at a particular point.
 @discussion Taps the screen at a specific point. In general you should use the factory steps that tap a view based on its accessibility label, but there are situations where it's not possible to access a view using accessibility mechanisms. This step is more lenient than the steps that use the accessibility label, and does not wait for any particular view to appear, or validate that the tapped view is enabled or has interaction enabled. Because this step doesn't validate that a view is present before tapping it, it's good practice to precede this step where possible with a -waitForViewWithAccessibilityLabel: with the label for another view that should appear on the same screen.

 @param screenPoint The point in screen coordinates to tap. Screen points originate from the top left of the screen.
 */
- (void)tapScreenAtPoint:(CGPoint)screenPoint;

/*!
 @abstract Swipe a view matching the tester's search predicate.
 @discussion The tester will first evaluate the accessibility hierarchy against it's search predicate and perform a swipe in the given direction on the first match
 @param direction The direction to swipe in.
 */
- (void)swipeInDirection:(KIFSwipeDirection)direction;

#pragma mark Waiting & Finding

/*!
 @abstract Waits until a view or accessibility element matching the tester's search predicate is present.
 @discussion The view or accessibility element is searched for in the view hierarchy. If the element isn't found, then the step will attempt to wait until it is. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 
 If the view you want to wait for is tappable, use the -waitToBecomeTappable method instead as it provides a more strict test. 
 @return The found view, if applicable.
 */
- (UIView *)waitForView;

/*!
 @abstract Waits until a view or accessibility element matching the tester's search predicate is present and available for tapping.
 @discussion The view or accessibility elemenr is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Whether or not a view is tappable is based on -[UIView hitTest:]

 @return The found view, if applicable.
 */
- (UIView *)waitForTappableView;

/*!
 @abstract Waits until a view or accessibility element is no longer present.
 @discussion The view or accessibility element is searched for in the view hierarchy. If the element is found, then the step will attempt to wait until it isn't. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are considered absent.
 */
- (void)waitForAbsenceOfView;

/*!
 @abstract Waits until a view or accessibility element matching the tester's search predicate is present and available for tapping.
 @discussion The view or accessibility elemenr is searched for in the view hierarchy. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Whether or not a view is tappable is based on -[UIView hitTest:]. */
- (void)waitToBecomeTappable DEPRECATED_MSG_ATTRIBUTE("Use 'waitForTappableView' instead.");

/*!
 @abstract Waits until a view or accessibility element matching the tester's search predicate is the first responder.
 @discussion The first responder is found by searching the view hierarchy of the application's
 main window and its accessibility label is compared to the given value. If they match, the
 step returns success else it will attempt to wait until they do.
 */
- (void)waitToBecomeFirstResponder;

/*!
 @abstract Confirms whether a view or accessibility element matching the tester's search predicate is present at the given moment.
 @discussion The view or accessibility element is searched for in the view hierarchy. If the element isn't found, then the step will not wait and instead immediately return NO. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 @return a BOOL reflecting whether or not the view was found.
 */
- (BOOL)tryFindingView;

/*!
 @abstract Confirms whether a view or accessibility element matching the tester's search predicate is present and tappable at the given moment.
 @discussion The view or accessibility element is searched for in the view hierarchy. If the element isn't found, then the step will not wait and instead immediately return NO. Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored. Whether or not a view is tappable is based on -[UIView hitTest:].
 @return a BOOL reflecting whether or not the view was found and tappable.
 */
- (BOOL)tryFindingTappableView;

/*!
 @abstract Tries to guess if there are any unfinished animations and waits for a certain amount of time to let them finish.
 */
- (void)waitForAnimationsToFinish;

#pragma mark Scroll Views, Table Views and Collection Views

/*!
 @abstract Taps the row at indexPath in a table view matching the tester's search predicate.
 @discussion This step will tap the row at indexPath.
 
 For cases where you may need to work from the end of a table view rather than the beginning, negative sections count back from the end of the table view (-1 is the last section) and negative rows count back from the end of the section (-1 is the last row for that section).
 
 @param indexPath Index path of the row to tap.
 */
- (void)tapRowInTableViewAtIndexPath:(NSIndexPath *)indexPath;

/*!
 @abstract Scrolls a table view matching the tester's search predicate while waiting for the cell at the given indexPath to appear.
 @discussion This step will get the cell at the indexPath.
 
 For cases where you may need to work from the end of a table view rather than the beginning, negative sections count back from the end of the table view (-1 is the last section) and negative rows count back from the end of the section (-1 is the last row for that section).
 
 @param indexPath Index path of the cell.
 @return The table view cell at the given index path.
 */
- (UITableViewCell *)waitForCellInTableViewAtIndexPath:(NSIndexPath *)indexPath;

/*!
 @abstract Scrolls a table view matching the tester's search predicate while waiting for the cell at the given indexPath to appear.
 @discussion This step will get the cell at the indexPath.
 
 For cases where you may need to work from the end of a table view rather than the beginning, negative sections count back from the end of the table view (-1 is the last section) and negative rows count back from the end of the section (-1 is the last row for that section).
 
 @param indexPath Index path of the cell.
 @param position Table View scroll position to scroll to. Useful for tall cells when the content needed is in a specific location.
 @return The table view cell at the given index path.
 */
- (UITableViewCell *)waitForCellInTableViewAtIndexPath:(NSIndexPath *)indexPath atPosition:(UITableViewScrollPosition)position;

/*!
 @abstract Moves the row at sourceIndexPath to destinationIndexPath in a table view matching the tester's search predicate.
 @discussion This step will move the row at sourceIndexPath to destinationIndexPath.
 
 For cases where you may need to work from the end of a table view rather than the beginning, negative sections count back from the end of the table view (-1 is the last section) and negative rows count back from the end of the section (-1 is the last row for that section).
 
 @param sourceIndexPath Index path of the row to move.
 @param destinationIndexPath Desired final index path of the row after moving.
 */
- (void)moveRowInTableViewAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

/*!
 @abstract Taps the item at indexPath in a collection view matching the tester's search predicate.
 @discussion This step will get the  collection view specified and tap the item at indexPath.
 
 For cases where you may need to work from the end of a collection view rather than the beginning, negative sections count back from the end of the collection view (-1 is the last section) and negative items count back from the end of the section (-1 is the last item for that section).
 
 @param indexPath Index path of the item to tap.
 */
- (void)tapCollectionViewItemAtIndexPath:(NSIndexPath *)indexPath;

/*!
 @abstract Scrolls a collection view while waiting for the cell at the given indexPath to appear.
 @discussion This step will get the cell at the indexPath.
 
 For cases where you may need to work from the end of a table view rather than the beginning, negative sections count back from the end of the table view (-1 is the last section) and negative rows count back from the end of the section (-1 is the last row for that section).
 
 @param indexPath Index path of the cell.
 @return Collection view cell at index path
 */
- (UICollectionViewCell *)waitForCellInCollectionViewAtIndexPath:(NSIndexPath *)indexPath;

/*!
 @abstract Scrolls a particular Scroll View in the view hierarchy by an amount indicated as a fraction of its size.
 @discussion The view will scroll by the indicated fraction of its size, with the scroll centered on the center of the view.
 @param horizontalFraction The horizontal displacement of the scroll action, as a fraction of the width of the view.
 @param verticalFraction The vertical displacement of the scroll action, as a fraction of the height of the view.
 */
- (void)scrollByFractionOfSizeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction;

#pragma mark Text Input

/*!
 @abstract Enters text into a particular view matching the tester's search predicate.
 @discussion If the element isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element, then text is entered into the view by simulating taps on the appropriate keyboard keys.
 @param text The text to enter.
 */
- (void)enterText:(NSString *)text;

/*!
 @abstract Enters text into a particular view matching the tester's search predicate, then asserts that the view contains the expected text.
 @discussion If the element isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element, then text is entered into the view by simulating taps on the appropriate keyboard keys.
 @param text The text to enter.
 @param expectedResult What the text value should be after entry completes, including any formatting done by the field. If this is nil, the "text" parameter will be used.
 */
- (void)enterText:(NSString *)text expectedResult:(NSString *)expectedResult;

/*!
 @abstract Enters text into a the current first responder.
 @discussion Text is entered into the view by simulating taps on the appropriate keyboard keys if the keyboard is already displayed. Useful to enter text in UIWebViews or components with no accessibility labels.
 @param text The text to enter.
 */
- (void)enterTextIntoCurrentFirstResponder:(NSString *)text DEPRECATED_MSG_ATTRIBUTE("Use 'usingFirstResponder' matcher with 'enterText:' instead.");
/*!
 @abstract Enters text into a the current first responder. if KIF is unable to type with the keyboard (which could be dismissed or obscured) the tester will call setText on the fallback view directly.
 @discussion Text is entered into the view by simulating taps on the appropriate keyboard keys if the keyboard is already displayed. Useful to enter text in UIWebViews or components with no accessibility labels.
 @param text The text to enter.
 @param fallbackView The UIView to enter if keyboard input fails.
 */
- (void)enterTextIntoCurrentFirstResponder:(NSString *)text fallbackView:(UIView *)fallbackView DEPRECATED_MSG_ATTRIBUTE("Please log a KIF Github issue if you have a use case for this.");

/*!
 @abstract Clears text from a particular view matching the tester's search predicate.
 @discussion If the element isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element, then text is cleared from the view by simulating taps on the backspace key.
 */
- (void)clearText;

/*!
 @abstract Clears text from the current first responder.
 @discussion text is cleared from the first responder by simulating taps on the backspace key.
 */

- (void)clearTextFromFirstResponder DEPRECATED_MSG_ATTRIBUTE("Use 'usingFirstResponder' matcher with 'clearText' instead.");

/*!
 @abstract Clears text from a particular view matching the tester's search predicate, then sets new text.
 @discussion If the element isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element, then text is cleared from the view by simulating taps on the backspace key, the new text is then entered by simulating taps on the appropriate keyboard keys.
 @param text The text to enter after clearing the view.
 */
- (void)clearAndEnterText:(NSString *)text;
/*!
 @abstract Clears text from a particular view matching the tester's search predicate, sets new text, then asserts that the view contains the expected text.
 @discussion If the element isn't currently tappable, then the step will attempt to wait until it is. Once the view is present and tappable, a tap event is simulated in the center of the view or element, then text is cleared from the view by simulating taps on the backspace key, the new text is then entered by simulating taps on the appropriate keyboard keys, finally the text of the view is compared against the expected result.
 @param text The text to enter after clearing the view.
 @param expectedResult What the text value should be after entry completes, including any formatting done by the field. If this is nil, the "text" parameter will be used.

 */
- (void)clearAndEnterText:(NSString *)text expectedResult:(NSString *)expectedResult;

/*!
 @abstract Sets text into a particular view matching the tester's search predicate.
 @discussion The text is set on the view directly with 'setText:'. Does not result in first responder changes. Does not perform expected result validation.
 @param text The text to set.
 */
- (void)setText:(NSString *)text;

/*!
 @abstract Validates the text in a field matches the supplied expected value.
 @discussion Waits until the view is present (up to the standard timeout), and then ensures that it has expected text.
 @param expectedResult The text to expect the view to contain.
 */
- (void)expectToContainText:(NSString *)expectedResult;

/*!
 @abstract Waits for the software keyboard to be visible.
 @discussion If input is also possible from a hardare keyboard @c waitForKeyInputReady may be more appropriate.
 */
- (void)waitForSoftwareKeyboard;

/*!
 @abstract If present, waits for the software keyboard to dismiss.
 */
- (void)waitForAbsenceOfSoftwareKeyboard;

/*!
 @abstract Waits for the keyboard to be ready for input.  This tests whether or not a hardware or software keyboard is available and if the keyboard has a responder to send events to.
 */
- (void)waitForKeyInputReady;

#pragma mark Specific Controls

/*!
 @abstract Slides a UISlider to a specified value.
 @discussion Searches for a UISlider matching the tester's search predicate. If the element isn't found or isn't currently tappable, then the step will attempt to wait until it is. Once the view is present, the step will attempt to drag the slider to the new value.  The step will fail if it finds a view matching the tester's search predicate that is not a UISlider or if value is outside of the possible values.  Because this step simulates drag events, the value reached may not be the exact value requested and the app may ignore the touch events if the movement is less than the drag gesture recognizer's minimum distance.
 @param value The desired value of the UISlider.
 */
- (void)setSliderValue:(float)value;

/*!
 @abstract Toggles a UISwitch matching the tester's search predicate into a specified position.
 @discussion If the Switch isn't currently tappable, then the step will attempt to wait until it is. Once the view is present, the step will return if it's already in the desired position. If the switch is tappable but not in the desired position, a tap event is simulated in the center of the view or element, toggling the switch into the desired position.
 @param switchIsOn The desired position of the UISwitch.
 */
- (void)setSwitchOn:(BOOL)switchIsOn;

/*!
 @abstract Pulls down on the view matching the tester's search predicate to trigger a pull to refresh.
 @discussion This will enact the pull to refresh by pulling down the distance of 1/2 the height of the view found by the tester's search predicate.
 */
- (void)pullToRefresh;

/*!
 @abstract Pulls down on the view matching the tester's search predicate then hold for a given duration, then release to trigger a pull to refresh.
 @discussion This will enact the pull to refresh by pulling down the distance of 1/2 the height of the view found by the tester's search predicate. The view will be held down for the given duration and then released.
 @param pullDownDuration The enum describing the approximate time for the pull down to travel the entire distance
 */
- (void)pullToRefreshWithDuration:(KIFPullToRefreshTiming)pullDownDuration;

/*!
 @abstract Dismisses a popover on screen.
 @discussion With a popover up, tap at the top-left corner of the screen.
 */
- (void)dismissPopover;

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
 @abstract Selects an item from a currently visible date picker view in specified component. This can only be used on UIDatePicker objects and not UIPickerView objects.
 @discussion With a date picker view already visible, this step will find an item with the given title in given component, select that item, and tap the Done button.
 @param title The title of the row to select.
 @param component The component tester inteds to select the title in.
 */
- (void)selectDatePickerViewRowWithTitle:(NSString *)title inComponent:(NSInteger)component;

/*!
 @abstract Selects a value from a currently visible date picker view.
 @discussion With a date picker view already visible, this step will select the different rotating wheel values in order of how the array parameter is passed in. After it is done it will hide the date picker. It works with all 4 UIDatePickerMode* modes. The input parameter of type NSArray has to match in what order the date picker is displaying the values/columns. So if the locale is changing the input parameter has to be adjusted. Example: Mode: UIDatePickerModeDate, Locale: en_US, Input param: NSArray *date = @[@"June", @"17", @"1965"];. Example: Mode: UIDatePickerModeDate, Locale: de_DE, Input param: NSArray *date = @[@"17.", @"Juni", @"1965".
 @param datePickerColumnValues Each element in the NSArray represents a rotating wheel in the date picker control. Elements from 0 - n are listed in the order of the rotating wheels, left to right.
 */
- (void)selectDatePickerValue:(NSArray *)datePickerColumnValues;

/*!
 @abstract Selects a value from a currently visible date picker view, according to the search order specified.
 @discussion With a date picker view already visible, this step will select the different rotating wheel values in order of how the array parameter is passed in. Each value will be searched according to the search order provided. After it is done it will hide the date picker. It works with all 4 UIDatePickerMode* modes. The input parameter of type NSArray has to match in what order the date picker is displaying the values/columns. So if the locale is changing the input parameter has to be adjusted. Example: Mode: UIDatePickerModeDate, Locale: en_US, Input param: NSArray *date = @[@"June", @"17", @"1965"];. Example: Mode: UIDatePickerModeDate, Locale: de_DE, Input param: NSArray *date = @[@"17.", @"Juni", @"1965".
 @param datePickerColumnValues Each element in the NSArray represents a rotating wheel in the date picker control. Elements from 0 - n are listed in the order of the rotating wheels, left to right.
 @param searchOrder The order in which the values are being searched for selection in each compotent.
 */
- (void)selectDatePickerValue:(NSArray *)datePickerColumnValues withSearchOrder:(KIFPickerSearchOrder)searchOrder;

/*!
 @abstract Select a certain photo from the built in photo picker.
 @discussion This set of steps expects that the photo picker has been initiated and that the sheet is up. From there it will tap the "Choose Photo" button and select the desired photo.
 @param albumName The name of the album to select the photo from. (1-indexed)
 @param row The row number in the album for the desired photo. (1-indexed)
 @param column The column number in the album for the desired photo.
 */
- (void)choosePhotoInAlbum:(NSString *)albumName atRow:(NSInteger)row column:(NSInteger)column;

/*!
 @abstract Taps the status bar at the top of the screen. This will fail if a status bar is not found.
 */
- (void)tapStatusBar;

#if TARGET_IPHONE_SIMULATOR
/*!
 @abstract If present, dismisses a system alert with the last button, usually 'Allow'. Returns YES if a dialog was dismissed, NO otherwise.
 @discussion Use this to dissmiss a location services authorization dialog or a photos access dialog by tapping the 'Allow' button. No action is taken if no alert is present.
 */
- (BOOL)acknowledgeSystemAlert;
#endif


@end
