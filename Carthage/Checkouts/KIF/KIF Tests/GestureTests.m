//
//  GestureTests.m
//  Test Suite
//
//  Created by Brian Nickel on 6/28/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>
#import <KIF/KIFTestStepValidation.h>

@interface GestureTests : KIFTestCase
@end

@implementation GestureTests

- (void)beforeAll
{
    [tester tapViewWithAccessibilityLabel:@"Gestures"];
}

- (void)afterAll
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testSwipingLeft
{
    [tester swipeViewWithAccessibilityLabel:@"Swipe Me" inDirection:KIFSwipeDirectionLeft];
    [tester waitForViewWithAccessibilityLabel:@"Left"];
}

- (void)testSwipingRight
{
    [tester swipeViewWithAccessibilityLabel:@"Swipe Me" inDirection:KIFSwipeDirectionRight];
    [tester waitForViewWithAccessibilityLabel:@"Right"];
}

- (void)testSwipingUp
{
    [tester swipeViewWithAccessibilityLabel:@"Swipe Me" inDirection:KIFSwipeDirectionUp];
    [tester waitForViewWithAccessibilityLabel:@"Up"];
}

- (void)testSwipingDown
{
    [tester swipeViewWithAccessibilityLabel:@"Swipe Me" inDirection:KIFSwipeDirectionDown];
    [tester waitForViewWithAccessibilityLabel:@"Down"];
}

- (void)testMissingSwipeableElement
{
    KIFExpectFailure([[tester usingTimeout:0.25] swipeViewWithAccessibilityLabel:@"Unknown" inDirection:KIFSwipeDirectionDown]);
}

- (void)testSwipingLeftWithTraits
{
    [tester swipeViewWithAccessibilityLabel:@"Swipe Me" value:nil traits:UIAccessibilityTraitStaticText inDirection:KIFSwipeDirectionLeft];
    [tester waitForViewWithAccessibilityLabel:@"Left"];
}

- (void)testSwipingRightWithTraits
{
    [tester swipeViewWithAccessibilityLabel:@"Swipe Me" value:nil traits:UIAccessibilityTraitStaticText inDirection:KIFSwipeDirectionRight];
    [tester waitForViewWithAccessibilityLabel:@"Right"];
}

- (void)testSwipingUpWithTraits
{
    [tester swipeViewWithAccessibilityLabel:@"Swipe Me" value:nil traits:UIAccessibilityTraitStaticText inDirection:KIFSwipeDirectionUp];
    [tester waitForViewWithAccessibilityLabel:@"Up"];
}

- (void)testSwipingDownWithTraits
{
    [tester swipeViewWithAccessibilityLabel:@"Swipe Me" value:nil traits:UIAccessibilityTraitStaticText inDirection:KIFSwipeDirectionDown];
    [tester waitForViewWithAccessibilityLabel:@"Down"];
}

- (void)testMissingSwipeableElementWithTraits
{
    KIFExpectFailure([[tester usingTimeout:0.25] swipeViewWithAccessibilityLabel:@"Unknown" value:nil traits:UIAccessibilityTraitStaticText inDirection:KIFSwipeDirectionDown]);
}

- (void)testScrolling
{
    [tester scrollViewWithAccessibilityIdentifier:@"Scroll View" byFractionOfSizeHorizontal:-0.9 vertical:-0.9];
    [tester waitForTappableViewWithAccessibilityLabel:@"Bottom Right"];
    [tester scrollViewWithAccessibilityIdentifier:@"Scroll View" byFractionOfSizeHorizontal:0.9 vertical:0.9];
    [tester waitForTappableViewWithAccessibilityLabel:@"Top Left"];
}

- (void)testMissingScrollableElement
{
    KIFExpectFailure([[tester usingTimeout:0.25] scrollViewWithAccessibilityIdentifier:@"Unknown" byFractionOfSizeHorizontal:0.5 vertical:0.5]);
}

@end
