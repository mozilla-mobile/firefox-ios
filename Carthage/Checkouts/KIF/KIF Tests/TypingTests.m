//
//  TypingTests.m
//  Test Suite
//
//  Created by Brian Nickel on 6/28/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"

@interface TypingTests : KIFTestCase
@end

@implementation TypingTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Tapping"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testWaitingForFirstResponder
{
    [tester tapViewWithAccessibilityLabel:@"Greeting" value:@"Hello" traits:UIAccessibilityTraitNone];
    [tester waitForFirstResponderWithAccessibilityLabel:@"Greeting"];
}

- (void)testMissingFirstResponder
{
    KIFExpectFailure([[tester usingTimeout:1] waitForFirstResponderWithAccessibilityLabel:@"Greeting"]);
}

- (void)testEnteringTextIntoFirstResponder
{
    [tester longPressViewWithAccessibilityLabel:@"Greeting" value:@"Hello" duration:2];
    [tester tapViewWithAccessibilityLabel:@"Select All"];
    [tester enterTextIntoCurrentFirstResponder:@"Yo"];
    [tester waitForViewWithAccessibilityLabel:@"Greeting" value:@"Yo" traits:UIAccessibilityTraitNone];
}

- (void)testFailingToEnterTextIntoFirstResponder
{
    KIFExpectFailure([[tester usingTimeout:1] enterTextIntoCurrentFirstResponder:@"Yo"]);
}

- (void)testEnteringTextIntoViewWithAccessibilityLabel
{
    [tester longPressViewWithAccessibilityLabel:@"Greeting" value:@"Hello" duration:2];
    [tester tapViewWithAccessibilityLabel:@"Select All"];
    [tester tapViewWithAccessibilityLabel:@"Cut"];
    [tester enterText:@"Yo" intoViewWithAccessibilityLabel:@"Greeting"];
    [tester waitForViewWithAccessibilityLabel:@"Greeting" value:@"Yo" traits:UIAccessibilityTraitNone];
}

- (void)testEnteringTextIntoViewWithAccessibilityLabelExpectingResults
{
    [tester enterText:@", world" intoViewWithAccessibilityLabel:@"Greeting" traits:UIAccessibilityTraitNone expectedResult:@"Hello, world"];
    [tester waitForViewWithAccessibilityLabel:@"Greeting" value:@"Hello, world" traits:UIAccessibilityTraitNone];
}

- (void)testClearingAndEnteringTextIntoViewWithAccessibilityLabel
{
    [tester clearTextFromAndThenEnterText:@"Yo" intoViewWithAccessibilityLabel:@"Greeting"];
}

- (void)testEnteringReturnCharacterIntoViewWithAccessibilityLabel
{
    [tester enterText:@"Hello\n" intoViewWithAccessibilityLabel:@"Other Text"];
    [tester waitForFirstResponderWithAccessibilityLabel:@"Greeting"];
    [tester enterText:@", world\n" intoViewWithAccessibilityLabel:@"Greeting" traits:UIAccessibilityTraitNone expectedResult:@"Hello, world"];
}

- (void)testClearingALongTextField
{
    [tester clearTextFromAndThenEnterText:@"A man, a plan, a canal, Panama.  Able was I, ere I saw Elba." intoViewWithAccessibilityLabel:@"Greeting"];
    [tester clearTextFromViewWithAccessibilityLabel:@"Greeting"];
}

- (void)testThatClearingTextHitsTheDelegate
{
    [tester enterText:@"hello" intoViewWithAccessibilityLabel:@"Other Text"];
    [tester clearTextFromViewWithAccessibilityLabel:@"Other Text"];
    [tester waitForViewWithAccessibilityLabel:@"Greeting" value:@"Deleted something." traits:UIAccessibilityTraitNone];
}

- (void)testThatBackspaceDeletesOneCharacter
{
    [tester enterText:@"hi\bello" intoViewWithAccessibilityLabel:@"Other Text" traits:UIAccessibilityTraitNone expectedResult:@"hello"];
    [tester waitForViewWithAccessibilityLabel:@"Greeting" value:@"Deleted something." traits:UIAccessibilityTraitNone];
}

@end
