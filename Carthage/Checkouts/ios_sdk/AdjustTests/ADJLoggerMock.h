//
//  ADJLoggerMock.h
//  Adjust
//
//  Created by Pedro Filipe on 10/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJLogger.h"

static const int ADJLogLevelTest = 7;
static const int ADJLogLevelCheck = 8;

@interface ADJLoggerMock : NSObject <ADJLogger>
- (void)test:(NSString *)message, ...;
- (BOOL)deleteUntil:(NSInteger)logLevel beginsWith:(NSString *)beginsWith;
- (void)reset;

@end
