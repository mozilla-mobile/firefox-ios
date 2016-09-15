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

static NSString   * const kPackageQueueFilename = @"AdjustIoPackageQueue";
static const char * const kInternalQueueName    = "io.adjust.PackageQueue";


#pragma mark - private
@interface ADJPackageHandler()

@property (nonatomic) dispatch_queue_t internalQueue;
@property (nonatomic) dispatch_semaphore_t sendingSemaphore;
@property (nonatomic, assign) id<ADJActivityHandler> activityHandler;
@property (nonatomic, retain) id<ADJRequestHandler> requestHandler;
@property (nonatomic, retain) id<ADJLogger> logger;
@property (nonatomic, retain) NSMutableArray *packageQueue;
@property (nonatomic, assign) BOOL paused;

@end


#pragma mark -
@implementation ADJPackageHandler

+ (id<ADJPackageHandler>)handlerWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                                        startPaused:(BOOL)startPaused {
    return [[ADJPackageHandler alloc] initWithActivityHandler:activityHandler startPaused:startPaused];
}

- (id)initWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                  startPaused:(BOOL)startPaused {
    self = [super init];
    if (self == nil) return nil;

    self.internalQueue = dispatch_queue_create(kInternalQueueName, DISPATCH_QUEUE_SERIAL);

    dispatch_async(self.internalQueue, ^{
        [self initInternal:activityHandler startPaused:startPaused];
    });

    return self;
}

- (void)addPackage:(ADJActivityPackage *)package {
    dispatch_async(self.internalQueue, ^{
        [self addInternal:package];
    });
}

- (void)sendFirstPackage {
    dispatch_async(self.internalQueue, ^{
        [self sendFirstInternal];
    });
}

- (void)sendNextPackage {
    dispatch_async(self.internalQueue, ^{
        [self sendNextInternal];
    });
}

- (void)closeFirstPackage {
    dispatch_semaphore_signal(self.sendingSemaphore);
}

- (void)pauseSending {
    self.paused = YES;
}

- (void)resumeSending {
    self.paused = NO;
}

- (void)finishedTracking:(NSDictionary *)jsonDict{
    [self.activityHandler finishedTracking:jsonDict];
}

#pragma mark - internal
- (void)initInternal:(id<ADJActivityHandler>)activityHandler
         startPaused:(BOOL)startPaused
{
    self.activityHandler = activityHandler;
    self.paused = startPaused;
    self.requestHandler = [ADJAdjustFactory requestHandlerForPackageHandler:self];
    self.logger = ADJAdjustFactory.logger;
    self.sendingSemaphore = dispatch_semaphore_create(1);
    [self readPackageQueue];
}

- (void)addInternal:(ADJActivityPackage *)newPackage {
    if (newPackage.activityKind == ADJActivityKindClick && [self.packageQueue count] > 0) {
        [self.packageQueue insertObject:newPackage atIndex:1];
    } else {
        [self.packageQueue addObject:newPackage];
    }
    [self.logger debug:@"Added package %d (%@)", self.packageQueue.count, newPackage];
    [self.logger verbose:@"%@", newPackage.extendedString];

    [self writePackageQueue];
}

- (void)sendFirstInternal {
    if (self.packageQueue.count == 0) return;

    if (self.paused) {
        [self.logger debug:@"Package handler is paused"];
        return;
    }

    if (dispatch_semaphore_wait(self.sendingSemaphore, DISPATCH_TIME_NOW) != 0) {
        [self.logger verbose:@"Package handler is already sending"];
        return;
    }

    ADJActivityPackage *activityPackage = [self.packageQueue objectAtIndex:0];
    if (![activityPackage isKindOfClass:[ADJActivityPackage class]]) {
        [self.logger error:@"Failed to read activity package"];
        [self sendNextInternal];
        return;
    }

    [self.requestHandler sendPackage:activityPackage];
}

- (void)sendNextInternal {
    [self.packageQueue removeObjectAtIndex:0];
    [self writePackageQueue];
    dispatch_semaphore_signal(self.sendingSemaphore);
    [self sendFirstInternal];
}

#pragma mark - private
- (void)readPackageQueue {
    @try {
        [NSKeyedUnarchiver setClass:[ADJActivityPackage class] forClassName:@"AIActivityPackage"];
        NSString *filename = self.packageQueueFilename;
        id object = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
        if ([object isKindOfClass:[NSArray class]]) {
            self.packageQueue = object;
            [self.logger debug:@"Package handler read %d packages", self.packageQueue.count];
            return;
        } else if (object == nil) {
            [self.logger verbose:@"Package queue file not found"];
        } else {
            [self.logger error:@"Failed to read package queue"];
        }
    } @catch (NSException *exception) {
        [self.logger error:@"Failed to read package queue (%@)", exception];
    }

    // start with a fresh package queue in case of any exception
    self.packageQueue = [NSMutableArray array];
}

- (void)writePackageQueue {
    NSString *filename = self.packageQueueFilename;
    BOOL result = [NSKeyedArchiver archiveRootObject:self.packageQueue toFile:filename];
    if (result == YES) {
        [ADJUtil excludeFromBackup:filename];
        [self.logger debug:@"Package handler wrote %d packages", self.packageQueue.count];
    } else {
        [self.logger error:@"Failed to write package queue"];
    }
}

- (NSString *)packageQueueFilename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filename = [path stringByAppendingPathComponent:kPackageQueueFilename];
    return filename;
}

@end
