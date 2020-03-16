//
//  ExistTests.m
//  KIF
//
//  Created by Jeroen Leenarts on 11-07-14.
//
//

#import <KIF/KIF.h>

@interface ExistTests : KIFTestCase
@end

@implementation ExistTests

- (void)beforeAll;
{
    [super beforeAll];

    // If a previous test was still in the process of navigating back to the main view, let that complete before starting this test
    [tester waitForAnimationsToFinish];
}

- (void)testExistsViewWithAccessibilityLabel
{
    BOOL tappingFound = [tester tryFindingTappableViewWithAccessibilityLabel:@"Tapping" error:NULL];
    BOOL testSuiteFound = [tester tryFindingTappableViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton error:NULL];
    if (tappingFound && !testSuiteFound) {
        [tester tapViewWithAccessibilityLabel:@"Tapping"];
    } else {
        [tester fail];
    }
    
    tappingFound = [tester tryFindingTappableViewWithAccessibilityLabel:@"Tapping" error:NULL];
    testSuiteFound = [tester tryFindingTappableViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton error:NULL];
    if (testSuiteFound && !tappingFound) {
        [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
    } else {
        [tester fail];
    }
}


@end
