//
//  ViewWaitForAnimationTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//

#import <KIF/KIF.h>

@interface WaitForAnimationTests_ViewTestActor : KIFTestCase
@end


@implementation WaitForAnimationTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Tapping"] tap];
    [[viewTester usingLabel:@"Animations"] tap];
}

- (void)afterEach
{
    [[viewTester usingLabel:@"Back"] tap];
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testWaitForFinishingAnimation
{
    [viewTester tapScreenAtPoint:CGPointMake(100, 100)];
    [[viewTester usingLabel:@"Label"] waitForView];
}

@end
