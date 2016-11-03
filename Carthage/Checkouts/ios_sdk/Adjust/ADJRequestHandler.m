//
//  ADJRequestHandler.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-04.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJActivityPackage.h"
#import "ADJLogger.h"
#import "ADJUtil.h"
#import "NSString+ADJAdditions.h"
#import "ADJAdjustFactory.h"
#import "ADJActivityKind.h"

static const char * const kInternalQueueName = "io.adjust.RequestQueue";

#pragma mark - private
@interface ADJRequestHandler()

@property (nonatomic, strong) dispatch_queue_t internalQueue;
@property (nonatomic, weak) id<ADJPackageHandler> packageHandler;
@property (nonatomic, weak) id<ADJLogger> logger;
@property (nonatomic, strong) NSURL *baseUrl;

@end

#pragma mark -
@implementation ADJRequestHandler

+ (ADJRequestHandler *)handlerWithPackageHandler:(id<ADJPackageHandler>)packageHandler {
    return [[ADJRequestHandler alloc] initWithPackageHandler:packageHandler];
}

- (id)initWithPackageHandler:(id<ADJPackageHandler>) packageHandler {
    self = [super init];
    if (self == nil) return nil;

    self.internalQueue = dispatch_queue_create(kInternalQueueName, DISPATCH_QUEUE_SERIAL);
    self.packageHandler = packageHandler;
    self.logger = ADJAdjustFactory.logger;
    self.baseUrl = [NSURL URLWithString:ADJUtil.baseUrl];

    return self;
}

- (void)sendPackage:(ADJActivityPackage *)activityPackage
          queueSize:(NSUInteger)queueSize
{
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJRequestHandler* selfI) {
                         [selfI sendI:selfI
                     activityPackage:activityPackage
                           queueSize:queueSize];
                     }];
}

- (void)teardown {
    [ADJAdjustFactory.logger verbose:@"ADJRequestHandler teardown"];

    self.internalQueue = nil;
    self.packageHandler = nil;
    self.logger = nil;
    self.baseUrl = nil;
}

#pragma mark - internal
- (void)sendI:(ADJRequestHandler *)selfI
activityPackage:(ADJActivityPackage *)activityPackage
   queueSize:(NSUInteger)queueSize
{

    [ADJUtil sendPostRequest:selfI.baseUrl
                   queueSize:queueSize
          prefixErrorMessage:activityPackage.failureMessage
          suffixErrorMessage:@"Will retry later"
             activityPackage:activityPackage
         responseDataHandler:^(ADJResponseData * responseData)
    {
        if (responseData.jsonResponse == nil) {
            [selfI.packageHandler closeFirstPackage:responseData activityPackage:activityPackage];
            return;
        }

        [selfI.packageHandler sendNextPackage:responseData];
     }];
}

@end
