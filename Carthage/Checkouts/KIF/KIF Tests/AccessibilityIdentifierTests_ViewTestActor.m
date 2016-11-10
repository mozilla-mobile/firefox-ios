//
//  NewAccessibilityIdentifierTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//

#import <KIF/KIF.h>
#import <KIF/KIFTestStepValidation.h>

@interface AccessibilityIdentifierTests_ViewTestActor : KIFTestCase
@end


@implementation AccessibilityIdentifierTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Tapping"] tap];
}

- (void)testWaitingForViewWithAccessibilityIdentifier
{
    // Since the tap has occurred in setup, we just need to wait for the result.
    [[viewTester usingIdentifier:@"X_BUTTON"] waitForView];
    KIFExpectFailure([[[viewTester usingTimeout:0.5] usingIdentifier:@"NOT_X_BUTTON"] waitForView]);
}

- (void)testTappingViewWithAccessibilityIdentifier
{
    [[viewTester usingIdentifier:@"X_BUTTON"] tap];
    [[[viewTester usingLabel:@"X"] usingTraits:UIAccessibilityTraitButton | UIAccessibilityTraitSelected] waitForView];
    KIFExpectFailure([[[viewTester usingTimeout:0.5] usingIdentifier:@"NOT_X_BUTTON"] tap]);
}

- (void)testWaitingForAbscenceOfViewWithAccessibilityIdentifier
{
    // Since the tap has occurred in setup, we just need to wait for the result.
    [[viewTester usingIdentifier:@"X_BUTTON"] waitForView];
    [[viewTester usingIdentifier:@"NOT_X_BUTTON"] waitForAbsenceOfView];
    KIFExpectFailure([[[viewTester usingTimeout:0.5] usingIdentifier:@"X_BUTTON"] waitForAbsenceOfView]);
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
    [[viewTester usingIdentifier:@"X_BUTTON"] waitForAbsenceOfView];
    [[viewTester usingLabel:@"Tapping"] tap];
}

- (void)testLongPressingViewWithAccessibilityIdentifier
{
    [[viewTester usingIdentifier:@"idGreeting"] longPressWithDuration:2];
    [[viewTester usingLabel:@"Select All"] tap];
}

- (void)testEnteringTextIntoViewWithAccessibilityIdentifier
{
    [[viewTester usingIdentifier:@"idGreeting"] longPressWithDuration:2];
    [[viewTester usingLabel:@"Select All"] tap];
    [[viewTester usingLabel:@"Cut"] tap];
    [[viewTester usingIdentifier:@"idGreeting"] enterText:@"Yo"];
}

- (void)testEnteringTextIntoViewWithAccessibilityIdentifierExpectingResults
{
    [[viewTester usingIdentifier:@"idGreeting"] enterText:@", world" expectedResult:@"Hello, world"];
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Hello, world"] waitForView];
}

- (void)testClearingAndEnteringTextIntoViewWithAccessibilityLabel
{
    [[viewTester usingIdentifier:@"idGreeting"] clearAndEnterText:@"Yo"];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

@end
