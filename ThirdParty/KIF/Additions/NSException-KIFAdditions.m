//
//  NSException-KIFAdditions.m
//  KIF
//
//  Created by Tony DiPasquale on 12/20/13.
//
//

#import "NSException-KIFAdditions.h"

@implementation NSException (KIFAdditions)

+ (NSException *)failureInFile:(NSString *)file atLine:(NSInteger)line withDescription:(NSString *)formatString, ...
{
    va_list argumentList;
    va_start(argumentList, formatString);

    NSString *reason = [[NSString alloc] initWithFormat:formatString arguments:argumentList];

    va_end(argumentList);

    return [NSException exceptionWithName:@"KIFFailureException"
                                   reason: reason
                                 userInfo:@{@"SenTestFilenameKey": file,
                                            @"SenTestLineNumberKey": @(line)}];
}

@end
