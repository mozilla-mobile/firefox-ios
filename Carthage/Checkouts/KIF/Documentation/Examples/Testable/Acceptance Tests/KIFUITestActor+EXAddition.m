//
//  KIFTester+EXAddition.m
//  Testable
//
//  Created by Brian Nickel on 12/18/12.
//
//

#import "KIFUITestActor+EXAddition.h"

@implementation KIFUITestActor (EXAddition)

- (void)reset
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        BOOL successfulReset = YES;
        
        // Do the actual reset for your app. Set successfulReset = NO if it fails.
        
        KIFTestCondition(successfulReset, error, @"Failed to reset some part of the application.");
        
        return KIFTestStepResultSuccess;
    }];
}

#pragma mark - Step Collections

- (void)goToLoginPage
{
    // Dismiss the welcome message
    [self tapViewWithAccessibilityLabel:@"That's awesome!"];
    
    // Tap the "I already have an account" button
    [self tapViewWithAccessibilityLabel:@"I already have an account."];
}

@end
