//
//  KIFTester+UI.m
//  KIF
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "KIFUITestActor.h"
#import "UIApplication-KIFAdditions.h"
#import "UIWindow-KIFAdditions.h"
#import "UIAccessibilityElement-KIFAdditions.h"
#import "UIView-KIFAdditions.h"
#import "UITableView-KIFAdditions.h"
#import "CGGeometry-KIFAdditions.h"
#import "NSError-KIFAdditions.h"
#import "KIFTypist.h"
#import "UIAutomationHelper.h"

@implementation KIFUITestActor

+ (void)initialize
{
    if (self == [KIFUITestActor class]) {
        [KIFTypist registerForNotifications];
    }
}

- (UIView *)waitForViewWithAccessibilityLabel:(NSString *)label
{
    return [self waitForViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone tappable:NO];
}

- (UIView *)waitForViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits
{
    return [self waitForViewWithAccessibilityLabel:label value:nil traits:traits tappable:NO];
}

- (UIView *)waitForViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits
{
    return [self waitForViewWithAccessibilityLabel:label value:value traits:traits tappable:NO];
}

- (UIView *)waitForTappableViewWithAccessibilityLabel:(NSString *)label
{
    return [self waitForViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone tappable:YES];
}

- (UIView *)waitForTappableViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits
{
    return [self waitForViewWithAccessibilityLabel:label value:nil traits:traits tappable:YES];
}

- (UIView *)waitForTappableViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits
{
    return [self waitForViewWithAccessibilityLabel:label value:value traits:traits tappable:YES];
}

- (UIView *)waitForViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable
{
    UIView *view = nil;
    @autoreleasepool {
        [self waitForAccessibilityElement:NULL view:&view withLabel:label value:value traits:traits tappable:mustBeTappable];
    }
    
    return view;
}

- (void)waitForAccessibilityElement:(UIAccessibilityElement **)element view:(out UIView **)view withLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        return [UIAccessibilityElement accessibilityElement:element view:view withLabel:label value:value traits:traits tappable:mustBeTappable error:error] ? KIFTestStepResultSuccess : KIFTestStepResultWait;
    }];
}

- (void)waitForAccessibilityElement:(UIAccessibilityElement **)element view:(out UIView **)view withIdentifier:(NSString *)identifier tappable:(BOOL)mustBeTappable
{
    if (![UIAccessibilityElement instancesRespondToSelector:@selector(accessibilityIdentifier)]) {
        [self failWithError:[NSError KIFErrorWithFormat:@"Running test on platform that does not support accessibilityIdentifier"] stopTest:YES];
    }
    
    [self waitForAccessibilityElement:element view:view withElementMatchingPredicate:[NSPredicate predicateWithFormat:@"accessibilityIdentifier = %@", identifier] tappable:mustBeTappable];
}

- (void)waitForAccessibilityElement:(UIAccessibilityElement **)element view:(out UIView **)view withElementMatchingPredicate:(NSPredicate *)predicate tappable:(BOOL)mustBeTappable
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        return [UIAccessibilityElement accessibilityElement:element view:view withElementMatchingPredicate:predicate tappable:mustBeTappable error:error] ? KIFTestStepResultSuccess : KIFTestStepResultWait;
    }];
}

- (void)waitForAbsenceOfViewWithAccessibilityLabel:(NSString *)label
{
    [self waitForAbsenceOfViewWithAccessibilityLabel:label traits:UIAccessibilityTraitNone];
}

- (void)waitForAbsenceOfViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits
{
    [self waitForAbsenceOfViewWithAccessibilityLabel:label value:nil traits:traits];
}

- (void)waitForAbsenceOfViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        // If the app is ignoring interaction events, then wait before doing our analysis
        KIFTestWaitCondition(![[UIApplication sharedApplication] isIgnoringInteractionEvents], error, @"Application is ignoring interaction events.");
        
        // If the element can't be found, then we're done
        UIAccessibilityElement *element = [[UIApplication sharedApplication] accessibilityElementWithLabel:label accessibilityValue:value traits:traits];
        if (!element) {
            return KIFTestStepResultSuccess;
        }
        
        UIView *view = [UIAccessibilityElement viewContainingAccessibilityElement:element];
        
        // If we found an element, but it's not associated with a view, then something's wrong. Wait it out and try again.
        KIFTestWaitCondition(view, error, @"Cannot find view containing accessibility element with the label \"%@\"", label);

        // Hidden views count as absent
        KIFTestWaitCondition([view isHidden] || [view superview] == nil, error, @"Accessibility element with label \"%@\" is visible and not hidden.", label);
        
        return KIFTestStepResultSuccess;
    }];
}

- (void)waitForAnimationsToFinish {
    [self waitForAnimationsToFinishWithTimeout:self.animationWaitingTimeout];
}

- (void)waitForAnimationsToFinishWithTimeout:(NSTimeInterval)timeout {
    static const CGFloat kStabilizationWait = 0.5f;
    
    NSTimeInterval maximumWaitingTimeInterval = timeout;
    if (maximumWaitingTimeInterval <= kStabilizationWait) {
        if(maximumWaitingTimeInterval >= 0) {
            [self waitForTimeInterval:maximumWaitingTimeInterval];
        }
        
        return;
    }
    
    // Wait for the view to stabilize and give them a chance to start animations before we wait for them.
    [self waitForTimeInterval:kStabilizationWait];
    maximumWaitingTimeInterval -= kStabilizationWait;
    
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    [self runBlock:^KIFTestStepResult(NSError **error) {
        __block BOOL runningAnimationFound = false;
        for (UIWindow *window in [UIApplication sharedApplication].windowsWithKeyWindow) {
            [window performBlockOnDescendentViews:^(UIView *view, BOOL *stop) {
                BOOL isViewVisible = [view isVisibleInViewHierarchy];   // do not wait for animatinos of views that aren't visible
                BOOL hasAnimation = view.layer.animationKeys.count != 0 && ![view.layer.animationKeys isEqualToArray:@[@"_UIParallaxMotionEffect"]];    // explicitly exclude _UIParallaxMotionEffect as it is used in alertviews, and we don't want every alertview to be paused
                BOOL hasUnfinishedSystemAnimation = [NSStringFromClass(view.class) isEqualToString:@"_UIParallaxDimmingView"];  // indicates that the view-hierarchy is in an in-between-state of an animation
                if (isViewVisible && (hasAnimation || hasUnfinishedSystemAnimation)) {
                    runningAnimationFound = YES;
                    if (stop != NULL) {
                        *stop = YES;
                    }
                    return;
                }
            }];
        }
        
        return runningAnimationFound && ([NSDate timeIntervalSinceReferenceDate] - startTime) < maximumWaitingTimeInterval ? KIFTestStepResultWait : KIFTestStepResultSuccess;
    } timeout:maximumWaitingTimeInterval + 1];
}

