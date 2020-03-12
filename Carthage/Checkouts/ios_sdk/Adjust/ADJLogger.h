//
//  ADJLogger.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2012-11-15.
//  Copyright (c) 2012-2014 adjust GmbH. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef enum {
    ADJLogLevelVerbose  = 1,
    ADJLogLevelDebug    = 2,
    ADJLogLevelInfo     = 3,
    ADJLogLevelWarn     = 4,
    ADJLogLevelError    = 5,
    ADJLogLevelAssert   = 6,
    ADJLogLevelSuppress = 7
} ADJLogLevel;

/**
 * @brief Adjust logger protocol.
 */
@protocol ADJLogger

/**
 * @brief Set the log level of the SDK.
 *
 * @param logLevel Level of the logs to be displayed.
 */
- (void)setLogLevel:(ADJLogLevel)logLevel isProductionEnvironment:(BOOL)isProductionEnvironment;

/**
 * @brief Prevent log level changes.
 */
- (void)lockLogLevel;

/**
 * @brief Print verbose logs.
 */
- (void)verbose:(nonnull NSString *)message, ...;

/**
 * @brief Print debug logs.
 */
- (void)debug:(nonnull NSString *)message, ...;

/**
 * @brief Print info logs.
 */
- (void)info:(nonnull NSString *)message, ...;

/**
 * @brief Print warn logs.
 */
- (void)warn:(nonnull NSString *)message, ...;
- (void)warnInProduction:(nonnull NSString *)message, ...;

/**
 * @brief Print error logs.
 */
- (void)error:(nonnull NSString *)message, ...;

/**
 * @brief Print assert logs.
 */
- (void)assert:(nonnull NSString *)message, ...;

@end

/**
 * @brief Adjust logger class.
 */
@interface ADJLogger : NSObject<ADJLogger>

/**
 * @brief Convert log level string to ADJLogLevel enumeration.
 *
 * @param logLevelString Log level as string.
 *
 * @return Log level as ADJLogLevel enumeration.
 */
+ (ADJLogLevel)logLevelFromString:(nonnull NSString *)logLevelString;

@end
