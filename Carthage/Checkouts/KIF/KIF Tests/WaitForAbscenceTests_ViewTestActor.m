//
//  NewWaitForAbsenceTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//


#import <KIF/KIF.h>

@interface WaitForAbscenceTests_ViewTestActor : KIFTestCase
@end


@implementation WaitForAbscenceTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Tapping"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testWaitingForAbsenceOfViewWithAccessibilityLabel
{
    [[viewTester usingLabel:@"Tapping"] waitForAbsenceOfView];
}

- (void)testWaitingForAbsenceOfViewWithTraits
{
    [[[viewTester usingLabel:@"Tapping"] usingTraits:UIAccessibilityTraitStaticText] waitForAbsenceOfView];
}

- (void)testWaitingForAbsenceOfViewWithValue
{
    [[[viewTester usingLabel:@"Switch 1"] usingValue:@"1"] waitForAbsenceOfView];
}

@end
