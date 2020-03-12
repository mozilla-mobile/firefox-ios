//
//  SentryAsynchronousOperation.h
//  Sentry
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryAsynchronousOperation : NSOperation

- (void)completeOperation;

@end

NS_ASSUME_NONNULL_END
