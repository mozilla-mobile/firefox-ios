//
//  BasicCalculatorTests.m
//  Calculator
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <KIF/KIF.h>

@interface KIFUITestActor (BasicCalculator)

- (void)enterValue1:(NSString *)value;
- (void)enterValue2:(NSString *)value;
- (void)setOperation:(NSString *)operation;
- (void)enterValue1:(NSString *)value1 value2:(NSString *)value2 operation:(NSString *)operation;
- (void)waitForResult:(NSString *)result;

@end

@implementation KIFUITestActor (BasicCalculator)

- (void)enterValue1:(NSString *)value
{
    [self clearTextFromAndThenEnterText:value intoViewWithAccessibilityLabel:@"First Number"];
}

- (void)enterValue2:(NSString *)value
{
    [self clearTextFromAndThenEnterText:value intoViewWithAccessibilityLabel:@"Second Number"];
}

- (void)setOperation:(NSString *)operation
{
    [self tapViewWithAccessibilityLabel:operation];
}

- (void)enterValue1:(NSString *)value1 value2:(NSString *)value2 operation:(NSString *)operation
{
    [self enterValue1:value1];
    [self enterValue2:value2];
    [self setOperation:operation];
}

- (void)waitForResult:(NSString *)result
{
    [self waitForViewWithAccessibilityLabel:result];
}

@end

@interface BasicCalculatorTests : KIFTestCase
@end

@implementation BasicCalculatorTests

- (void)beforeAll
{
    [tester tapViewWithAccessibilityLabel:@"Basic Calculator" traits:UIAccessibilityTraitButton];
}

- (void)afterAll
{
    [tester tapViewWithAccessibilityLabel:@"Home" traits:UIAccessibilityTraitButton];
}

- (void)testAddition
{
    [tester enterValue1:@"100" value2:@"11.11111" operation:@"Add"];
    [tester waitForResult:@"111.11111000"];
}

- (void)testSubtraction
{
    [tester enterValue1:@"200" value2:@"0.1" operation:@"Subtract"];
    [tester waitForResult:@"199.90000000"];
}

- (void)testMultiplication
{
    [tester enterValue1:@"11.000" value2:@"1.1" operation:@"Multiply"];
    [tester waitForResult:@"12.10000000"];
}

- (void)testDivision
{
    [tester enterValue1:@"5.000" value2:@"2" operation:@"Divide"];
    [tester waitForResult:@"2.50000000"];
}

- (void)testToFail
{
    [tester fail];
    NSLog(@"This line never executes.");
}

@end