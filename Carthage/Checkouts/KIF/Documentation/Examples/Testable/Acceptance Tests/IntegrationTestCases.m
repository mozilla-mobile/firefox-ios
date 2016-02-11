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

- (void)testThatUserCanSuccessfullyLogIn
{
    [tester reset];
    [tester goToLoginPage];
    [tester enterText:@"user@example.com" intoViewWithAccessibilityLabel:@"Login User Name"];
    [tester enterText:@"thisismypassword" intoViewWithAccessibilityLabel:@"Login Password"];
    [tester tapViewWithAccessibilityLabel:@"Log In"];
    
    // Verify that the login succeeded
    [tester waitForTappableViewWithAccessibilityLabel:@"Welcome"];
}

- (void)testSelectingDifferentColors
{
    [tester tapViewWithAccessibilityLabel:@"Purple"];
    [tester tapViewWithAccessibilityLabel:@"Blue"];
    [tester tapViewWithAccessibilityLabel:@"Red"];
    [tester waitForTimeInterval:5.0];
    [tester waitForViewWithAccessibilityLabel:@"Selected: Red"];
}

@end
