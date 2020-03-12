//
//  IntegrationTestCases.m
//  Integration Tests with KIFTestCase
//
//  Created by Brian Nickel on 12/18/12.
//
//

#import <KIF/KIF.h>
#import "KIFUITestActor+EXAddition.h"

@interface IntegrationTestCases : KIFTestCase

@end

@implementation IntegrationTestCases

- (void)testThatUsesViewTestActorCategory
{
    [[viewTester redCell] tap];
    [viewTester validateSelectedColor:@"Red"];
    [[viewTester blueCell] tap];
    [viewTester validateSelectedColor:@"Blue"];
}

- (void)testSelectingDifferentColors
{
    [[viewTester usingLabel:@"Purple"] tap];
    [[viewTester usingLabel:@"Blue"] tap];
    [[viewTester usingLabel:@"Red"] tap];
    [viewTester waitForTimeInterval:5.0];
    [[viewTester usingLabel:@"Selected: Red"] waitForView];
}

@end
