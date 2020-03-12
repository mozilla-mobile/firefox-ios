//
//  ATLBlockingQueue.h
//  AdjustTestLibrary
//
//  Created by Pedro on 11.01.18.
//  Copyright © 2018 adjust. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATLUtil.h"

@interface ATLBlockingQueue : NSObject

/**
 * Enqueues an object to the queue.
 * @param object Object to enqueue
 */
- (void)enqueue:(id)object;

/**
 * Dequeues an object from the queue.  This method will block.
 */
- (id)dequeue;

- (void)teardown;

@end
