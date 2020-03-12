//
//  ViewWaitForViewTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//


#import <KIF/KIF.h>

@interface WaitForViewTests_ViewTestActor : KIFTestCase
@end


@implementation WaitForViewTests_ViewTestActor

- (void)beforeAll;
{
    [super beforeAll];

    // If a previous test was still in the process of navigating back to the main view, let that complete before starting this test
    [tester waitForAnimationsToFinish];
}

- (void)testWaitingForViewWithAccessibilityLabel
{
    [[viewTester usingLabel:@"Test Suite"] waitForView];
}

- (void)testWaitingForViewWithTraits
{
    NSString *label = nil;
    UIAccessibilityTraits traits = UIAccessibilityTraitNone;

    NSOperatingSystemVersion iOS9 = {9, 0, 0};
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)] && ![[NSProcessInfo new] isOperatingSystemAtLeastVersion:iOS9]) {
        // In iOS 8 and before, you couldn't identify the table view elements as buttons
        label = @"Test Suite";
        traits = UIAccessibilityTraitStaticText;
    } else {
        // In iOS 11, the static text trait of the navigation bar header goes away for some reason
        label = @"UIAlertView";
        traits = UIAccessibilityTraitButton;
    }
    [[[viewTester usingLabel:label] usingTraits:traits] waitForView];
}

- (void)testWaitingForViewWithValue
{
    [[[viewTester usingLabel:@"Switch 1"] usingValue:@"1"] waitForView];
}

@end
