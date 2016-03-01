//
//  SenTestCase-KIFAdditions.m
//  KIF
//
//  Created by Brian Nickel on 8/23/13.
//
//

#import "SenTestCase-KIFAdditions.h"
#import "LoadableCategory.h"
#import "UIApplication-KIFAdditions.h"

MAKE_CATEGORIES_LOADABLE(SenTestCase_KIFAdditions)

@implementation SenTestCase (KIFAdditions)

- (void)failWithException:(NSException *)exception stopTest:(BOOL)stop
{
    if (stop) {
        [self writeScreenshotForException:exception];
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

- (void)writeScreenshotForException:(NSException *)exception;
{
#ifndef KIF_SENTEST
    [[UIApplication sharedApplication] writeScreenshotForLine:[exception.userInfo[@"SenTestLineNumberKey"] unsignedIntegerValue] inFile:exception.userInfo[@"SenTestFilenameKey"] description:nil error:NULL];
#else
    [[UIApplication sharedApplication] writeScreenshotForLine:exception.lineNumber.unsignedIntegerValue inFile:exception.filename description:nil error:NULL];
#endif
}

@end
