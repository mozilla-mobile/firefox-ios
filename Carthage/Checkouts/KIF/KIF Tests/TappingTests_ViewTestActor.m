//
//  ViewTappingTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//


#import <KIF/KIF.h>

@implementation KIFUIViewTestActor (tappingtests)

- (KIFUIViewTestActor *)xButton;
{
    return [[self usingLabel:@"X"] usingTraits:UIAccessibilityTraitButton];
}

- (KIFUIViewTestActor *)greeting;
{
    return [self usingLabel:@"Greeting"];
}

@end

@interface TappingTests_ViewTestActor : KIFTestCase
@end


@implementation TappingTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Tapping"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testTappingViewWithAccessibilityLabel
{
    // Since the tap has occurred in setup, we just need to wait for the result.
    [[viewTester usingLabel:@"TapView"] waitForView];
}

- (void)testTappingViewWithTraits
{
    [[viewTester xButton] tap];
    [[[viewTester xButton] usingTraits:UIAccessibilityTraitSelected] waitForView];
}

- (void)testTappingViewWithValue
{
    [[[viewTester greeting] usingValue:@"Hello"] tap];
    [[viewTester greeting] waitToBecomeFirstResponder];
}

- (void)testTappingViewWithScreenAtPoint
{
    [viewTester waitForTimeInterval:0.75];
    [viewTester tapScreenAtPoint:CGPointMake(15, 200)];
    [[[viewTester xButton] usingTraits:UIAccessibilityTraitSelected] waitForView];
}

- (void)testTappingViewPartiallyOffscreenAndWithinScrollView
{
    [[viewTester usingLabel:@"Slightly Offscreen Button"] tap];
}

- (void)testTappingViewWithTapGestureRecognizer
{
    [[viewTester usingLabel:@"Label with Tap Gesture Recognizer"] tap];
}

- (void)testTappingLabelWithLineBreaks
{
    [[viewTester usingLabel:@"Label with\nLine Break\n\n"] tap];
    [[viewTester usingLabel:@"A\nB\nC\n\n"] tap];
}


@end
