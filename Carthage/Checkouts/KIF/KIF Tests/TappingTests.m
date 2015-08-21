//
//  TappingTests.m
//  Test Suite
//
//  Created by Brian Nickel on 6/28/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>

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

- (void)testTappingViewWithAccessibilityLabel
{
    // Since the tap has occurred in setup, we just need to wait for the result.
    [tester waitForViewWithAccessibilityLabel:@"TapViewController"];
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

@end
