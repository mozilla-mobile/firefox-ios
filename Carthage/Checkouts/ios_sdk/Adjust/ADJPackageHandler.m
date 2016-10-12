//
//  ADJPackageHandler.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-03.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJRequestHandler.h"
#import "ADJActivityPackage.h"
#import "ADJLogger.h"
#import "ADJUtil.h"
#import "ADJAdjustFactory.h"
#import "ADJBackoffStrategy.h"
#import "ADJPackageBuilder.h"

static NSString   * const kPackageQueueFilename = @"AdjustIoPackageQueue";
static const char * const kInternalQueueName    = "io.adjust.PackageQueue";


#pragma mark - private
@interface ADJPackageHandler()

@property (nonatomic, strong) dispatch_queue_t internalQueue;
@property (nonatomic, strong) dispatch_semaphore_t sendingSemaphore;
@property (nonatomic, strong) id<ADJRequestHandler> requestHandler;
@property (nonatomic, strong) NSMutableArray *packageQueue;
@property (nonatomic, strong) ADJBackoffStrategy * backoffStrategy;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, weak) id<ADJActivityHandler> activityHandler;
@property (nonatomic, weak) id<ADJLogger> logger;

@end

#pragma mark -
@implementation ADJPackageHandler

+ (id<ADJPackageHandler>)handlerWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                                      startsSending:(BOOL)startsSending
{
    return [[ADJPackageHandler alloc] initWithActivityHandler:activityHandler startsSending:startsSending];
}

- (id)initWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                startsSending:(BOOL)startsSending
{
    self = [super init];
    if (self == nil) return nil;

    self.internalQueue = dispatch_queue_create(kInternalQueueName, DISPATCH_QUEUE_SERIAL);
    self.backoffStrategy = [ADJAdjustFactory packageHandlerBackoffStrategy];

    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJPackageHandler * selfI) {
                         [selfI initI:selfI
                     activityHandler:activityHandler
                       startsSending:startsSending];
                     }];

    return self;
}

- (void)addPackage:(ADJActivityPackage *)package {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJPackageHandler* selfI) {
                         [selfI addI:selfI package:package];
                     }];
}

- (void)sendFirstPackage {
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJPackageHandler* selfI) {
                         [selfI sendFirstI:selfI];
                     }];
}

- (void)sendNextPackage:(ADJResponseData *)responseData{
    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJPackageHandler* selfI) {
                         [selfI sendNextI:selfI];
                     }];

    [self.activityHandler finishedTracking:responseData];
}

- (void)closeFirstPackage:(ADJResponseData *)responseData
          activityPackage:(ADJActivityPackage *)activityPackage
{
    responseData.willRetry = YES;
    [self.activityHandler finishedTracking:responseData];

    dispatch_block_t work = ^{
        [self.logger verbose:@"Package handler can send"];
        dispatch_semaphore_signal(self.sendingSemaphore);

        [self sendFirstPackage];
    };

    if (activityPackage == nil) {
        work();
        return;
    }

    NSInteger retries = [activityPackage increaseRetries];
    NSTimeInterval waitTime = [ADJUtil waitingTime:retries backoffStrategy:self.backoffStrategy];
    NSString * waitTimeFormatted = [ADJUtil secondsNumberFormat:waitTime];

    [self.logger verbose:@"Waiting for %@ seconds before retrying the %d time", waitTimeFormatted, retries];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), self.internalQueue, work);
}

- (void)pauseSending {
    self.paused = YES;
}

- (void)resumeSending {
    self.paused = NO;
}

- (void)updatePackages:(ADJSessionParameters *)sessionParameters
{
    // make copy to prevent possible Activity Handler changes of it
    ADJSessionParameters * sessionParametersCopy = [sessionParameters copy];

    [ADJUtil launchInQueue:self.internalQueue
                selfInject:self
                     block:^(ADJPackageHandler* selfI) {
                         [selfI updatePackagesI:selfI sessionParameters:sessionParametersCopy];
                     }];
}

- (void)teardown:(BOOL)deleteState {
    [ADJAdjustFactory.logger verbose:@"ADJPackageHandler teardown"];
    if (self.sendingSemaphore != nil) {
        dispatch_semaphore_signal(self.sendingSemaphore);
    }
    if (self.requestHandler != nil) {
        [self.requestHandler teardown];
    }
    [self teardownPackageQueueS:deleteState];
    self.internalQueue = nil;
    self.sendingSemaphore = nil;
    self.requestHandler = nil;
    self.backoffStrategy = nil;
    self.activityHandler = nil;
    self.logger = nil;
}

#pragma mark - internal
- (void)initI:(ADJPackageHandler *)selfI
activityHandler:(id<ADJActivityHandler>)activityHandler
startsSending:(BOOL)startsSending
{
    selfI.activityHandler = activityHandler;
    selfI.paused = !startsSending;
    selfI.requestHandler = [ADJAdjustFactory requestHandlerForPackageHandler:selfI];
    selfI.logger = ADJAdjustFactory.logger;
    selfI.sendingSemaphore = dispatch_semaphore_create(1);
    [selfI readPackageQueueI:selfI];
}