- (void)tapViewWithAccessibilityLabel:(NSString *)label
{
    [self tapViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone];
}

- (void)tapViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits
{
    [self tapViewWithAccessibilityLabel:label value:nil traits:traits];
}

- (void)tapViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits
{
    @autoreleasepool {
        UIView *view = nil;
        UIAccessibilityElement *element = nil;
        [self waitForAccessibilityElement:&element view:&view withLabel:label value:value traits:traits tappable:YES];
        [self tapAccessibilityElement:element inView:view];
    }
}

- (void)tapAccessibilityElement:(UIAccessibilityElement *)element inView:(UIView *)view
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        
        KIFTestWaitCondition(view.isUserInteractionActuallyEnabled, error, @"View is not enabled for interaction");
        
        // If the accessibilityFrame is not set, fallback to the view frame.
        CGRect elementFrame;
        if (CGRectEqualToRect(CGRectZero, element.accessibilityFrame)) {
            elementFrame.origin = CGPointZero;
            elementFrame.size = view.frame.size;
        } else {
            elementFrame = [view.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:view];
        }
        CGPoint tappablePointInElement = [view tappablePointInRect:elementFrame];
        
        // This is mostly redundant of the test in _accessibilityElementWithLabel:
        KIFTestWaitCondition(!isnan(tappablePointInElement.x), error, @"View is not tappable");
        
        if ([NSStringFromClass([view class]) isEqualToString:@"_UIAlertControllerActionView"]) {
            [view longPressAtPoint:tappablePointInElement duration:0.1];
        }
        [view tapAtPoint:tappablePointInElement];
        
        KIFTestCondition(![view canBecomeFirstResponder] || [view isDescendantOfFirstResponder], error, @"Failed to make the view into the first responder");
        
        return KIFTestStepResultSuccess;
    }];

    [self waitForAnimationsToFinish];
}

- (void)tapScreenAtPoint:(CGPoint)screenPoint
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        
        // Try all the windows until we get one back that actually has something in it at the given point
        UIView *view = nil;
        for (UIWindow *window in [[[UIApplication sharedApplication] windowsWithKeyWindow] reverseObjectEnumerator]) {
            CGPoint windowPoint = [window convertPoint:screenPoint fromView:nil];
            view = [window hitTest:windowPoint withEvent:nil];
            
            // If we hit the window itself, then skip it.
            if (view != window && view != nil) {
                break;
            }
        }
        
        KIFTestWaitCondition(view, error, @"No view was found at the point %@", NSStringFromCGPoint(screenPoint));
        
        // This is mostly redundant of the test in _accessibilityElementWithLabel:
        CGPoint viewPoint = [view convertPoint:screenPoint fromView:nil];
        [view tapAtPoint:viewPoint];
        
        return KIFTestStepResultSuccess;
    }];
}

- (void)longPressViewWithAccessibilityLabel:(NSString *)label duration:(NSTimeInterval)duration;
{
    [self longPressViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone duration:duration];
}

- (void)longPressViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value duration:(NSTimeInterval)duration;
{
    [self longPressViewWithAccessibilityLabel:label value:value traits:UIAccessibilityTraitNone duration:duration];
}

- (void)longPressViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits duration:(NSTimeInterval)duration;
{
    @autoreleasepool {
        UIView *view = nil;
        UIAccessibilityElement *element = nil;
        [self waitForAccessibilityElement:&element view:&view withLabel:label value:value traits:traits tappable:YES];
        [self longPressAccessibilityElement:element inView:view duration:duration];
    }
}

- (void)longPressAccessibilityElement:(UIAccessibilityElement *)element inView:(UIView *)view duration:(NSTimeInterval)duration;
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        
        KIFTestWaitCondition(view.isUserInteractionActuallyEnabled, error, @"View is not enabled for interaction");
        
        CGRect elementFrame = [view.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:view];
        CGPoint tappablePointInElement = [view tappablePointInRect:elementFrame];
        
        // This is mostly redundant of the test in _accessibilityElementWithLabel:
        KIFTestWaitCondition(!isnan(tappablePointInElement.x), error, @"View is not tappable");
        [view longPressAtPoint:tappablePointInElement duration:duration];
        
        KIFTestCondition(![view canBecomeFirstResponder] || [view isDescendantOfFirstResponder], error, @"Failed to make the view into the first responder");
        
        return KIFTestStepResultSuccess;
    }];
    
    // Wait for view to settle.
    [self waitForTimeInterval:0.5];
}

- (void)waitForKeyboard
{
    [self waitForSoftwareKeyboard];
}

- (void)waitForSoftwareKeyboard
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        KIFTestWaitCondition(![KIFTypist keyboardHidden], error, @"Keyboard is not visible");
        
        return KIFTestStepResultSuccess;
    }];
}

- (void)waitForAbsenceOfKeyboard
{
    [self waitForAbsenceOfSoftwareKeyboard];
}

- (void)waitForAbsenceOfSoftwareKeyboard
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        KIFTestWaitCondition([KIFTypist keyboardHidden], error, @"Keyboard is visible");
        
        return KIFTestStepResultSuccess;
    }];
}

