//
//  WaitForAbscenceTests.m
//  Test Suite
//
//  Created by Brian Nickel on 6/28/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>

@interface WaitForAbscenceTests : KIFTestCase
@end

@implementation WaitForAbscenceTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Tapping"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testWaitingForAbsenceOfViewWithAccessibilityLabel
{
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Tapping"];
}

- (void)testWaitingForAbsenceOfViewWithTraits
{
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Tapping" traits:UIAccessibilityTraitStaticText];
}

- (void)testWaitingForAbsenceOfViewWithValue
{
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Switch 1" value:@"1" traits:UIAccessibilityTraitNone];
}

@end
