//
//  ADJTimerOnce.h
//  adjust
//
//  Created by Pedro Filipe on 03/06/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ADJTimerOnce : NSObject

+ (ADJTimerOnce *)timerWithBlock:(dispatch_block_t)block
                           queue:(dispatch_queue_t)queue
                            name:(NSString*)name;

- (id)initBlock:(dispatch_block_t)block
          queue:(dispatch_queue_t)queue
           name:(NSString*)name;

- (void)startIn:(NSTimeInterval)startIn;
- (NSTimeInterval)fireIn;
- (void)cancel;
@end