- (void)waitForKeyInputReady
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        KIFTestWaitCondition(![KIFTypist keyboardHidden] || [KIFTypist hasHardwareKeyboard], error, @"No software or hardware keyboard.");
        KIFTestWaitCondition([KIFTypist hasKeyInputResponder], error, @"No responder for key inputs.");
        
        return KIFTestStepResultSuccess;
    }];
}

- (void)enterTextIntoCurrentFirstResponder:(NSString *)text
{
    [self waitForKeyInputReady];
    [self enterTextIntoCurrentFirstResponder:text fallbackView:nil];
}

- (void)enterTextIntoCurrentFirstResponder:(NSString *)text fallbackView:(UIView *)fallbackView
{
    for (NSUInteger characterIndex = 0; characterIndex < [text length]; characterIndex++) {
        NSString *characterString = [text substringWithRange:NSMakeRange(characterIndex, 1)];
        
        if (![KIFTypist enterCharacter:characterString]) {
            // Attempt to cheat if we couldn't find the character
            if (!fallbackView) {
                UIResponder *firstResponder = [[[UIApplication sharedApplication] keyWindow] firstResponder];
                
                if ([firstResponder isKindOfClass:[UIView class]]) {
                    fallbackView = (UIView *)firstResponder;
                }
            }
            
            if ([fallbackView isKindOfClass:[UITextField class]] || [fallbackView isKindOfClass:[UITextView class]] || [fallbackView isKindOfClass:[UISearchBar class]]) {
                NSLog(@"KIF: Unable to find keyboard key for %@. Inserting manually.", characterString);
                [(UITextField *)fallbackView setText:[[(UITextField *)fallbackView text] stringByAppendingString:characterString]];
            } else {
                [self failWithError:[NSError KIFErrorWithFormat:@"Failed to find key for character \"%@\"", characterString] stopTest:YES];
            }
        }
    }
}

- (void)enterText:(NSString *)text intoViewWithAccessibilityLabel:(NSString *)label
{
    return [self enterText:text intoViewWithAccessibilityLabel:label traits:UIAccessibilityTraitNone expectedResult:nil];
}

- (void)enterText:(NSString *)text intoViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits expectedResult:(NSString *)expectedResult
{
    UIView *view = nil;
    UIAccessibilityElement *element = nil;
    
    [self waitForAccessibilityElement:&element view:&view withLabel:label value:nil traits:traits tappable:YES];
    [self tapAccessibilityElement:element inView:view];
    [self waitForTimeInterval:0.25];
    [self enterTextIntoCurrentFirstResponder:text fallbackView:view];
    [self expectView:view toContainText:expectedResult ?: text];
}

- (void)expectView:(UIView *)view toContainText:(NSString *)expectedResult
{
    // We will perform some additional validation if the view is UITextField or UITextView.
    if (![view respondsToSelector:@selector(text)]) {
        return;
    }
    
    UITextView *textView = (UITextView *)view;
    
    // Some slower machines take longer for typing to catch up, so wait for a bit before failing
    [self runBlock:^KIFTestStepResult(NSError **error) {
        // We trim \n and \r because they trigger the return key, so they won't show up in the final product on single-line inputs.
        // Also trim \b (backspace) characters to allow for deletion.
        NSMutableCharacterSet *charExclusionSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"\b"];
        [charExclusionSet formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
        NSString *expected = [expectedResult stringByTrimmingCharactersInSet:charExclusionSet];
        NSString *actual = [textView.text stringByTrimmingCharactersInSet:charExclusionSet];
        
        KIFTestWaitCondition([actual isEqualToString:expected], error, @"Failed to get text \"%@\" in field; instead, it was \"%@\"", expected, actual);
        
        return KIFTestStepResultSuccess;
    } timeout:1.0];
}

- (void)clearTextFromFirstResponder
{
    UIView *firstResponder = (id)[[[UIApplication sharedApplication] keyWindow] firstResponder];
    if ([firstResponder isKindOfClass:[UIView class]]) {
        [self clearTextFromElement:(UIAccessibilityElement *)firstResponder inView:firstResponder];
    }
}

- (void)clearTextFromViewWithAccessibilityLabel:(NSString *)label
{
    [self clearTextFromViewWithAccessibilityLabel:label traits:UIAccessibilityTraitNone];
}

- (void)clearTextFromViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits
{
    UIView *view = nil;
    UIAccessibilityElement *element = nil;
    
    [self waitForAccessibilityElement:&element view:&view withLabel:label value:nil traits:traits tappable:YES];
	[self clearTextFromElement:element inView:view];
}

- (void)clearTextFromElement:(UIAccessibilityElement*)element inView:(UIView*)view
{
    [self tapAccessibilityElement:element inView:view];

    // Per issue #294, the tap occurs in the center of the text view.  If the text is too long, this means not all text gets cleared.  To address this for most cases, we can check if the selected view conforms to UITextInput and select the whole text range.
    if ([view conformsToProtocol:@protocol(UITextInput)]) {
        id <UITextInput> textInput = (id <UITextInput>)view;
        [textInput setSelectedTextRange:[textInput textRangeFromPosition:textInput.beginningOfDocument toPosition:textInput.endOfDocument]];
        
        [self waitForTimeInterval:0.1];
        [self enterTextIntoCurrentFirstResponder:@"\b" fallbackView:view];
    } else {
        NSUInteger numberOfCharacters = [view respondsToSelector:@selector(text)] ? [(UITextField *)view text].length : element.accessibilityValue.length;
        NSMutableString *text = [NSMutableString string];
        for (NSInteger i = 0; i < numberOfCharacters; i ++) {
            [text appendString:@"\b"];
        }
        [self enterTextIntoCurrentFirstResponder:text fallbackView:view];
    }
    
    [self expectView:view toContainText:@""];
}

- (void)clearTextFromAndThenEnterText:(NSString *)text intoViewWithAccessibilityLabel:(NSString *)label
{
    [self clearTextFromViewWithAccessibilityLabel:label];
    [self enterText:text intoViewWithAccessibilityLabel:label];
}

