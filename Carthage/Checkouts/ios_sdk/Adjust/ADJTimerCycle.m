//
//  ADJTimerCycle.m
//  adjust
//
//  Created by Pedro Filipe on 03/06/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import "ADJTimerCycle.h"

static const uint64_t kTimerLeeway   =  1 * NSEC_PER_SEC; // 1 second

#pragma mark - private
@interface ADJTimerCycle()

@property (nonatomic) dispatch_source_t source;
@property (nonatomic, assign) BOOL suspended;

@end

#pragma mark -
@implementation ADJTimerCycle

+ (ADJTimerCycle *)timerWithBlock:(dispatch_block_t)block
                       queue:(dispatch_queue_t)queue
                   startTime:(NSTimeInterval)startTime
                intervalTime:(NSTimeInterval)intervalTime
{
    return [[ADJTimerCycle alloc] initBlock:block queue:queue startTime:startTime intervalTime:intervalTime];
}

- (id)initBlock:(dispatch_block_t)block
          queue:(dispatch_queue_t)queue
      startTime:(NSTimeInterval)startTime
   intervalTime:(NSTimeInterval)intervalTime
{
    self = [super init];
    if (self == nil) return nil;

    self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

    dispatch_source_set_timer(self.source,
                              dispatch_walltime(NULL, startTime * NSEC_PER_SEC),
                              intervalTime * NSEC_PER_SEC,
                              kTimerLeeway);

    dispatch_source_set_event_handler(self.source, block);

    self.suspended = YES;

    return self;
}

- (void)resume {
    if (!self.suspended) return;

    dispatch_resume(self.source);
    self.suspended = NO;
}

- (void)suspend {
    if (self.suspended) return;

    dispatch_suspend(self.source);
    self.suspended = YES;
}

@end
