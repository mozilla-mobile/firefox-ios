//
//  SentryUser.h
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

NS_SWIFT_NAME(User)
@interface SentryUser : NSObject <SentrySerializable>

/**
 * Optional: Id of the user
 */
@property(nonatomic, copy) NSString *userId;

/**
 * Optional: Email of the user
 */
@property(nonatomic, copy) NSString *_Nullable email;

/**
 * Optional: Username
 */
@property(nonatomic, copy) NSString *_Nullable username;

/**
 * Optional: Additional data
 */
@property(nonatomic, strong) NSDictionary<NSString *, id> *_Nullable extra;

/**
 * Initializes a SentryUser with the id
 * @param userId NSString
 * @return SentryUser
 */
- (instancetype)initWithUserId:(NSString *)userId;

- (instancetype)init;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