- (void)clearTextFromAndThenEnterText:(NSString *)text intoViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits expectedResult:(NSString *)expectedResult
{
    [self clearTextFromViewWithAccessibilityLabel:label traits:traits];
    [self enterText:text intoViewWithAccessibilityLabel:label traits:traits expectedResult:expectedResult];
}

- (void)clearTextFromAndThenEnterTextIntoCurrentFirstResponder:(NSString *)text
{
    [self clearTextFromFirstResponder];
    [self enterTextIntoCurrentFirstResponder:text];
}

- (void) selectDatePickerValue:(NSArray*)datePickerColumnValues {
    [self selectPickerValue:datePickerColumnValues pickerType:KIFUIDatePicker];
}

- (void)selectPickerViewRowWithTitle:(NSString *)title
{
    NSArray *dataToSelect = @[title];
    [self selectPickerValue:dataToSelect pickerType:KIFUIPickerView];
}

- (void)selectPickerViewRowWithTitle:(NSString *)title inComponent:(NSInteger)component
{
    NSMutableArray *dataToSelect = [[NSMutableArray alloc] init];
    
    // Assume it is datePicker and then test our hypothesis later!
    UIPickerView *pickerView = [[[[UIApplication sharedApplication] datePickerWindow] subviewsWithClassNameOrSuperClassNamePrefix:@"UIPickerView"] lastObject];
    
    // Check which type of UIPickerVIew is visible on current window.
    KIFPickerType pickerType = 0;
    if ([pickerView respondsToSelector:@selector(setDate:animated:)]) {
        pickerType = KIFUIDatePicker;
    }
    else {
        pickerType = KIFUIPickerView;
        pickerView = [[[[UIApplication sharedApplication] pickerViewWindow] subviewsWithClassNameOrSuperClassNamePrefix:@"UIPickerView"] lastObject];
    }
    
    // Add title at component index and add empty strings for other.
    // This support legacy function re-use.
    for (int i = 0; i < pickerView.numberOfComponents; i++) {
        if (component == i) {
            [dataToSelect addObject:title];
        }
        else {
            NSInteger currentIndex = [pickerView selectedRowInComponent:i];
            NSString *rowTitle = nil;
            if ([pickerView.delegate respondsToSelector:@selector(pickerView:titleForRow:forComponent:)]) {
                rowTitle = [pickerView.delegate pickerView:pickerView titleForRow:currentIndex forComponent: i];
            } else if ([pickerView.delegate respondsToSelector:@selector(pickerView:viewForRow:forComponent:reusingView:)]) {
                // This delegate inserts views directly, so try to figure out what the title is by looking for a label
                UIView *rowView = [pickerView.delegate pickerView:pickerView viewForRow:currentIndex forComponent: i reusingView:nil];
                NSArray *labels = [rowView subviewsWithClassNameOrSuperClassNamePrefix:@"UILabel"];
                UILabel *label = (labels.count > 0 ? labels[0] : nil);
                rowTitle = label.text;
            }
            
            if (rowTitle) {
                [dataToSelect addObject: rowTitle];
            } else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unknown picker type. Delegate responds neither to pickerView:titleForRow:forComponent: nor to pickerView:viewForRow:forComponent:reusingView:" userInfo:nil];
            }
        }
    }
    
    [self selectPickerValue:dataToSelect pickerType:pickerType];
}

- (void) selectPickerValue:(NSArray*)pickerColumnValues pickerType:(KIFPickerType)pickerType {
    
    [self runBlock:^KIFTestStepResult(NSError **error) {
        NSInteger columnCount = [pickerColumnValues count];
        NSMutableArray* found_values = [NSMutableArray arrayWithCapacity:columnCount];
        for (NSInteger componentIndex = 0; componentIndex < columnCount; componentIndex++) {
            [found_values addObject:[NSNumber numberWithBool:NO]];
        }
        // Find the picker view
        UIPickerView *pickerView = nil;
        switch (pickerType)
        {
            case KIFUIDatePicker:
                pickerView = [[[[UIApplication sharedApplication] datePickerWindow] subviewsWithClassNameOrSuperClassNamePrefix:@"UIPickerView"] lastObject];
                KIFTestCondition(pickerView, error, @"No picker view is present");
                break;
            case KIFUIPickerView:
                pickerView = [[[[UIApplication sharedApplication] pickerViewWindow] subviewsWithClassNameOrSuperClassNamePrefix:@"UIPickerView"] lastObject];
        }
        
        NSInteger componentCount = [pickerView.dataSource numberOfComponentsInPickerView:pickerView];
        KIFTestCondition(componentCount == columnCount, error, @"The UIDatePicker does not have the expected column count.");
        
        for (NSInteger componentIndex = 0; componentIndex < componentCount; componentIndex++) {
            NSInteger rowCount = [pickerView.dataSource pickerView:pickerView numberOfRowsInComponent:componentIndex];
            for (NSInteger rowIndex = 0; rowIndex < rowCount; rowIndex++) {
                NSString *rowTitle = nil;
                if ([pickerView.delegate respondsToSelector:@selector(pickerView:titleForRow:forComponent:)]) {
                    rowTitle = [pickerView.delegate pickerView:pickerView titleForRow:rowIndex forComponent:componentIndex];
                } else if ([pickerView.delegate respondsToSelector:@selector(pickerView:viewForRow:forComponent:reusingView:)]) {
                    
                    UIView *rowView = [pickerView.delegate pickerView:pickerView viewForRow:rowIndex forComponent:componentIndex reusingView:nil];
                    UILabel *label;
                    if ([rowView isKindOfClass:[UILabel class]] ) {
                        label = (id)rowView;
                    } else {
                        // This delegate inserts views directly, so try to figure out what the title is by looking for a label
                        NSArray *labels = [rowView subviewsWithClassNameOrSuperClassNamePrefix:@"UILabel"];
                        label = (labels.count > 0 ? labels[0] : nil);
                    }
                    rowTitle = label.text;
                }
                
                if (rowIndex==[pickerView selectedRowInComponent:componentIndex] && [rowTitle isEqual:pickerColumnValues[componentIndex]]){
                    [found_values replaceObjectAtIndex:componentIndex withObject:@(YES)];
                    break;
                }
                else if ([rowTitle isEqual:pickerColumnValues[componentIndex]]) {
                    [pickerView selectRow:rowIndex inComponent:componentIndex animated:false];
                    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);
                    
                    // Tap in the middle of the picker view to select the item
                    [pickerView tap];
                    [self waitForTimeInterval:0.5];
                    
                    // The combination of selectRow:inComponent:animated: and tap does not consistently result in
                    // pickerView:didSelectRow:inComponent: being called on the delegate. We need to do it explicitly.
                    if ([pickerView.delegate respondsToSelector:@selector(pickerView:didSelectRow:inComponent:)]) {
                        [pickerView.delegate pickerView:pickerView didSelectRow:rowIndex inComponent:componentIndex];
                    }
                    
                    [found_values replaceObjectAtIndex:componentIndex withObject:@(YES)];
                    break;
                }
            }
            if (found_values[componentIndex] == [NSNumber numberWithBool:YES]) {
                continue;
            }
        }
        
        // Support multiple column by adding flag to check if the value found in
        // at-least one column
        BOOL _foundInOneColumn = NO;
        for (NSInteger componentIndex = 0; componentIndex < columnCount; componentIndex++) {
            if (found_values[componentIndex] != [NSNumber numberWithBool:NO]) {
                _foundInOneColumn = YES;
            }
        }
        
        if (!_foundInOneColumn) {
            KIFTestCondition(NO, error, @"Failed to select from Picker.");
            return KIFTestStepResultFailure;
        }
        
        return KIFTestStepResultSuccess;
    }];
    
}

