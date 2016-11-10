//
//  NewGestureTests.m
//  KIF
//
//  Created by Alex Odawa on 1/27/15.
//
//


#import <KIF/KIF.h>
#import <KIF/KIFTestStepValidation.h>
@implementation KIFUIViewTestActor (gesturetests)

- (KIFUIViewTestActor *)swipeMe
{
    return [self usingLabel:@"Swipe Me"];
}
@end


@interface GestureTests_ViewTestActor : KIFTestCase
@end

@implementation GestureTests_ViewTestActor

- (void)beforeAll
{
    [[viewTester usingLabel:@"Gestures"] tap];
    
    // Wait for the push animation to complete before trying to interact with the view
    [viewTester waitForTimeInterval:.25];
}

- (void)afterAll
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testSwipingLeft
{
    [[viewTester swipeMe] swipeInDirection:KIFSwipeDirectionLeft];
    [[viewTester usingLabel:@"Left"] waitForView];
}

- (void)testSwipingRight
{
    [[viewTester swipeMe] swipeInDirection:KIFSwipeDirectionRight];
    [[viewTester usingLabel:@"Right"] waitForView];
}

- (void)testSwipingUp
{
    [[viewTester swipeMe] swipeInDirection:KIFSwipeDirectionUp];
    [[viewTester usingLabel:@"Up"] waitForView];
}

- (void)testSwipingDown
{
    [[viewTester swipeMe] swipeInDirection:KIFSwipeDirectionDown];
    [[viewTester usingLabel:@"Down"] waitForView];
}

- (void)testMissingSwipeableElement
{
    KIFExpectFailure([[[viewTester usingTimeout:0.25] usingLabel:@"Unknown"] swipeInDirection:KIFSwipeDirectionDown]);
}

- (void)testSwipingLeftWithTraits
{
    [[[viewTester swipeMe] usingTraits:UIAccessibilityTraitStaticText] swipeInDirection:KIFSwipeDirectionLeft];
    [[viewTester usingLabel:@"Left"] waitForView];
}

- (void)testSwipingRightWithTraits
{
    [[[viewTester swipeMe] usingTraits:UIAccessibilityTraitStaticText] swipeInDirection:KIFSwipeDirectionRight];
    [[viewTester usingLabel:@"Right"] waitForView];
}

- (void)testSwipingUpWithTraits
{
    [[[viewTester swipeMe] usingTraits:UIAccessibilityTraitStaticText] swipeInDirection:KIFSwipeDirectionUp];
    [[viewTester usingLabel:@"Up"] waitForView];
}

- (void)testSwipingDownWithTraits
{
    [[[viewTester swipeMe] usingTraits:UIAccessibilityTraitStaticText] swipeInDirection:KIFSwipeDirectionDown];
    [[viewTester usingLabel:@"Down"] waitForView];
}

- (void)testMissingSwipeableElementWithTraits
{
    KIFExpectFailure([[[[viewTester usingTimeout:0.25] usingLabel:@"Unknown"] usingTraits:UIAccessibilityTraitStaticText] swipeInDirection:KIFSwipeDirectionDown]);
}

- (void)testScrolling
{
    // Needs to be offset from the edge to prevent the navigation controller's interactivePopGestureRecognizer from triggering
    [[viewTester usingIdentifier:@"Scroll View"] scrollByFractionOfSizeHorizontal:-0.80 vertical:-0.80];
    [[viewTester usingLabel:@"Bottom Right"] waitToBecomeTappable];
    [[viewTester usingIdentifier:@"Scroll View"] scrollByFractionOfSizeHorizontal:0.80 vertical:0.80];
    [[viewTester usingLabel:@"Top Left"] waitToBecomeTappable];
}

- (void)testMissingScrollableElement
{
    KIFExpectFailure([[[viewTester usingTimeout:0.25] usingIdentifier:@"Unknown"] scrollByFractionOfSizeHorizontal:0.5 vertical:0.5]);
}

@end
