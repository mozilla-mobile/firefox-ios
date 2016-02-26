//
//  SimpleObjCTest.m
//  Testable Swift
//
//  Created by Jim Puls on 10/29/14.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <UIKit/UIKit.h>
#import <KIF/KIF.h>


@interface SimpleObjCTest : KIFTestCase
@end

@implementation SimpleObjCTest

- (void)testRed {
    [tester tapViewWithAccessibilityLabel:@"Red"];
    [tester waitForViewWithAccessibilityLabel:@"Selected: Red"];
}

@end
