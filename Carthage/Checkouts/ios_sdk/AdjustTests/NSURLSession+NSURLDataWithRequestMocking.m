//
//  NSURLSession+NSURLDataWithRequestMocking.m
//  adjust
//
//  Created by Pedro Filipe on 25/01/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "NSURLSession+NSURLDataWithRequestMocking.h"
#import "ADJAdjustFactory.h"
#import "ADJLoggerMock.h"

static ADJSessionResponseType sessionResponseTypeInternal;
static NSURLRequest * lastRequest = nil;

static NSData * completionData = nil;
static NSURLResponse * completionResponse = nil;
static NSError * completionError = nil;

static BOOL timeoutMockInternal = NO;
static double waitingTimeInternal = 0.0;

static void (^completionDelegate) (NSData * data, NSURLResponse * response, NSError * error)  = nil;

@implementation NSURLSession(NSURLDataWithRequestMocking)

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error))completionHandler
{
    ADJLoggerMock *loggerMock =(ADJLoggerMock *)ADJAdjustFactory.logger;
    [loggerMock test:@"NSURLSession dataTaskWithRequest"];

    lastRequest = request;
    NSInteger statusCode = -1;
    NSString * sResponse = nil;
    completionDelegate = completionHandler;

    completionResponse = nil;
    completionData = nil;
    completionError = nil;

    if (timeoutMockInternal) {
        [NSThread sleepForTimeInterval:10.0];
    }

    if (waitingTimeInternal != 0) {
        [NSThread sleepForTimeInterval:waitingTimeInternal];
    }

    if (sessionResponseTypeInternal == ADJSessionResponseTypeNil) {

    } else if (sessionResponseTypeInternal == ADJSessionResponseTypeConnError) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"connection error", nil) };
        completionError = [NSError errorWithDomain:@"Adjust"
                                       code:-57
                                   userInfo:userInfo];
    } else if (sessionResponseTypeInternal == ADJSessionResponseTypeServerError) {
        statusCode = 500;
        sResponse = @"{ \"message\": \"testResponseError\"}";
    } else if (sessionResponseTypeInternal == ADJSessionResponseTypeWrongJson) {
        statusCode = 200;
        sResponse = @"not a json response";
    } else if (sessionResponseTypeInternal == ADJSessionResponseTypeEmptyJson) {
        statusCode = 200;
        sResponse = @"{ }";
    } else if (sessionResponseTypeInternal == ADJSessionResponseTypeMessage) {
        statusCode = 200;
        sResponse = @"{ \"message\" : \"response OK\"}";
    }

    //  build response
    if (statusCode != -1) {
        completionResponse = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:statusCode HTTPVersion:@"" headerFields:nil];
    }

    if (sResponse != nil) {
        completionData = [sResponse dataUsingEncoding:NSUTF8StringEncoding];
    }

    return [[NSURLSessionDataTask alloc] init];
}

+ (void)setResponseType:(ADJSessionResponseType)responseType {
    sessionResponseTypeInternal = responseType;
}

+ (NSURLRequest *)getLastRequest
{
    return lastRequest;
}

+ (void)reset {
    sessionResponseTypeInternal = ADJSessionResponseTypeNil;
    lastRequest = nil;
    timeoutMockInternal = NO;
    waitingTimeInternal = 0.0;
}

+ (void)setTimeoutMock:(BOOL)enable {
    timeoutMockInternal = enable;
}
+ (void)setWaitingTime:(double)waitingTime {
    waitingTimeInternal = waitingTime;
}

@end

@implementation NSURLSessionDataTask(NSURLResume)

- (void)resume
{
    ADJLoggerMock *loggerMock =(ADJLoggerMock *)ADJAdjustFactory.logger;
    [loggerMock test:@"NSURLSessionDataTask resume"];

    completionDelegate(completionData, completionResponse, completionError);
}

@end
