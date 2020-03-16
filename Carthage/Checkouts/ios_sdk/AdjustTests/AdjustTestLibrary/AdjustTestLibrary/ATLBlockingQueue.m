//
//  ATLBlockingQueue.m
//  AdjustTestLibrary
//
//  Created by Pedro on 11.01.18.
//  Copyright © 2018 adjust. All rights reserved.
//  Adapted from https://github.com/adamk77/MKBlockingQueue/blob/master/MKBlockingQueue/MKBlockingQueue.m
//

#import "ATLBlockingQueue.h"

@interface ATLBlockingQueue()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSCondition *lock;
@property (nonatomic, strong) NSOperationQueue* operationQueue;

@end

@implementation ATLBlockingQueue

- (id)init
{
    self = [super init];
    if (self)
    {
        self.queue = [[NSMutableArray alloc] init];
        self.lock = [[NSCondition alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        [self.operationQueue setMaxConcurrentOperationCount:1];
    }
    return self;
}

- (void)enqueue:(id)object
{
    [_lock lock];
    [_queue addObject:object];
    [_lock signal];
    [_lock unlock];
}

- (id)dequeue
{
    __block id object;
    [ATLUtil addOperationAfterLast:self.operationQueue blockWithOperation:^(NSBlockOperation * operation) {
        [self.lock lock];
        while (self.queue.count == 0)
        {
            if (operation.cancelled) {
                [self.lock unlock];
                return;
            }
            [self.lock wait];
        }
        if (operation.cancelled) {
            [self.lock unlock];
            return;
        }
        object = [self.queue objectAtIndex:0];
        [self.queue removeObjectAtIndex:0];
        [self.lock unlock];
    }];
    [self.operationQueue waitUntilAllOperationsAreFinished];

    return object;
}

- (void)teardown {
    if (self.lock == nil) {
        return;
    }
    [_lock lock];
    if (self.queue != nil) {
        [self.queue removeAllObjects];
    }
    self.queue = nil;
    if (self.operationQueue != nil) {
        [self.operationQueue cancelAllOperations];
    }
    [_lock unlock];
    self.lock = nil;
}

@end
