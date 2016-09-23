//
//  NSURLSession+NSURLDataWithRequestMocking.h
//  adjust
//
//  Created by Pedro Filipe on 25/01/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ADJSessionResponseTypeNil = 0,
    ADJSessionResponseTypeConnError = 1,
    ADJSessionResponseTypeWrongJson = 2,
    ADJSessionResponseTypeEmptyJson = 3,
    ADJSessionResponseTypeServerError = 4,
    ADJSessionResponseTypeMessage = 5,
} ADJSessionResponseType;

@interface NSURLSession(NSURLDataWithRequestMocking)

/* Creates a data task with the given request.  The request may have a body stream. */
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error))completionHandler;

+ (void)setResponseType:(ADJSessionResponseType)responseType;
+ (NSURLResponse *)getLastRequest;
+ (void)reset;
+ (void)setTimeoutMock:(BOOL)enable;
+ (void)setWaitingTime:(double)waitingTime;

@end

@interface NSURLSessionDataTask(NSURLResume)

- (void)resume;

@end