- (void)setOn:(BOOL)switchIsOn forSwitchWithAccessibilityLabel:(NSString *)label
{
    UIView *view = nil;
    UIAccessibilityElement *element = nil;
    
    [self waitForAccessibilityElement:&element view:&view withLabel:label value:nil traits:UIAccessibilityTraitButton tappable:YES];
    
    if (![view isKindOfClass:[UISwitch class]]) {
        [self failWithError:[NSError KIFErrorWithFormat:@"View with accessibility label \"%@\" is a %@, not a UISwitch", label, NSStringFromClass([view class])] stopTest:YES];
    }
    
    UISwitch *switchView = (UISwitch *)view;
    
    // No need to switch it if it's already in the correct position
    if (switchView.isOn == switchIsOn) {
        return;
    }
    
    [self tapAccessibilityElement:element inView:view];
    
    // If we succeeded, stop the test.
    if (switchView.isOn == switchIsOn) {
        return;
    }
    
    NSLog(@"Faking turning switch %@ with accessibility label %@", switchIsOn ? @"ON" : @"OFF", label);
    [switchView setOn:switchIsOn animated:YES];
    [switchView sendActionsForControlEvents:UIControlEventValueChanged];
    [self waitForTimeInterval:0.5];
    
    // We gave it our best shot.  Fail the test.
    if (switchView.isOn != switchIsOn) {
        [self failWithError:[NSError KIFErrorWithFormat:@"Failed to toggle switch to \"%@\"; instead, it was \"%@\"", switchIsOn ? @"ON" : @"OFF", switchView.on ? @"ON" : @"OFF"] stopTest:YES];
    }
}



- (void)setValue:(float)value forSliderWithAccessibilityLabel:(NSString *)label
{
    UISlider *slider = nil;
    UIAccessibilityElement *element = nil;
    [self waitForAccessibilityElement:&element view:&slider withLabel:label value:nil traits:UIAccessibilityTraitNone tappable:YES];
    
    if (![slider isKindOfClass:[UISlider class]]) {
        [self failWithError:[NSError KIFErrorWithFormat:@"View with accessibility label \"%@\" is a %@, not a UISlider", label, NSStringFromClass([slider class])] stopTest:YES];
    }
	[self setValue:value forSlider:slider];
}

- (void)setValue:(float)value forSlider:(UISlider *)slider
{
	if (value < slider.minimumValue) {
		[self failWithError:[NSError KIFErrorWithFormat:@"Cannot slide past minimum value of %f", slider.minimumValue] stopTest:YES];
	}
	
	if (value > slider.maximumValue) {
		[self failWithError:[NSError KIFErrorWithFormat:@"Cannot slide past maximum value of %f", slider.maximumValue] stopTest:YES];
	}

	CGRect trackRect = [slider trackRectForBounds:slider.bounds];
	CGPoint currentPosition = CGPointCenteredInRect([slider thumbRectForBounds:slider.bounds trackRect:trackRect value:slider.value]);
	CGPoint finalPosition = CGPointCenteredInRect([slider thumbRectForBounds:slider.bounds trackRect:trackRect value:value]);

    if (value == slider.minimumValue) {
        finalPosition.x = 0;
    } else if (value == slider.maximumValue) {
        finalPosition.x = slider.bounds.size.width;
    }

	[slider dragFromPoint:currentPosition toPoint:finalPosition steps:10];
}

- (void)dismissPopover
{
    const NSTimeInterval tapDelay = 0.05;
    UIWindow *window = [[UIApplication sharedApplication] dimmingViewWindow];
    if (!window) {
        [self failWithError:[NSError KIFErrorWithFormat:@"Failed to find any dimming views in the application"] stopTest:YES];
    }
    UIView *dimmingView = [[window subviewsWithClassNamePrefix:@"UIDimmingView"] lastObject];
    [dimmingView tapAtPoint:CGPointMake(50.0f, 50.0f)];
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, tapDelay, false);
}

