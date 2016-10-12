//
//  ADJSdkClickHandler.m
//  Adjust
//
//  Created by Pedro Filipe on 21/04/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJSdkClickHandler.h"
#import "ADJLogger.h"
#import "ADJAdjustFactory.h"
#import "ADJBackoffStrategy.h"
#import "ADJUtil.h"

static const char * const kInternalQueueName    = "com.adjust.SdkClickQueue";

#pragma mark - private
@interface ADJSdkClickHandler()

@property (nonatomic, strong) dispatch_queue_t internalQueue;
@property (nonatomic, weak) id<ADJLogger> logger;
@property (nonatomic, strong) ADJBackoffStrategy * backoffStrategy;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, strong) NSMutableArray *packageQueue;
@property (nonatomic, strong) NSURL *baseUrl;

@end

@implementation ADJSdkClickHandler

+ (id<ADJSdkClickHandler>)handlerWithStartsSending:(BOOL)startsSending
{
    return [[ADJSdkClickHandler alloc] initWithStartsSending:startsSending];
}

- (id)initWithStartsSending:(BOOL)startsSending
{
    self = [super init];
    if (self == nil) return nil;

    self.internalQueue = dispatch_queue_create(kInternalQueueName, DISPATCH_QUEUE_SERIAL);

    self.logger = ADJAdjustFactory.logger;
    self.paused = !startsSending;

    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJSdkClickHandler * selfI) {
                         [selfI initI:selfI];
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
                     block:^(ADJSdkClickHandler * selfI) {
                         [selfI sendSdkClickI:selfI sdkClickPackage:sdkClickPackage];
                     }];
}

- (void)sendNextSdkClick {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJSdkClickHandler * selfI) {
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
    self.baseUrl = nil;
}

#pragma mark - internal
- (void)initI:(ADJSdkClickHandler *)selfI
{
    selfI.backoffStrategy = [ADJAdjustFactory sdkClickHandlerBackoffStrategy];
    selfI.packageQueue = [NSMutableArray array];
    selfI.baseUrl = [NSURL URLWithString:ADJUtil.baseUrl];
}

- (void)sendSdkClickI:(ADJSdkClickHandler *)selfI
      sdkClickPackage:(ADJActivityPackage *)sdkClickPackage
{
    [selfI.packageQueue addObject:sdkClickPackage];

    [selfI.logger debug:@"Added sdk_click %d", selfI.packageQueue.count];
    [selfI.logger verbose:@"%@", sdkClickPackage.extendedString];

    [selfI sendNextSdkClick];
}

- (void)sendNextSdkClickI:(ADJSdkClickHandler *)selfI
{
    if (selfI.paused) return;
    NSUInteger queueSize = selfI.packageQueue.count;
    if (queueSize == 0) return;

    ADJActivityPackage *sdkClickPackage = [self.packageQueue objectAtIndex:0];
    [self.packageQueue removeObjectAtIndex:0];

    if (![sdkClickPackage isKindOfClass:[ADJActivityPackage class]]) {
        [selfI.logger error:@"Failed to read sdk_click package"];

        [selfI sendNextSdkClick];

        return;
    }

    dispatch_block_t work = ^{
        [ADJUtil sendPostRequest:selfI.baseUrl
                       queueSize:queueSize - 1
              prefixErrorMessage:sdkClickPackage.failureMessage
              suffixErrorMessage:@"Will retry later"
                 activityPackage:sdkClickPackage
             responseDataHandler:^(ADJResponseData * responseData)
             {
                 if (responseData.jsonResponse == nil) {
                     NSInteger retries = [sdkClickPackage increaseRetries];
                     [selfI.logger error:@"Retrying sdk_click package for the %d time", retries];

                     [selfI sendSdkClick:sdkClickPackage];
                 }
             }];

        [selfI sendNextSdkClick];
    };

    NSInteger retries = [sdkClickPackage retries];

    if (retries <= 0) {
        work();
        return;
    }

    NSTimeInterval waitTime = [ADJUtil waitingTime:retries backoffStrategy:self.backoffStrategy];
    NSString * waitTimeFormatted = [ADJUtil secondsNumberFormat:waitTime];

    [self.logger verbose:@"Waiting for %@ seconds before retrying sdk_click for the %d time", waitTimeFormatted, retries];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), self.internalQueue, work);
}

@end
