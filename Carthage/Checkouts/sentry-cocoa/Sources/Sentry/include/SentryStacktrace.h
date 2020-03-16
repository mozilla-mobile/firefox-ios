//
//  SentryStacktrace.h
//  Sentry
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)
#import <Sentry/SentryDefines.h>
#import <Sentry/SentrySerializable.h>
#else
#import "SentryDefines.h"
#import "SentrySerializable.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class SentryFrame;

NS_SWIFT_NAME(Stacktrace)
@interface SentryStacktrace : NSObject <SentrySerializable>
SENTRY_NO_INIT

/**
 * Array of all SentryFrame in the stacktrace
 */
@property(nonatomic, strong) NSArray<SentryFrame *> *frames;

/**
 * Registers of the thread for additional information used on the server
 */
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *registers;

/**
 * Initialize a SentryStacktrace with frames and registers
 * @param frames NSArray
 * @param registers NSArray
 * @return SentryStacktrace
 */
- (instancetype)initWithFrames:(NSArray<SentryFrame *> *)frames
                     registers:(NSDictionary<NSString *, NSString *> *)registers;

/**
 * This will be called internally, is used to remove duplicated frames for certain crashes.
 */
- (void)fixDuplicateFrames;

@end

NS_ASSUME_NONNULL_END
