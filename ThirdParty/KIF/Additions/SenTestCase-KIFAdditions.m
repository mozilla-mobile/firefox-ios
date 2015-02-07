//
//  SenTestCase-KIFAdditions.m
//  KIF
//
//  Created by Brian Nickel on 8/23/13.
//
//

#import "SenTestCase-KIFAdditions.h"
#import "LoadableCategory.h"

MAKE_CATEGORIES_LOADABLE(SenTestCase_KIFAdditions)

@implementation SenTestCase (KIFAdditions)

- (void)failWithException:(NSException *)exception stopTest:(BOOL)stop
{
    if (stop) {
        [self raiseAfterFailure];
    }
    [self failWithException:exception];
    [self continueAfterFailure];
}

- (void)failWithExceptions:(NSArray *)exceptions stopTest:(BOOL)stop
{
    NSException *lastException = exceptions.lastObject;
    for (NSException *exception in exceptions) {
        [self failWithException:exception stopTest:(exception == lastException ? stop : NO)];
    }
}

@end
