//
//  ScrollViewTests.m
//  Test Suite
//
//  Created by Hilton Campbell on 2/20/14.
//
//

#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"

@interface ScrollViewTests : KIFTestCase
@end

@implementation ScrollViewTests

- (void)beforeEach
{
    XCTAssertTrue([[tester class] testActorAnimationsEnabled]);
    [tester tapViewWithAccessibilityLabel:@"ScrollViews"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
    [[tester class] setTestActorAnimationsEnabled:YES];
}

- (void)testScrollingToTapOffscreenViews
{
    [tester tapViewWithAccessibilityLabel:@"Down"];
    [tester tapViewWithAccessibilityLabel:@"Up"];
    [tester tapViewWithAccessibilityLabel:@"Right"];
    [tester tapViewWithAccessibilityLabel:@"Left"];
}

- (void)testScrollingToTapOffscreenViewsWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];
    [tester tapViewWithAccessibilityLabel:@"Down"];
    [tester tapViewWithAccessibilityLabel:@"Up"];
    [tester tapViewWithAccessibilityLabel:@"Right"];
    [tester tapViewWithAccessibilityLabel:@"Left"];
}

- (void)testScrollingToTapOffscreenTextView
{
    [tester tapViewWithAccessibilityLabel:@"TextView"];
}

- (void)testScrollingToTapOffscreenTextViewWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];
    [tester tapViewWithAccessibilityLabel:@"TextView"];
}

@end