- (void)addI:(ADJPackageHandler *)selfI
     package:(ADJActivityPackage *)newPackage
{
    [selfI.packageQueue addObject:newPackage];
    [selfI.logger debug:@"Added package %d (%@)", selfI.packageQueue.count, newPackage];
    [selfI.logger verbose:@"%@", newPackage.extendedString];

    [selfI writePackageQueueS:selfI];
}

- (void)sendFirstI:(ADJPackageHandler *)selfI
{
    NSUInteger queueSize = selfI.packageQueue.count;
    if (queueSize == 0) return;

    if (selfI.paused) {
        [selfI.logger debug:@"Package handler is paused"];
        return;
    }

    if (dispatch_semaphore_wait(selfI.sendingSemaphore, DISPATCH_TIME_NOW) != 0) {
        [selfI.logger verbose:@"Package handler is already sending"];
        return;
    }

    ADJActivityPackage *activityPackage = [selfI.packageQueue objectAtIndex:0];
    if (![activityPackage isKindOfClass:[ADJActivityPackage class]]) {
        [selfI.logger error:@"Failed to read activity package"];
        [selfI sendNextI:selfI];
        return;
    }

    [selfI.requestHandler sendPackage:activityPackage
                            queueSize:queueSize - 1];
}

- (void)sendNextI:(ADJPackageHandler *)selfI {
    [selfI.packageQueue removeObjectAtIndex:0];
    [selfI writePackageQueueS:selfI];
    dispatch_semaphore_signal(selfI.sendingSemaphore);
    [selfI sendFirstI:selfI];
}

- (void)updatePackagesI:(ADJPackageHandler *)selfI
      sessionParameters:(ADJSessionParameters *)sessionParameters
{
    [selfI.logger debug:@"Updating package handler queue"];
    [selfI.logger verbose:@"Session callback parameters: %@", sessionParameters.callbackParameters];
    [selfI.logger verbose:@"Session partner parameters: %@", sessionParameters.partnerParameters];

    for (ADJActivityPackage * activityPackage in selfI.packageQueue) {
        // callback parameters
        NSDictionary * mergedCallbackParameters = [ADJUtil mergeParameters:sessionParameters.callbackParameters
                                                                    source:activityPackage.callbackParameters
                                                             parameterName:@"Callback"];

        [ADJPackageBuilder parameters:activityPackage.parameters
                        setDictionary:mergedCallbackParameters
                               forKey:@"callback_params"];

        // partner parameters
        NSDictionary * mergedPartnerParameters = [ADJUtil mergeParameters:sessionParameters.partnerParameters
                                                                   source:activityPackage.partnerParameters
                                                            parameterName:@"Partner"];

        [ADJPackageBuilder parameters:activityPackage.parameters
                        setDictionary:mergedPartnerParameters
                               forKey:@"partner_params"];
    }

    [selfI writePackageQueueS:selfI];
}

#pragma mark - private
- (void)readPackageQueueI:(ADJPackageHandler *)selfI {
    @try {
        [NSKeyedUnarchiver setClass:[ADJActivityPackage class] forClassName:@"AIActivityPackage"];
        NSString *filename = selfI.packageQueueFilename;
        id object = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
        if ([object isKindOfClass:[NSArray class]]) {
            selfI.packageQueue = object;
            [selfI.logger debug:@"Package handler read %d packages", selfI.packageQueue.count];
            return;
        } else if (object == nil) {
            [selfI.logger verbose:@"Package queue file not found"];
        } else {
            [selfI.logger error:@"Failed to read package queue"];
        }
    } @catch (NSException *exception) {
        [selfI.logger error:@"Failed to read package queue (%@)", exception];
    }

    // start with a fresh package queue in case of any exception
    selfI.packageQueue = [NSMutableArray array];
}

- (void)writePackageQueueS:(ADJPackageHandler *)selfS {
    @synchronized ([ADJPackageHandler class]) {
        if (selfS.packageQueue == nil) {
            return;
        }
        NSString *filename = selfS.packageQueueFilename;
        BOOL result = [NSKeyedArchiver archiveRootObject:selfS.packageQueue toFile:filename];
        if (result == YES) {
            [ADJUtil excludeFromBackup:filename];
            [selfS.logger debug:@"Package handler wrote %d packages", selfS.packageQueue.count];
        } else {
            [selfS.logger error:@"Failed to write package queue"];
        }
    }
}

- (void)teardownPackageQueueS:(BOOL)deleteState
{
    @synchronized ([ADJPackageHandler class]) {
        if (self.packageQueue == nil) {
            return;
        }
        if (deleteState) {
            [ADJUtil deleteFile:self.packageQueueFilename];
        }
        [self.packageQueue removeAllObjects];

        self.packageQueue = nil;
    }
}

- (NSString *)packageQueueFilename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filename = [path stringByAppendingPathComponent:kPackageQueueFilename];
    return filename;
}

-(void)dealloc {
    //cleanup code
    if (self.sendingSemaphore != nil) {
        dispatch_semaphore_signal(self.sendingSemaphore);
    }
}

@end
