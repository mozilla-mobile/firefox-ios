//
//  ADJTimerOnce.m
//  adjust
//
//  Created by Pedro Filipe on 03/06/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import "ADJTimerOnce.h"
#import "ADJLogger.h"
#import "ADJAdjustFactory.h"
#import "ADJUtil.h"

static const uint64_t kTimerLeeway   =  1 * NSEC_PER_SEC; // 1 second

#pragma mark - private
@interface ADJTimerOnce()

@property (nonatomic, strong) dispatch_queue_t internalQueue;
@property (nonatomic, strong) dispatch_source_t source;
@property (nonatomic, copy) dispatch_block_t block;
@property (nonatomic, assign, readonly) dispatch_time_t start;
@property (nonatomic, strong) NSDate * fireDate;
@property (nonatomic, weak) id<ADJLogger> logger;
@property (nonatomic, copy) NSString *name;

@end

#pragma mark -
@implementation ADJTimerOnce

+ (ADJTimerOnce *)timerWithBlock:(dispatch_block_t)block
                       queue:(dispatch_queue_t)queue
                            name:(NSString*)name
{
    return [[ADJTimerOnce alloc] initBlock:block queue:queue name:name];
}

- (id)initBlock:(dispatch_block_t)block
          queue:(dispatch_queue_t)queue
           name:(NSString*)name
{
    self = [super init];
    if (self == nil) return nil;

    self.internalQueue = queue;
    self.logger = ADJAdjustFactory.logger;
    self.name = name;

    self.block = ^{
        [ADJAdjustFactory.logger verbose:@"%@ fired", name];
        block();
    };

    return self;
}

- (NSTimeInterval)fireIn {
    if (self.fireDate == nil) {
        return 0;
    }
    return [self.fireDate timeIntervalSinceNow];
}

- (void)startIn:(NSTimeInterval)startIn {
    // cancel previous
    [self cancel:NO];

    self.fireDate = [[NSDate alloc] initWithTimeIntervalSinceNow:startIn];
    NSString * fireInFormatted = [ADJUtil secondsNumberFormat:[self fireIn]];
    [self.logger verbose:@"%@ starting. Launching in %@ seconds", self.name, fireInFormatted];

    self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.internalQueue);

    dispatch_source_set_timer(self.source,
                              dispatch_walltime(NULL, startIn * NSEC_PER_SEC),
                              DISPATCH_TIME_FOREVER,
                              kTimerLeeway);


    dispatch_resume(self.source);

    dispatch_source_set_event_handler(self.source, self.block);
}

- (void)cancel:(BOOL)log {
    if (self.source != nil) {
        dispatch_cancel(self.source);
    }
    self.source = nil;
    if (log) {
        [self.logger verbose:@"%@ canceled", self.name];
    }
}

- (void)cancel {
    [self cancel:YES];
}

- (void)dealloc {
    [self.logger verbose:@"%@ dealloc", self.name];
}

@end