- (void)choosePhotoInAlbum:(NSString *)albumName atRow:(NSInteger)row column:(NSInteger)column
{
    // This is basically the same as the step to tap with an accessibility label except that the accessibility labels for the albums have the number of photos appended to the end, such as "My Photos (3)." This means that we have to do a prefix match rather than an exact match.
    [self runBlock:^KIFTestStepResult(NSError **error) {
        
        NSString *labelPrefix = [NSString stringWithFormat:@"%@", albumName];
        UIAccessibilityElement *element = [[UIApplication sharedApplication] accessibilityElementMatchingBlock:^(UIAccessibilityElement *element) {
            return [element.accessibilityLabel hasPrefix:labelPrefix];
        }];
        
        KIFTestWaitCondition(element, error, @"Failed to find photo album with name %@", albumName);
        
        UIView *view = [UIAccessibilityElement viewContainingAccessibilityElement:element];
        KIFTestWaitCondition(view, error, @"Failed to find view for photo album with name %@", albumName);
        
        if (![view isUserInteractionActuallyEnabled]) {
            if (error) {
                *error = [NSError KIFErrorWithFormat:@"Album picker is not enabled for interaction"];
            }
            return KIFTestStepResultWait;
        }
        
        CGRect elementFrame = [view.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:view];
        CGPoint tappablePointInElement = [view tappablePointInRect:elementFrame];
        
        [view tapAtPoint:tappablePointInElement];
        
        return KIFTestStepResultSuccess;
    }];
    
    // Wait for media picker view controller to be pushed.
    [self waitForTimeInterval:1];
    
    // Tap the desired photo in the grid
    // TODO: This currently only works for the first page of photos. It should scroll appropriately at some point.
    const CGFloat headerHeight = 64.0;
    const CGSize thumbnailSize = CGSizeMake(75.0, 75.0);
    const CGFloat thumbnailMargin = 5.0;
    CGPoint thumbnailCenter;
    thumbnailCenter.x = thumbnailMargin + (MAX(0, column - 1) * (thumbnailSize.width + thumbnailMargin)) + thumbnailSize.width / 2.0;
    thumbnailCenter.y = headerHeight + thumbnailMargin + (MAX(0, row - 1) * (thumbnailSize.height + thumbnailMargin)) + thumbnailSize.height / 2.0;
    [self tapScreenAtPoint:thumbnailCenter];
}

- (void)tapRowAtIndexPath:(NSIndexPath *)indexPath inTableViewWithAccessibilityIdentifier:(NSString *)identifier
{
    UITableView *tableView;
    [self waitForAccessibilityElement:NULL view:&tableView withIdentifier:identifier tappable:NO];
    [self tapRowAtIndexPath:indexPath inTableView:tableView];
}

- (void)tapRowInTableViewWithAccessibilityLabel:(NSString*)tableViewLabel atIndexPath:(NSIndexPath *)indexPath
{
    UITableView *tableView = (UITableView *)[self waitForViewWithAccessibilityLabel:tableViewLabel];
    [self tapRowAtIndexPath:indexPath inTableView:tableView];
}

- (void)tapRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [self waitForCellAtIndexPath:indexPath inTableView:tableView];
    CGRect cellFrame = [cell.contentView convertRect:cell.contentView.frame toView:tableView];
    [tableView tapAtPoint:CGPointCenteredInRect(cellFrame)];
    
    [self waitForAnimationsToFinish];
}

- (void)swipeRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView inDirection:(KIFSwipeDirection)direction
{
    const NSUInteger kNumberOfPointsInSwipePath = 20;
    
    UITableViewCell *cell = [self waitForCellAtIndexPath:indexPath inTableView:tableView];
    CGRect cellFrame = [cell.contentView convertRect:cell.contentView.frame toView:tableView];
    CGPoint swipeStart = CGPointCenteredInRect(cellFrame);
    KIFDisplacement swipeDisplacement = KIFDisplacementForSwipingInDirection(direction);
    [tableView dragFromPoint:swipeStart displacement:swipeDisplacement steps:kNumberOfPointsInSwipePath];
    
    // Wait for the view to stabilize.
    [tester waitForTimeInterval:0.5];
    
}

- (void)tapItemAtIndexPath:(NSIndexPath *)indexPath inCollectionViewWithAccessibilityIdentifier:(NSString *)identifier
{
    UICollectionView *collectionView;
    [self waitForAccessibilityElement:NULL view:&collectionView withIdentifier:identifier tappable:NO];
    [self tapItemAtIndexPath:indexPath inCollectionView:collectionView];
}

- (BOOL)acknowledgeSystemAlert {
    return [UIAutomationHelper acknowledgeSystemAlert];
}

- (void)tapItemAtIndexPath:(NSIndexPath *)indexPath inCollectionView:(UICollectionView *)collectionView
{
    UICollectionViewCell *cell;
    cell = [self waitForCellAtIndexPath:indexPath inCollectionView:collectionView];
    
    CGRect cellFrame = [cell.contentView convertRect:cell.contentView.frame toView:collectionView];
    [collectionView tapAtPoint:CGPointCenteredInRect(cellFrame)];
    
    [self waitForAnimationsToFinish];
}

- (void)swipeViewWithAccessibilityLabel:(NSString *)label inDirection:(KIFSwipeDirection)direction
{
    [self swipeViewWithAccessibilityLabel:label value:nil traits:UIAccessibilityTraitNone inDirection:direction];
}

- (void)swipeViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value inDirection:(KIFSwipeDirection)direction
{
    [self swipeViewWithAccessibilityLabel:label value:value traits:UIAccessibilityTraitNone inDirection:direction];
}

- (void)swipeViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits inDirection:(KIFSwipeDirection)direction
{
    UIView *viewToSwipe = nil;
    UIAccessibilityElement *element = nil;

    [self waitForAccessibilityElement:&element view:&viewToSwipe withLabel:label value:value traits:traits tappable:YES];

    [self swipeAccessibilityElement:element inView:viewToSwipe inDirection:direction];
}

