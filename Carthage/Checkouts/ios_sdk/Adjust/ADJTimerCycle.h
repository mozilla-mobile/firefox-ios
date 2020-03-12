//
//  ADJTimerCycle.h
//  adjust
//
//  Created by Pedro Filipe on 03/06/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADJTimerCycle : NSObject

+ (ADJTimerCycle *)timerWithBlock:(dispatch_block_t)block
                            queue:(dispatch_queue_t)queue
                        startTime:(NSTimeInterval)startTime
                     intervalTime:(NSTimeInterval)intervalTime
                             name:(NSString*)name;

- (id)initBlock:(dispatch_block_t)block
          queue:(dispatch_queue_t)queue
      startTime:(NSTimeInterval)startTime
   intervalTime:(NSTimeInterval)intervalTime
           name:(NSString*)name;

- (void)resume;
- (void)suspend;
- (void)cancel;
@end
