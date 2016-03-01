//
//  ADJLogger.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2012-11-15.
//  Copyright (c) 2012-2014 adjust GmbH. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef enum {
    ADJLogLevelVerbose = 1,
    ADJLogLevelDebug   = 2,
    ADJLogLevelInfo    = 3,
    ADJLogLevelWarn    = 4,
    ADJLogLevelError   = 5,
    ADJLogLevelAssert  = 6
} ADJLogLevel;

// A simple logger with multiple log levels.
@protocol ADJLogger

- (void)setLogLevel:(ADJLogLevel)logLevel;

- (void)verbose:(NSString *)message, ...;
- (void)debug:  (NSString *)message, ...;
- (void)info:   (NSString *)message, ...;
- (void)warn:   (NSString *)message, ...;
- (void)error:  (NSString *)message, ...;
- (void)assert: (NSString *)message, ...;

@end

@interface ADJLogger : NSObject <ADJLogger>

+ (ADJLogLevel) LogLevelFromString: (NSString *) logLevelString;

@end
