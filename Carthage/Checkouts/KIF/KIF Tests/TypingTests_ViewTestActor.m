//
//  ViewTypingTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//

#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"

@interface TypingTests_ViewTestActor : KIFTestCase
@end


@implementation TypingTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Tapping"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testWaitingForFirstResponder
{
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Hello"] tap];
    [[viewTester usingLabel:@"Greeting"] waitToBecomeFirstResponder];
}

- (void)testMissingFirstResponder
{
    KIFExpectFailure([[[viewTester usingTimeout:1] usingLabel:@"Greeting"] waitToBecomeFirstResponder]);
}

- (void)testEnteringTextIntoFirstResponder
{
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Hello"] longPressWithDuration:2];
    [[viewTester usingLabel:@"Select All"] tap];
    [viewTester enterTextIntoCurrentFirstResponder:@"Yo"];
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Yo"] waitForView];
}

- (void)testFailingToEnterTextIntoFirstResponder
{
    KIFExpectFailure([[viewTester usingTimeout:1] enterTextIntoCurrentFirstResponder:@"Yo"]);
}

- (void)testEnteringTextIntoViewWithAccessibilityLabel
{
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Hello"] longPressWithDuration:2];
    [[viewTester usingLabel:@"Select All"] tap];
    [[viewTester usingLabel:@"Cut"] tap];
    [[viewTester usingLabel:@"Greeting"] enterText:@"Yo"];
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Yo"] waitForView];
}

- (void)testEnteringTextIntoViewWithAccessibilityLabelExpectingResults
{
    [[viewTester usingLabel:@"Greeting"] enterText:@", world" expectedResult:@"Hello, world"];
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Hello, world"] waitForView];
}

- (void)testClearingAndEnteringTextIntoViewWithAccessibilityLabel
{
    [[viewTester usingLabel:@"Greeting"] clearAndEnterText:@"Yo"];
}

- (void)testEnteringReturnCharacterIntoViewWithAccessibilityLabel
{
    [[viewTester usingLabel:@"Other Text"] enterText:@"Hello\n"];
    [[viewTester usingLabel:@"Greeting"] waitToBecomeFirstResponder];
    [[viewTester usingLabel:@"Greeting"] waitForView];
    [[viewTester usingLabel:@"Greeting"] enterText:@", world\n" expectedResult:@"Hello, world"];
}

- (void)testSettingTextIntoViewWithAccessibilityLabel
{
    [[viewTester usingLabel:@"Greeting"] setText:@"Yo"];
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Yo"] waitForView];
}

- (void)testClearingALongTextField
{
    [[viewTester usingLabel:@"Greeting"] clearAndEnterText:@"A man, a plan, a canal, Panama.  Able was I, ere I saw Elba."];
    [[viewTester usingLabel:@"Greeting"] clearText];
}

- (void)testThatClearingTextHitsTheDelegate
{
    [[viewTester usingLabel:@"Other Text"] enterText:@"hello"];
    [[viewTester usingLabel:@"Other Text"] clearText];
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Deleted something."] waitForView];
}

- (void)testThatBackspaceDeletesOneCharacter
{
    [[viewTester usingLabel:@"Other Text"] enterText:@"hi\bello" expectedResult:@"hello"];
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Deleted something."] waitForView];
}

@end
