//
//  ADJSdkClickHandler.m
//  Adjust SDK
//
//  Created by Pedro Filipe (@nonelse) on 21st April 2016.
//  Copyright © 2016 Adjust GmbH. All rights reserved.
//

#import "ADJUtil.h"
#import "ADJLogger.h"
#import "ADJAdjustFactory.h"
#import "ADJSdkClickHandler.h"
#import "ADJBackoffStrategy.h"

static const char * const kInternalQueueName = "com.adjust.SdkClickQueue";

@interface ADJSdkClickHandler()

@property (nonatomic, copy) NSString *basePath;
@property (nonatomic, strong) NSMutableArray *packageQueue;
@property (nonatomic, strong) dispatch_queue_t internalQueue;

@property (nonatomic, assign) BOOL paused;
@property (nonatomic, strong) ADJBackoffStrategy *backoffStrategy;

@property (nonatomic, weak) id<ADJLogger> logger;
@property (nonatomic, weak) id<ADJActivityHandler> activityHandler;

@end

@implementation ADJSdkClickHandler

#pragma mark - Public class methods

+ (id<ADJSdkClickHandler>)handlerWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                                       startsSending:(BOOL)startsSending {
    return [[ADJSdkClickHandler alloc] initWithActivityHandler:activityHandler
                                                 startsSending:startsSending];
}

#pragma mark - Public instance methods

- (id)initWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                startsSending:(BOOL)startsSending {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.internalQueue = dispatch_queue_create(kInternalQueueName, DISPATCH_QUEUE_SERIAL);
    self.logger = ADJAdjustFactory.logger;
    self.basePath = [activityHandler getBasePath];

    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJSdkClickHandler *selfI) {
                         [selfI initI:selfI
                      activityHandler:activityHandler
                        startsSending:startsSending];
                     }];
    return self;
}

- (void)pauseSending {
    self.paused = YES;
}

- (void)resumeSending {
    self.paused = NO;
    [self sendNextSdkClick];
}

- (void)sendSdkClick:(ADJActivityPackage *)sdkClickPackage {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJSdkClickHandler *selfI) {
                         [selfI sendSdkClickI:selfI sdkClickPackage:sdkClickPackage];
                     }];
}

- (void)sendNextSdkClick {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJSdkClickHandler *selfI) {
                         [selfI sendNextSdkClickI:selfI];
                     }];
}

- (void)teardown {
    [ADJAdjustFactory.logger verbose:@"ADJSdkClickHandler teardown"];

    if (self.packageQueue != nil) {
        [self.packageQueue removeAllObjects];
    }

    self.internalQueue = nil;
    self.logger = nil;
    self.backoffStrategy = nil;
    self.packageQueue = nil;
    self.activityHandler = nil;
}

#pragma mark - Private & helper methods

-   (void)initI:(ADJSdkClickHandler *)selfI
activityHandler:(id<ADJActivityHandler>)activityHandler
  startsSending:(BOOL)startsSending {
    selfI.activityHandler = activityHandler;
    selfI.paused = !startsSending;
    selfI.backoffStrategy = [ADJAdjustFactory sdkClickHandlerBackoffStrategy];
    selfI.packageQueue = [NSMutableArray array];
}

- (void)sendSdkClickI:(ADJSdkClickHandler *)selfI
      sdkClickPackage:(ADJActivityPackage *)sdkClickPackage {
    [selfI.packageQueue addObject:sdkClickPackage];
    [selfI.logger debug:@"Added sdk_click %d", selfI.packageQueue.count];
    [selfI.logger verbose:@"%@", sdkClickPackage.extendedString];
    [selfI sendNextSdkClick];
}

- (void)sendNextSdkClickI:(ADJSdkClickHandler *)selfI {
    if (selfI.paused) {
        return;
    }
    NSUInteger queueSize = selfI.packageQueue.count;
    if (queueSize == 0) {
        return;
    }
    if ([selfI.activityHandler isGdprForgotten]) {
        [selfI.logger debug:@"sdk_click request won't be fired for forgotten user"];
        return;
    }

    ADJActivityPackage *sdkClickPackage = [self.packageQueue objectAtIndex:0];
    [self.packageQueue removeObjectAtIndex:0];

    if (![sdkClickPackage isKindOfClass:[ADJActivityPackage class]]) {
        [selfI.logger error:@"Failed to read sdk_click package"];
        [selfI sendNextSdkClick];
        return;
    }

    NSURL *url;
    NSString *baseUrl = [ADJAdjustFactory baseUrl];
    if (selfI.basePath != nil) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseUrl, selfI.basePath]];
    } else {
        url = [NSURL URLWithString:baseUrl];
    }

    dispatch_block_t work = ^{
        [ADJUtil sendPostRequest:url
                       queueSize:queueSize - 1
              prefixErrorMessage:sdkClickPackage.failureMessage
              suffixErrorMessage:@"Will retry later"
                 activityPackage:sdkClickPackage
             responseDataHandler:^(ADJResponseData *responseData) {
                 // Check if any package response contains information that user has opted out.
                 // If yes, disable SDK and flush any potentially stored packages that happened afterwards.
                 if (responseData.trackingState == ADJTrackingStateOptedOut) {
                     [selfI.activityHandler setTrackingStateOptedOut];
                     return;
                 }
                 if (responseData.jsonResponse == nil) {
                     NSInteger retries = [sdkClickPackage increaseRetries];
                     [selfI.logger error:@"Retrying sdk_click package for the %d time", retries];
                     [selfI sendSdkClick:sdkClickPackage];
                     return;
                 }

                 [selfI.activityHandler finishedTracking:responseData];
             }];

        [selfI sendNextSdkClick];
    };

    NSInteger retries = [sdkClickPackage retries];
    if (retries <= 0) {
        work();
        return;
    }

    NSTimeInterval waitTime = [ADJUtil waitingTime:retries backoffStrategy:self.backoffStrategy];
    NSString *waitTimeFormatted = [ADJUtil secondsNumberFormat:waitTime];

    [self.logger verbose:@"Waiting for %@ seconds before retrying sdk_click for the %d time", waitTimeFormatted, retries];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), self.internalQueue, work);
}

@end
