//
//  BasicCalculatorTests.m
//  Calculator
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

@import KIF;

#import "BasicCalculatorRobot.h"


@interface BasicCalculatorTests : KIFTestCase
@end


@implementation BasicCalculatorTests

- (void)beforeAll
{
    // Run the test animations super fast!!!
    UIApplication.sharedApplication.animationSpeed = 4.0;
    KIFTypist.keystrokeDelay = 0.0025f;
    KIFTestActor.defaultAnimationStabilizationTimeout = 0.1;
    KIFTestActor.defaultAnimationWaitingTimeout = 2.0;
    
    [[[viewTester usingLabel:@"Basic Calculator"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)afterAll
{
    [[[viewTester usingLabel:@"Home"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testAddition
{
    [basicCalculatorRobot(self) enterValue1:@"100" value2:@"11.11111" operation:@"Add"];
    [basicCalculatorRobot(self) waitForResult:@"111.11111000"];
}

- (void)testSubtraction
{
    [basicCalculatorRobot(self) enterValue1:@"200" value2:@"0.1" operation:@"Subtract"];
    [basicCalculatorRobot(self) waitForResult:@"199.90000000"];
}

- (void)testMultiplication
{
    [basicCalculatorRobot(self) enterValue1:@"11.000" value2:@"1.1" operation:@"Multiply"];
    [basicCalculatorRobot(self) waitForResult:@"12.10000000"];
}

- (void)testDivision
{
    [basicCalculatorRobot(self) enterValue1:@"5.000" value2:@"2" operation:@"Divide"];
    [basicCalculatorRobot(self) waitForResult:@"2.50000000"];
}

- (void)testToFail
{
    [viewTester fail];
    NSLog(@"This line never executes.");
}

@end
