//
//  ViewLongPressTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//

#import <KIF/KIF.h>

@interface LongPressTests_ViewTestActor : KIFTestCase
@end


@implementation LongPressTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Tapping"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testLongPressingViewWithAccessibilityLabel
{
    [[viewTester usingLabel:@"Greeting"] longPressWithDuration:2];
    [[viewTester usingLabel:@"Select All"] tap];
}

- (void)testLongPressingViewViewWithTraits
{
    [[[viewTester usingLabel:@"Greeting"] usingValue:@"Hello"] longPressWithDuration:2];
    [[viewTester usingLabel:@"Select All"] tap];
}

- (void)testLongPressingViewViewWithValue
{
    [[[[viewTester usingLabel:@"Greeting"] usingValue:@"Hello"] usingTraits:UIAccessibilityTraitUpdatesFrequently] longPressWithDuration:2];
    [[viewTester usingLabel:@"Select All"] tap];
}

@end
