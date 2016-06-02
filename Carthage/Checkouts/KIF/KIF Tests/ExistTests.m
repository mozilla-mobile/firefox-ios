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

- (void)testExistsViewWithAccessibilityLabel
{
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Tapping" error:NULL] && ![tester tryFindingTappableViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton error:NULL]) {
        [tester tapViewWithAccessibilityLabel:@"Tapping"];
    } else {
        [tester fail];
    }
    
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Test Suite" error:NULL] && ![tester tryFindingTappableViewWithAccessibilityLabel:@"Tapping" error:NULL]) {
        [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
    } else {
        [tester fail];
    }
}


@end
