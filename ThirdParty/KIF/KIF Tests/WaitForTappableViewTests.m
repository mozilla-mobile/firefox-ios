//
//  WaitForTappableViewTests.m
//  Test Suite
//
//  Created by Brian Nickel on 6/28/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>

@interface WaitForTappableViewTests : KIFTestCase
@end

@implementation WaitForTappableViewTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Show/Hide"];
    [tester tapViewWithAccessibilityLabel:@"Cover/Uncover"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}


- (void)testWaitingForTappableViewWithAccessibilityLabel
{
    [tester waitForTappableViewWithAccessibilityLabel:@"B"];
}

- (void)testWaitingForViewWithTraits
{
    [tester waitForTappableViewWithAccessibilityLabel:@"B" traits:UIAccessibilityTraitButton];
}

- (void)testWaitingForViewWithValue
{
    [tester waitForTappableViewWithAccessibilityLabel:@"B" value:@"BB" traits:UIAccessibilityTraitButton];
}

@end
