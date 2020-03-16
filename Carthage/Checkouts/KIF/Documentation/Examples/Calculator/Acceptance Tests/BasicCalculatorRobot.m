//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <KIF/KIF.h>

#import "BasicCalculatorRobot.h"


@implementation BasicCalculatorRobot

#pragma mark - Public Methods

- (void)enterValue1:(NSString *)value1 value2:(NSString *)value2 operation:(NSString *)operation
{
    [self enterValue1:value1];
    [self enterValue2:value2];
    [self setOperation:operation];
}

- (void)enterValue1:(NSString *)value
{
    [[viewTester usingLabel:@"First Number"] clearAndEnterText:value];
}

- (void)enterValue2:(NSString *)value
{
    [[viewTester usingLabel:@"Second Number"] clearAndEnterText:value];
}

- (void)setOperation:(NSString *)operation
{
    [[viewTester usingLabel:operation] tap];
}

- (void)waitForResult:(NSString *)result
{
    [[viewTester usingLabel:result] waitForView];
}

@end


BasicCalculatorRobot *basicCalculatorRobot(KIFTestCase *testCase)
{
    return [[BasicCalculatorRobot alloc] initWithTestCase:testCase];
}