- (void)swipeAccessibilityElement:(UIAccessibilityElement *)element inView:(UIView *)viewToSwipe inDirection:(KIFSwipeDirection)direction
{
    // The original version of this came from http://groups.google.com/group/kif-framework/browse_thread/thread/df3f47eff9f5ac8c
  
    const NSUInteger kNumberOfPointsInSwipePath = 20;
  
    // Within this method, all geometry is done in the coordinate system of the view to swipe.
  
    CGRect elementFrame = [viewToSwipe.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:viewToSwipe];
    CGPoint swipeStart = CGPointCenteredInRect(elementFrame);
    KIFDisplacement swipeDisplacement = KIFDisplacementForSwipingInDirection(direction);
  
    [viewToSwipe dragFromPoint:swipeStart displacement:swipeDisplacement steps:kNumberOfPointsInSwipePath];
}

- (void)scrollViewWithAccessibilityLabel:(NSString *)label byFractionOfSizeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction
{
    UIView *viewToScroll;
    UIAccessibilityElement *element;
    [self waitForAccessibilityElement:&element view:&viewToScroll withLabel:label value:nil traits:UIAccessibilityTraitNone tappable:NO];
    [self scrollAccessibilityElement:element inView:viewToScroll byFractionOfSizeHorizontal:horizontalFraction vertical:verticalFraction];
}

- (void)scrollViewWithAccessibilityIdentifier:(NSString *)identifier byFractionOfSizeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction
{
    UIView *viewToScroll;
    UIAccessibilityElement *element;
    [self waitForAccessibilityElement:&element view:&viewToScroll withIdentifier:identifier tappable:NO];
    [self scrollAccessibilityElement:element inView:viewToScroll byFractionOfSizeHorizontal:horizontalFraction vertical:verticalFraction];
}

- (void)scrollAccessibilityElement:(UIAccessibilityElement *)element inView:(UIView *)viewToScroll byFractionOfSizeHorizontal:(CGFloat)horizontalFraction vertical:(CGFloat)verticalFraction
{
    const NSUInteger kNumberOfPointsInScrollPath = 5;
    
    // Within this method, all geometry is done in the coordinate system of the view to scroll.
    
    CGRect elementFrame = [viewToScroll.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:viewToScroll];
    
    KIFDisplacement scrollDisplacement = CGPointMake(elementFrame.size.width * horizontalFraction, elementFrame.size.height * verticalFraction);
    
    CGPoint scrollStart = CGPointCenteredInRect(elementFrame);
    scrollStart.x -= scrollDisplacement.x / 2;
    scrollStart.y -= scrollDisplacement.y / 2;
    
    [viewToScroll dragFromPoint:scrollStart displacement:scrollDisplacement steps:kNumberOfPointsInScrollPath];
}

- (void)waitForFirstResponderWithAccessibilityLabel:(NSString *)label
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        UIResponder *firstResponder = [[[UIApplication sharedApplication] keyWindow] firstResponder];
        if ([firstResponder isKindOfClass:NSClassFromString(@"UISearchBarTextField")]) {
            do {
                firstResponder = [(UIView *)firstResponder superview];
            } while (firstResponder && ![firstResponder isKindOfClass:[UISearchBar class]]);
        }
        KIFTestWaitCondition([[firstResponder accessibilityLabel] isEqualToString:label], error, @"Expected accessibility label for first responder to be '%@', got '%@'", label, [firstResponder accessibilityLabel]);
        
        return KIFTestStepResultSuccess;
    }];
}

- (void)waitForFirstResponderWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        UIResponder *firstResponder = [[[UIApplication sharedApplication] keyWindow] firstResponder];
        
        NSString *foundLabel = firstResponder.accessibilityLabel;
        
        // foundLabel == label checks for the case where both are nil.
        KIFTestWaitCondition(foundLabel == label || [foundLabel isEqualToString:label], error, @"Expected accessibility label for first responder to be '%@', got '%@'", label, foundLabel);
        KIFTestWaitCondition(firstResponder.accessibilityTraits & traits, error, @"Found first responder with accessibility label, but not traits.");
        
        return KIFTestStepResultSuccess;
    }];
}

- (UITableViewCell *)waitForCellAtIndexPath:(NSIndexPath *)indexPath inTableViewWithAccessibilityIdentifier:(NSString *)identifier
{
    UITableView *tableView;
    [self waitForAccessibilityElement:NULL view:&tableView withIdentifier:identifier tappable:NO];
    return [self waitForCellAtIndexPath:indexPath inTableView:tableView];
}

- (UITableViewCell *)waitForCellAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView
{
    if (![tableView isKindOfClass:[UITableView class]]) {
        [self failWithError:[NSError KIFErrorWithFormat:@"View is not a table view"] stopTest:YES];
    }

    // If section < 0, search from the end of the table.
    if (indexPath.section < 0) {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:tableView.numberOfSections + indexPath.section];
    }

    // If row < 0, search from the end of the section.
    if (indexPath.row < 0) {
        indexPath = [NSIndexPath indexPathForRow:[tableView numberOfRowsInSection:indexPath.section] + indexPath.row inSection:indexPath.section];
    }

    [self runBlock:^KIFTestStepResult(NSError **error) {

        KIFTestWaitCondition(indexPath.section < tableView.numberOfSections, error, @"Section %ld is not found in table view", (long)indexPath.section);

        KIFTestWaitCondition(indexPath.row < [tableView numberOfRowsInSection:indexPath.section], error, @"Row %ld is not found in section %ld of table view", (long)indexPath.row, (long)indexPath.section);

        return KIFTestStepResultSuccess;
    }];

    __block UITableViewCell *cell = nil;
    __block CGFloat lastYOffset = CGFLOAT_MAX;
    [self runBlock:^KIFTestStepResult(NSError **error) {
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        cell = [tableView cellForRowAtIndexPath:indexPath];
        KIFTestWaitCondition(!!cell, error, @"Table view cell at index path %@ not found", indexPath);
        
        if (lastYOffset != tableView.contentOffset.y) {
            lastYOffset = tableView.contentOffset.y;
            KIFTestWaitCondition(NO, error, @"Didn't finish scrolling to cell.");
        }
        
        return KIFTestStepResultSuccess;
    }];
    
    [self waitForTimeInterval:0.1]; // Let things settle.
    

    return cell;
}

