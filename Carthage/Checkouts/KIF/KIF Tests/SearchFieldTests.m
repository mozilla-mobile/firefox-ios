//
//  SearchFieldTests.m
//  KIF
//
//  Created by Brian Nickel on 9/13/13.
//
//

#import <KIF/KIF.h>
#import <KIF/UIApplication-KIFAdditions.h>

@interface SearchFieldTests : KIFTestCase
@end

@implementation SearchFieldTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"TableViews"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testWaitingForSearchFieldToBecomeFirstResponder
{
    [tester tapViewWithAccessibilityLabel:nil traits:UIAccessibilityTraitSearchField];
    [tester waitForFirstResponderWithAccessibilityLabel:nil traits:UIAccessibilityTraitSearchField];
    [tester enterTextIntoCurrentFirstResponder:@"text"];
    [tester waitForViewWithAccessibilityLabel:nil value:@"text" traits:UIAccessibilityTraitSearchField];
}

@end
