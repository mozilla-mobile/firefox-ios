//
//  ViewWaitForTappableViewTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//

#import <KIF/KIF.h>

@interface WaitForTappableViewTests_ViewTestActor : KIFTestCase
@end


@implementation WaitForTappableViewTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Show/Hide"] tap];
    [[viewTester usingLabel:@"Cover/Uncover"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testWaitingForTappableViewWithAccessibilityLabel
{
    [[viewTester usingLabel:@"B"] waitToBecomeTappable];
}

- (void)testWaitingForViewWithTraits
{
    [[[viewTester usingLabel:@"B"] usingTraits:UIAccessibilityTraitButton] waitToBecomeTappable];
}

- (void)testWaitingForViewWithValue
{
    [[[[viewTester usingLabel:@"B"] usingValue:@"BB"] usingTraits:UIAccessibilityTraitButton] waitToBecomeTappable];
}

@end
