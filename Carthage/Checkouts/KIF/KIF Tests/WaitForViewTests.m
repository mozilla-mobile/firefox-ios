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

- (void)testWaitingForViewWithAccessibilityLabel
{
    [tester waitForViewWithAccessibilityLabel:@"Test Suite"];
}

- (void)testWaitingForViewWithTraits
{
    [tester waitForViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitStaticText];
}

- (void)testWaitingForViewWithValue
{
    [tester waitForViewWithAccessibilityLabel:@"Switch 1" value:@"1" traits:UIAccessibilityTraitNone];
}

@end