- (UICollectionViewCell *)waitForCellAtIndexPath:(NSIndexPath *)indexPath inCollectionViewWithAccessibilityIdentifier:(NSString *)identifier
{
    UICollectionView *collectionView;
    [self waitForAccessibilityElement:NULL view:&collectionView withIdentifier:identifier tappable:NO];
    return [self waitForCellAtIndexPath:indexPath inCollectionView:collectionView];
}

- (UICollectionViewCell *)waitForCellAtIndexPath:(NSIndexPath *)indexPath inCollectionView:(UICollectionView *)collectionView
{
    if (![collectionView isKindOfClass:[UICollectionView class]]) {
        [self failWithError:[NSError KIFErrorWithFormat:@"View is not a collection view"] stopTest:YES];
    }
    
    NSInteger section = indexPath.section;
    NSInteger item    = indexPath.item;
    
    // If section < 0, search from the end of the table.
    if (section < 0) {
        section += collectionView.numberOfSections;
    }
    
    // If item < 0, search from the end of the section.
    if (item < 0) {
        item += [collectionView numberOfItemsInSection:section];
    }

    indexPath = [NSIndexPath indexPathForItem:item inSection:section];

    [self runBlock:^KIFTestStepResult(NSError **error) {

        KIFTestWaitCondition(indexPath.section < collectionView.numberOfSections, error, @"Section %ld is not found in collection view", (long)indexPath.section);

        KIFTestWaitCondition(indexPath.row < [collectionView numberOfItemsInSection:indexPath.section], error, @"Item %ld is not found in section %ld of collection view", (long)indexPath.row, (long)indexPath.section);

        return KIFTestStepResultSuccess;
    }];

    [collectionView scrollToItemAtIndexPath:indexPath
                           atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally | UICollectionViewScrollPositionCenteredVertically
                                   animated:YES];

    [self waitForAnimationsToFinish];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];

    //For big collection views with many cells the cell might not be ready yet. Relayout and try again.
    if(cell == nil) {
        [collectionView layoutIfNeeded];
        [collectionView scrollToItemAtIndexPath:indexPath
                               atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally | UICollectionViewScrollPositionCenteredVertically
                                       animated:YES];
        [self waitForAnimationsToFinish];
        cell = [collectionView cellForItemAtIndexPath:indexPath];
    }
    
    if (!cell) {
        [self failWithError:[NSError KIFErrorWithFormat: @"Collection view cell at index path %@ not found", indexPath] stopTest:YES];
    }

    return cell;
}

- (void)tapStatusBar
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        KIFTestWaitCondition(![UIApplication sharedApplication].statusBarHidden, error, @"Expected status bar to be visible.");
        return KIFTestStepResultSuccess;
    }];
    
    UIWindow *statusBarWindow = [[UIApplication sharedApplication] statusBarWindow];
    NSArray *statusBars = [statusBarWindow subviewsWithClassNameOrSuperClassNamePrefix:@"UIStatusBar"];
    
    if (statusBars.count == 0) {
        [self failWithError:[NSError KIFErrorWithFormat: @"Could not find the status bar"] stopTest:YES];
    }
    
    [self tapAccessibilityElement:statusBars[0] inView:statusBars[0]];
}

- (void)moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath inTableViewWithAccessibilityIdentifier:(NSString *)identifier
{
    UITableView *tableView;
    [self waitForAccessibilityElement:NULL view:&tableView withIdentifier:identifier tappable:NO];
    
    UITableViewCell *cell = [self waitForCellAtIndexPath:sourceIndexPath inTableView:tableView];
    
    NSError *error = nil;
    if (![tableView dragCell:cell toIndexPath:destinationIndexPath error:&error]) {
        [self failWithError:error stopTest:YES];
    }
}

- (void)deactivateAppForDuration:(NSTimeInterval)duration {
    [UIAutomationHelper deactivateAppForDuration:@(duration)];
}

-(void) tapStepperWithAccessibilityLabel: (NSString *)accessibilityLabel increment: (KIFStepperDirection) stepperDirection
{
	@autoreleasepool {
		UIView *view = nil;
		UIAccessibilityElement *element = nil;
		[self waitForAccessibilityElement:&element view:&view withLabel:accessibilityLabel value:nil traits:UIAccessibilityTraitNone tappable:YES];
		[self tapStepperWithAccessibilityElement:element increment:stepperDirection inView:view];
	}
}

//inspired by http://www.raywenderlich.com/61419/ios-ui-testing-with-kif
- (void)tapStepperWithAccessibilityElement:(UIAccessibilityElement *)element increment: (KIFStepperDirection) stepperDirection inView:(UIView *)view
{
	[self runBlock:^KIFTestStepResult(NSError **error) {

		KIFTestWaitCondition(view.isUserInteractionActuallyEnabled, error, @"View is not enabled for interaction");

		// If the accessibilityFrame is not set, fallback to the view frame.
		CGRect elementFrame;
		if (CGRectEqualToRect(CGRectZero, element.accessibilityFrame)) {
			elementFrame.origin = CGPointZero;
			elementFrame.size = view.frame.size;
		} else {
			elementFrame = [view.windowOrIdentityWindow convertRect:element.accessibilityFrame toView:view];
		}

		CGPoint stepperPointToTap = [view tappablePointInRect:elementFrame];

		switch (stepperDirection)
		{
			case KIFStepperDirectionIncrement:
				stepperPointToTap.x += CGRectGetWidth(view.frame) / 4;
				break;
			case KIFStepperDirectionDecrement:
				stepperPointToTap.x -= CGRectGetWidth(view.frame) / 4;
				break;
		}

		// This is mostly redundant of the test in _accessibilityElementWithLabel:
		KIFTestWaitCondition(!isnan(stepperPointToTap.x), error, @"View is not tappable");
		[view tapAtPoint:stepperPointToTap];

		KIFTestCondition(![view canBecomeFirstResponder] || [view isDescendantOfFirstResponder], error, @"Failed to make the view into the first responder");

		return KIFTestStepResultSuccess;
	}];

	[self waitForAnimationsToFinish];
}
@end

