//
//  ADJAttributionHandler.m
//  adjust
//
//  Created by Pedro Filipe on 29/10/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJAttributionHandler.h"
#import "ADJAdjustFactory.h"
#import "ADJUtil.h"
#import "ADJActivityHandler.h"
#import "NSString+ADJAdditions.h"
#import "ADJTimerOnce.h"

static const char * const kInternalQueueName     = "com.adjust.AttributionQueue";
static NSString   * const kAttributionTimerName   = @"Attribution timer";

@interface ADJAttributionHandler()

@property (nonatomic, strong) dispatch_queue_t internalQueue;
@property (nonatomic, weak) id<ADJActivityHandler> activityHandler;
@property (nonatomic, weak) id<ADJLogger> logger;
@property (nonatomic, strong) ADJTimerOnce *attributionTimer;
@property (nonatomic, strong) ADJActivityPackage * attributionPackage;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL hasNeedsResponseDelegate;

@end

static const double kRequestTimeout = 60; // 60 seconds

@implementation ADJAttributionHandler

+ (id<ADJAttributionHandler>)handlerWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                                 withAttributionPackage:(ADJActivityPackage *) attributionPackage
                                          startsSending:(BOOL)startsSending
                          hasAttributionChangedDelegate:(BOOL)hasAttributionChangedDelegate;
{
    return [[ADJAttributionHandler alloc] initWithActivityHandler:activityHandler
                                           withAttributionPackage:attributionPackage
                                                    startsSending:startsSending
                                    hasAttributionChangedDelegate:hasAttributionChangedDelegate];
}

- (id)initWithActivityHandler:(id<ADJActivityHandler>) activityHandler
       withAttributionPackage:(ADJActivityPackage *) attributionPackage
                startsSending:(BOOL)startsSending
hasAttributionChangedDelegate:(BOOL)hasAttributionChangedDelegate;
{
    self = [super init];
    if (self == nil) return nil;

    self.internalQueue = dispatch_queue_create(kInternalQueueName, DISPATCH_QUEUE_SERIAL);
    self.activityHandler = activityHandler;
    self.logger = ADJAdjustFactory.logger;
    self.attributionPackage = attributionPackage;
    self.paused = !startsSending;
    self.hasNeedsResponseDelegate = hasAttributionChangedDelegate;
    __weak __typeof__(self) weakSelf = self;
    self.attributionTimer = [ADJTimerOnce timerWithBlock:^{
        __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) return;

        [strongSelf requestAttributionI:strongSelf];
    }
                                                   queue:self.internalQueue
                                                    name:kAttributionTimerName];

    return self;
}

- (void)checkSessionResponse:(ADJSessionResponseData *)sessionResponseData {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJAttributionHandler* selfI) {
                         [selfI checkSessionResponseI:selfI
                                  sessionResponseData:sessionResponseData];
                     }];
}

- (void)checkAttributionResponse:(ADJAttributionResponseData *)attributionResponseData {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJAttributionHandler* selfI) {
                         [selfI checkAttributionResponseI:selfI
                                  attributionResponseData:attributionResponseData];

                     }];
}

- (void)getAttribution {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJAttributionHandler* selfI) {
                         [selfI waitRequestAttributionWithDelayI:selfI
                                               milliSecondsDelay:0];

                     }];
}

- (void)pauseSending {
    self.paused = YES;
}

- (void)resumeSending {
    self.paused = NO;
}

#pragma mark - internal
- (void)checkSessionResponseI:(ADJAttributionHandler*)selfI
          sessionResponseData:(ADJSessionResponseData *)sessionResponseData {
    [selfI checkAttributionI:selfI responseData:sessionResponseData];

    [selfI.activityHandler launchSessionResponseTasks:sessionResponseData];
}

- (void)checkAttributionResponseI:(ADJAttributionHandler*)selfI
                  attributionResponseData:(ADJAttributionResponseData *)attributionResponseData {
    [selfI checkAttributionI:selfI responseData:attributionResponseData];

    [selfI checkDeeplinkI:selfI attributionResponseData:attributionResponseData];

    [selfI.activityHandler launchAttributionResponseTasks:attributionResponseData];
}

