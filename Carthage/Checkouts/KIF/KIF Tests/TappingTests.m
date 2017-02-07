//
//  TappingTests.m
//  Test Suite
//
//  Created by Brian Nickel on 6/28/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>
#import <KIF/KIFUITestActor-IdentifierTests.h>

@interface TappingTests : KIFTestCase
@end

@implementation TappingTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Tapping"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testTappingViewFromSpecificView
{
    UIView *scrollView = [tester waitForViewWithAccessibilityIdentifier:@"TapViewController Inner ScrollView"];
    UIView *buttonView;
    UIAccessibilityElement *element;
    [tester waitForAccessibilityElement:&element view:&buttonView withIdentifier:@"Inner Button" fromRootView:scrollView tappable:YES];
    
    if (buttonView != NULL) {
        [tester tapAccessibilityElement:element inView:buttonView];
    }
}

- (void)testTappingViewWithAccessibilityLabel
{
    // Since the tap has occurred in setup, we just need to wait for the result.
    [tester waitForViewWithAccessibilityLabel:@"TapView"];
}

- (void)testTappingViewWithTraits
{
    [tester tapViewWithAccessibilityLabel:@"X" traits:UIAccessibilityTraitButton];
    [tester waitForViewWithAccessibilityLabel:@"X" traits:UIAccessibilityTraitButton | UIAccessibilityTraitSelected];
}

- (void)testTappingViewWithValue
{
    [tester tapViewWithAccessibilityLabel:@"Greeting" value:@"Hello" traits:UIAccessibilityTraitNone];
    [tester waitForFirstResponderWithAccessibilityLabel:@"Greeting"];
}

- (void)testTappingViewWithScreenAtPoint
{
    [tester waitForTimeInterval:0.75];
    [tester tapScreenAtPoint:CGPointMake(15, 200)];
    [tester waitForViewWithAccessibilityLabel:@"X" traits:UIAccessibilityTraitSelected];
}

- (void)testTappingViewPartiallyOffscreenAndWithinScrollView
{
    [tester tapViewWithAccessibilityLabel:@"Slightly Offscreen Button"];
}

- (void)testTappingViewWithTapGestureRecognizer
{
    [tester tapViewWithAccessibilityLabel:@"Label with Tap Gesture Recognizer"];
}

- (void)testTappingLabelWithLineBreaks
{
    [tester tapViewWithAccessibilityLabel:@"Label with\nLine Break\n\n"];
    [tester tapViewWithAccessibilityLabel:@"A\nB\nC\n\n"];
}

- (void) testTappingStepperIncrement
{
	UILabel *uiLabel = (UILabel *)[tester waitForViewWithAccessibilityLabel: @"stepperValue"];
	NSInteger originalValue = [[uiLabel text] integerValue];

	[tester tapStepperWithAccessibilityLabel:@"theStepper" increment:(KIFStepperDirectionIncrement)];

	[tester waitForTimeInterval:0.5f];
	uiLabel = (UILabel *)[tester waitForViewWithAccessibilityLabel: @"stepperValue"];
	NSInteger newValue = [[uiLabel text] integerValue];
	if (newValue != (originalValue + 1))
	{
		NSException *exception = [NSException exceptionWithName:@"Unexpected test failure"
														 reason:[NSString stringWithFormat: @"newValue was expected to be +1 of originalValue. Original Value was %ld while newValue is %ld", (long)originalValue, (long)newValue] userInfo:nil];
		[tester failWithException: exception stopTest: NO];
	}
}

- (void) testTappingStepperDecrement
{
	UILabel *uiLabel = (UILabel *)[tester waitForViewWithAccessibilityLabel: @"stepperValue"];
	NSInteger originalValue = [[uiLabel text] integerValue];

	[tester tapStepperWithAccessibilityLabel:@"theStepper" increment:(KIFStepperDirectionDecrement)];

	[tester waitForTimeInterval:0.5f];
	uiLabel = (UILabel *)[tester waitForViewWithAccessibilityLabel: @"stepperValue"];
	NSInteger newValue = [[uiLabel text] integerValue];
	if (newValue != (originalValue - 1))
	{
		NSException *exception = [NSException exceptionWithName:@"Unexpected test failure"
														 reason:[NSString stringWithFormat: @"newValue was expected to be -1 of originalValue. Original Value was %ld while newValue is %ld", (long)originalValue, (long)newValue] userInfo:nil];
		[tester failWithException: exception stopTest: NO];
	}
}

@end
