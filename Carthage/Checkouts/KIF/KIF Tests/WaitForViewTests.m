//
//  WaitForViewTests.m
//  Test Suite
//
//  Created by Brian Nickel on 6/28/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>

@interface WaitForViewTests : KIFTestCase
@end

@implementation WaitForViewTests

- (void)beforeAll;
{
    [super beforeAll];

    // If a previous test was still in the process of navigating back to the main view, let that complete before starting this test
    [tester waitForAnimationsToFinish];
}

- (void)testWaitingForViewWithAccessibilityLabel
{
    [tester waitForViewWithAccessibilityLabel:@"Test Suite"];
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
    [tester waitForViewWithAccessibilityLabel:label traits:traits];
}

- (void)testWaitingForViewWithValue
{
    [tester waitForViewWithAccessibilityLabel:@"Switch 1" value:@"1" traits:UIAccessibilityTraitNone];
}

@end