- (void)checkAttributionI:(ADJAttributionHandler*)selfI
             responseData:(ADJResponseData *)responseData {
    if (responseData.jsonResponse == nil) {
        return;
    }

    NSNumber *timerMilliseconds = [responseData.jsonResponse objectForKey:@"ask_in"];

    if (timerMilliseconds != nil) {
        [selfI.activityHandler setAskingAttribution:YES];

        [selfI waitRequestAttributionWithDelayI:selfI
                              milliSecondsDelay:[timerMilliseconds intValue]];

        return;
    }

    [selfI.activityHandler setAskingAttribution:NO];

    NSDictionary * jsonAttribution = [responseData.jsonResponse objectForKey:@"attribution"];
    responseData.attribution = [ADJAttribution dataWithJsonDict:jsonAttribution];
}

- (void)checkDeeplinkI:(ADJAttributionHandler*)selfI
attributionResponseData:(ADJAttributionResponseData *)attributionResponseData {
    if (attributionResponseData.jsonResponse == nil) {
        return;
    }

    NSDictionary * jsonAttribution = [attributionResponseData.jsonResponse objectForKey:@"attribution"];
    if (jsonAttribution == nil) {
        return;
    }

    NSString *deepLink = [jsonAttribution objectForKey:@"deeplink"];
    if (deepLink == nil) {
        return;
    }

    attributionResponseData.deeplink = [NSURL URLWithString:deepLink];
}

- (void)requestAttributionI:(ADJAttributionHandler*)selfI {
    if (!selfI.hasNeedsResponseDelegate) {
        return;
    }
    if (selfI.paused) {
        [selfI.logger debug:@"Attribution handler is paused"];
        return;
    }
    [selfI.logger verbose:@"%@", selfI.attributionPackage.extendedString];

    [ADJUtil sendRequest:[selfI requestI:selfI]
      prefixErrorMessage:@"Failed to get attribution"
         activityPackage:selfI.attributionPackage
     responseDataHandler:^(ADJResponseData * responseData)
    {
        if ([responseData isKindOfClass:[ADJAttributionResponseData class]]) {
            [selfI checkAttributionResponse:(ADJAttributionResponseData*)responseData];
        }
    }];
}

- (void)waitRequestAttributionWithDelayI:(ADJAttributionHandler*)selfI
                       milliSecondsDelay:(int)milliSecondsDelay
{
    NSTimeInterval secondsDelay = milliSecondsDelay / 1000;
    NSTimeInterval nextAskIn = [selfI.attributionTimer fireIn];
    if (nextAskIn > secondsDelay) {
        return;
    }

    if (milliSecondsDelay > 0) {
        [selfI.logger debug:@"Waiting to query attribution in %d milliseconds", milliSecondsDelay];
    }

    // set the new time the timer will fire in
    [selfI.attributionTimer startIn:secondsDelay];
}

#pragma mark - private

- (NSMutableURLRequest *)requestI:(ADJAttributionHandler*)selfI {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[selfI urlI:selfI]];
    request.timeoutInterval = kRequestTimeout;
    request.HTTPMethod = @"GET";

    [request setValue:selfI.attributionPackage.clientSdk forHTTPHeaderField:@"Client-Sdk"];

    return request;
}

- (NSURL *)urlI:(ADJAttributionHandler*)selfI {
    NSString *parameters = [ADJUtil queryString:selfI.attributionPackage.parameters];
    NSString *relativePath = [NSString stringWithFormat:@"%@?%@", selfI.attributionPackage.path, parameters];
    NSURL *baseUrl = [NSURL URLWithString:ADJUtil.baseUrl];
    NSURL *url = [NSURL URLWithString:relativePath relativeToURL:baseUrl];
    
    return url;
}

- (void)teardown {
    [ADJAdjustFactory.logger verbose:@"ADJAttributionHandler teardown"];

    if (self.attributionTimer != nil) {
        [self.attributionTimer cancel];
    }
    self.internalQueue = nil;
    self.activityHandler = nil;
    self.logger = nil;
    self.attributionTimer = nil;
    self.attributionPackage = nil;
}

@end
