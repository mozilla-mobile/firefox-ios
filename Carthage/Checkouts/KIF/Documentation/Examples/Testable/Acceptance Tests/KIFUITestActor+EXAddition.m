//
//  KIFTester+EXAddition.m
//  Testable
//
//  Created by Brian Nickel on 12/18/12.
//
//

#import "KIFUITestActor+EXAddition.h"

@implementation KIFUIViewTestActor (EXAddition)

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

- (KIFUIViewTestActor *)redCell;
{
    return [self usingLabel:@"Red"];
}

- (KIFUIViewTestActor *)blueCell;
{
    return [self usingLabel:@"Blue"];
}

- (void)validateSelectedColor:(NSString *)color;
{
    [[self usingLabel:[NSString stringWithFormat:@"Selected: %@", color]] waitForView];
}

@end
