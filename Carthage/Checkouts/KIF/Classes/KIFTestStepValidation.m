//
//  KIFTestStepValidation.m
//  KIF
//
//  Created by Brian Nickel on 7/27/13.
//
//

#import "KIFTestStepValidation.h"

@implementation _MockKIFTestActorDelegate

- (void)failWithException:(NSException *)exception stopTest:(BOOL)stop
{
    [self failWithExceptions:@[exception] stopTest:stop];
}

- (void)failWithExceptions:(NSArray *)exceptions stopTest:(BOOL)stop
{
    self.failed = YES;
    self.exceptions = exceptions;
    self.stopped = stop;
    if (stop) {
        [[exceptions objectAtIndex:0] raise];
    }
}

+ (instancetype)mockDelegate
{
    return [[self alloc] init];
}


@end
