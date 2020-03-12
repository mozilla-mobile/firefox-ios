//
//  NewExistsTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//

#import <KIF/KIF.h>

@interface ExistTests_ViewTestActor : KIFTestCase
@end


@implementation ExistTests_ViewTestActor

- (void)beforeAll;
{
    [super beforeAll];

    // If a previous test was still in the process of navigating back to the main view, let that complete before starting this test
    [tester waitForAnimationsToFinish];
}

- (void)testExistsViewWithAccessibilityLabel
{
    if ([[viewTester usingLabel:@"Tapping"] tryFindingTappableView] && ![[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tryFindingTappableView]) {
        [[viewTester usingLabel:@"Tapping"] tap];
    } else {
        [viewTester fail];
    }

    if ([[viewTester usingLabel:@"Test Suite"] tryFindingTappableView] && ![[viewTester usingLabel:@"Tapping"] tryFindingTappableView]) {
        [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
    } else {
        [viewTester fail];
    }
}

@end
