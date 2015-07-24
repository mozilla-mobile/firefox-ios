//
//  AccessibilityIdentifierTests.m
//  KIF
//
//  Created by Brian Nickel on 11/6/14.
//
//

#import <KIF/KIFTestCase.h>
#import <KIF/KIFUITestActor-IdentifierTests.h>
#import <KIF/KIFTestStepValidation.h>

@interface AccessibilityIdentifierTests : KIFTestCase
@end

@implementation AccessibilityIdentifierTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Tapping"];
}

- (void)testWaitingForViewWithAccessibilityIdentifier
{
    // Since the tap has occurred in setup, we just need to wait for the result.
    [tester waitForViewWithAccessibilityIdentifier:@"X_BUTTON"];
    KIFExpectFailure([[tester usingTimeout:0.5] waitForViewWithAccessibilityIdentifier:@"NOT_X_BUTTON"]);
}

- (void)testTappingViewWithAccessibilityIdentifier
{
    [tester tapViewWithAccessibilityIdentifier:@"X_BUTTON"];
    [tester waitForViewWithAccessibilityLabel:@"X" traits:UIAccessibilityTraitButton | UIAccessibilityTraitSelected];
    KIFExpectFailure([[tester usingTimeout:0.5] tapViewWithAccessibilityIdentifier:@"NOT_X_BUTTON"]);
}

- (void)testWaitingForAbscenceOfViewWithAccessibilityIdentifier
{
    // Since the tap has occurred in setup, we just need to wait for the result.
    [tester waitForViewWithAccessibilityIdentifier:@"X_BUTTON"];
    [tester waitForAbsenceOfViewWithAccessibilityIdentifier:@"NOT_X_BUTTON"];
    KIFExpectFailure([[tester usingTimeout:0.5] waitForAbsenceOfViewWithAccessibilityIdentifier:@"X_BUTTON"]);
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
    [tester waitForAbsenceOfViewWithAccessibilityIdentifier:@"X_BUTTON"];
    [tester tapViewWithAccessibilityLabel:@"Tapping"];
}

- (void)testLongPressingViewWithAccessibilityIdentifier
{
	[tester longPressViewWithAccessibilityIdentifier:@"idGreeting" duration:2];
	[tester tapViewWithAccessibilityLabel:@"Select All"];
}

- (void)testEnteringTextIntoViewWithAccessibilityIdentifier
{
	[tester longPressViewWithAccessibilityIdentifier:@"idGreeting" duration:2];
	[tester tapViewWithAccessibilityLabel:@"Select All"];
	[tester tapViewWithAccessibilityLabel:@"Cut"];
	[tester enterText:@"Yo" intoViewWithAccessibilityIdentifier:@"idGreeting"];
}

- (void)testEnteringTextIntoViewWithAccessibilityIdentifierExpectingResults
{
	[tester enterText:@", world" intoViewWithAccessibilityIdentifier:@"idGreeting" expectedResult:@"Hello, world"];
	[tester waitForViewWithAccessibilityLabel:@"Greeting" value:@"Hello, world" traits:UIAccessibilityTraitNone];
}

- (void)testClearingAndEnteringTextIntoViewWithAccessibilityLabel
{
	[tester clearTextFromAndThenEnterText:@"Yo" intoViewWithAccessibilityIdentifier:@"idGreeting"];
}

- (void)testTryFindingViewWithAccessibilityIdentifier
{
    if (![tester tryFindingViewWithAccessibilityIdentifier:@"idGreeting"])
    {
        [tester fail];
    }

    if ([tester tryFindingViewWithAccessibilityIdentifier:@"idDoesNotExist"])
    {
        [tester fail];
    }
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

@end
