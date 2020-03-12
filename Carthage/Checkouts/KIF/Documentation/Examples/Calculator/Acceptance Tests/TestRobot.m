//
//  TestRobot.m
//  Calculator
//
//  Created by Justin Martin on 9/18/17.
//  Copyright © 2017 SSK Development. All rights reserved.
//

#import <KIF/KIF.h>

#import "TestRobot.h"


@interface TestRobot ()

@property (nonatomic, readwrite, weak) KIFTestCase *testCase;

@end


@implementation TestRobot

- (instancetype)initWithTestCase:(KIFTestCase *)testCase;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _testCase = testCase;
    return self;
}

#pragma mark - KIFTestActorDelegate

- (void)failWithException:(NSException *)exception stopTest:(BOOL)stop;
{
    [self.testCase failWithException:exception stopTest:stop];
}

- (void)failWithExceptions:(NSArray *)exceptions stopTest:(BOOL)stop;
{
    [self.testCase failWithExceptions:exceptions stopTest:stop];
}

@end
