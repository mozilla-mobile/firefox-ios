//
//  SentryOptions.h
//  Sentry
//
//  Created by Daniel Griesser on 12.03.19.
//  Copyright © 2019 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)
#import <Sentry/SentryDefines.h>
#else
#import "SentryDefines.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class SentryDsn;

NS_SWIFT_NAME(Options)
@interface SentryOptions : NSObject
SENTRY_NO_INIT

    
/**
 * Init SentryOptions.
 * @param options Options dictionary
 * @return SentryOptions
 */
- (_Nullable instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options
                         didFailWithError:(NSError *_Nullable *_Nullable)error;
    
/**
 * The Dsn passed in the options.
 */
@property(nonatomic, strong) SentryDsn *dsn;

/**
 * This property will be filled before the event is sent.
 */
@property(nonatomic, copy) NSString *_Nullable releaseName;

/**
 * This property will be filled before the event is sent.
 */
@property(nonatomic, copy) NSString *_Nullable dist;

/**
 * The environment used for this event
 */
@property(nonatomic, copy) NSString *_Nullable environment;
    
/**
 * Is the client enabled?. Default is @YES, if set @NO sending of events will be prevented.
 */
@property(nonatomic, copy) NSNumber *enabled;

@end

NS_ASSUME_NONNULL_END
