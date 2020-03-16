//
//  ATLUtil.m
//  AdjustTestLibrary
//
//  Created by Pedro on 18.04.17.
//  Copyright © 2017 adjust. All rights reserved.
//

#import "ATLUtil.h"

static NSString * const kLogTag = @"AdjustTestLibrary";
static NSDateFormatter *dateFormat;

static NSString * const kDateFormat                 = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'Z";

@implementation ATLUtil

+ (void)initialize {
    dateFormat = [[NSDateFormatter alloc] init];

    if ([NSCalendar instancesRespondToSelector:@selector(calendarWithIdentifier:)]) {
        // http://stackoverflow.com/a/3339787
        NSString *calendarIdentifier;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
        if (&NSCalendarIdentifierGregorian != NULL) {
#pragma clang diagnostic pop
            calendarIdentifier = NSCalendarIdentifierGregorian;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            calendarIdentifier = NSGregorianCalendar;
#pragma clang diagnostic pop
        }

        dateFormat.calendar = [NSCalendar calendarWithIdentifier:calendarIdentifier];
    }

    dateFormat.locale = [NSLocale systemLocale];
    [dateFormat setDateFormat:kDateFormat];
}

+ (void)debug:(NSString *)format, ...{
    va_list parameters; va_start(parameters, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:parameters];
    va_end(parameters);
    NSArray *lines = [string componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSLog(@"\t[%@]: %@", kLogTag, line);
    }
}

+ (void)launchInQueue:(dispatch_queue_t)queue
           selfInject:(id)selfInject
                block:(selfInjectedBlock)block {
    __weak __typeof__(selfInject) weakSelf = selfInject;
    
    dispatch_async(queue, ^{
        __typeof__(selfInject) strongSelf = weakSelf;
        
        if (strongSelf == nil) {
            return;
        }
        
        block(strongSelf);
    });
}

+ (void)addOperationAfterLast:(NSOperationQueue *)operationQueue
           blockWithOperation:(operationBlock)blockWithOperation
{
    // https://stackoverflow.com/a/8113307/2393678
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak __typeof__(NSBlockOperation *) weakOperation = operation;

    [operation addExecutionBlock:^{
        __typeof__(NSBlockOperation *) strongOperation = weakOperation;

        if (strongOperation == nil) {
            return;
        }

        if (strongOperation.cancelled) {
            return;
        }

        blockWithOperation(strongOperation);
    }];

    // https://stackoverflow.com/a/32701781/2393678
    NSOperation *lastOperation = operationQueue.operations.lastObject;
    if (lastOperation != nil) {
        [operation addDependency: lastOperation];
    }

    [operationQueue addOperation:operation];
}


+ (void)addOperationAfterLast:(NSOperationQueue *)operationQueue
                        block:(dispatch_block_t)block
{
    // https://stackoverflow.com/a/8113307/2393678
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak __typeof__(NSBlockOperation *) weakOperation = operation;

    [operation addExecutionBlock:^{
        __typeof__(NSBlockOperation *) strongOperation = weakOperation;

        if (strongOperation == nil) {
            return;
        }

        if (strongOperation.cancelled) {
            return;
        }

        block();
    }];

    // https://stackoverflow.com/a/32701781/2393678
    NSOperation *lastOperation = operationQueue.operations.lastObject;
    if (lastOperation != nil) {
        [operation addDependency: lastOperation];
    }

    [operationQueue addOperation:operation];
}

+ (BOOL)isNull:(id)value {
    return value == nil || value == (id)[NSNull null];
}

+ (NSString *)adjTrim:(NSString *)value {
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSString *)formatDate:(NSDate *)value {
    if (dateFormat == nil) {
        return nil;
    }
    return [dateFormat stringFromDate:value];
}

+ (NSString *)parseDictionaryToJsonString:(NSDictionary *) dictionary {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                         options:0
                                                           error:&error];
    if (error != nil || data == nil) {
        [ATLUtil debug:@"error parsing dictionary to json: %@", error.description];
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)appendBasePath:(NSString *)basePath path:(NSString *)path {
    if (basePath == nil) {
        return path;
    } else {
        return [NSString stringWithFormat:@"%@%@", basePath, path];
    }
}

+ (NSString *)queryString:(NSDictionary *)parameters {
    if (parameters == nil) {
        return nil;
    }
    NSMutableArray *pairs = [NSMutableArray array];

    for (NSString *key in parameters) {
        NSString *value = [parameters objectForKey:key];
        NSString *escapedValue = [ATLUtil urlEncode:value ];
        NSString *escapedKey = [ATLUtil urlEncode:key];
        NSString *pair = [NSString stringWithFormat:@"%@=%@", escapedKey, escapedValue];

        [pairs addObject:pair];
    }

    NSString *queryString = [pairs componentsJoinedByString:@"&"];

    return queryString;
}

+ (NSString *)urlEncode:(NSString *)urlString {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (CFStringRef)urlString,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
#pragma clang diagnostic pop

    // Alternative:
    // return [self stringByAddingPercentEncodingWithAllowedCharacters:
    //        [NSCharacterSet characterSetWithCharactersInString:@"!*'\"();:@&=+$,/?%#[]% "]];
}

@end
