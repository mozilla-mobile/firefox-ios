//
//  CascadingFailureTests.m
//  Test Suite
//
//  Created by Brian Nickel on 8/4/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"

@interface KIFSystemTestActor (CascadingFailureTests)
- (void)failA;
@end

@implementation KIFSystemTestActor (CascadingFailureTests)

- (void)failA
{
    [system failB];
}

- (void)failB
{
    [system failC];
}

- (void)failC
{
    [system fail];
}

@end

@interface CascadingFailureTests : KIFTestCase
@end

@implementation CascadingFailureTests

- (void)testCascadingFailure
{
    KIFExpectFailure([system failA]);
    KIFExpectFailureWithCount([system failA], 4);
}

@end
