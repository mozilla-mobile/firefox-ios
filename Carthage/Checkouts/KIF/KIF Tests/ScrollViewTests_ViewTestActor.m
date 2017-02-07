//
//  NewScrollViewTests.m
//  KIF
//
//  Created by Alex Odawa on 1/27/15.
//
//

#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"

@interface ScrollViewTests_ViewTestActor : KIFTestCase
@end

@implementation ScrollViewTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"ScrollViews"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testScrollingToTapOffscreenViews
{
    [[viewTester usingLabel:@"Down"] tap];
    [[viewTester usingLabel:@"Up"] tap];
    [[viewTester usingLabel:@"Right"] tap];
    [[viewTester usingLabel:@"Left"] tap];
}

- (void)testScrollingToTapOffscreenTextView
{
    [[viewTester usingLabel:@"TextView"] tap];
}

@end
