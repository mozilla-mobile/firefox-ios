//
//  SentryRequestOperation.m
//  Sentry
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryRequestOperation.h>
#import <Sentry/SentryLog.h>
#import <Sentry/SentryError.h>
#import <Sentry/SentryClient.h>

#else
#import "SentryRequestOperation.h"
#import "SentryLog.h"
#import "SentryError.h"
#import "SentryClient.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SentryRequestOperation ()

@property(nonatomic, strong) NSURLSessionTask *task;
@property(nonatomic, strong) NSURLRequest *request;

@end

@implementation SentryRequestOperation

- (instancetype)initWithSession:(NSURLSession *)session request:(NSURLRequest *)request
              completionHandler:(_Nullable SentryRequestOperationFinished)completionHandler {
    self = [super init];
    if (self) {
        self.request = request;
        self.task = [session dataTaskWithRequest:self.request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = [httpResponse statusCode];
            
            // We only have these if's here because of performance reasons
            [SentryLog logWithMessage:[NSString stringWithFormat:@"Request status: %ld", (long) statusCode] andLevel:kSentryLogLevelDebug];
            if (SentryClient.logLevel == kSentryLogLevelVerbose) {
                [SentryLog logWithMessage:[NSString stringWithFormat:@"Request response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]] andLevel:kSentryLogLevelVerbose];
            }
            
            if (nil != error) {
                [SentryLog logWithMessage:[NSString stringWithFormat:@"Request failed: %@", error] andLevel:kSentryLogLevelError];
            }

            if (completionHandler) {
                completionHandler(httpResponse, error);
            }

            [self completeOperation];
        }];
    }
    return self;
}

- (void)cancel {
    if (nil != self.task) {
        [self.task cancel];
    }
    [super cancel];
}

- (void)main {
    if (nil != self.task) {
        [self.task resume];
    }
}

@end

NS_ASSUME_NONNULL_END
