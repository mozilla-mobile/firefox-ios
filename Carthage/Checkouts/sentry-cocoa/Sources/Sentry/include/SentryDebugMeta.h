//
//  SentryDebugMeta.h
//  Sentry
//
//  Created by Daniel Griesser on 10/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)
#import <Sentry/SentrySerializable.h>
#else
#import "SentrySerializable.h"
#endif

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DebugMeta)
@interface SentryDebugMeta : NSObject <SentrySerializable>

/**
 * UUID of image
 */
@property(nonatomic, copy) NSString *_Nullable uuid;

/**
 * Type of debug meta, mostly just apple
 */
@property(nonatomic, copy) NSString *_Nullable type;

/**
 * CPU type of image
 */
@property(nonatomic, copy) NSNumber *_Nullable cpuType;

/**
 * CPU Sub type of image
 */
@property(nonatomic, copy) NSNumber *_Nullable cpuSubType;

/**
 * Name of the image
 */
@property(nonatomic, copy) NSString *_Nullable name;

/**
 * Image size
 */
@property(nonatomic, copy) NSNumber *_Nullable imageSize;

/**
 * Image VM address
 */
@property(nonatomic, copy) NSString *_Nullable imageVmAddress;

/**
 * Image address
 */
@property(nonatomic, copy) NSString *_Nullable imageAddress;

/**
 * Major version of the image
 */
@property(nonatomic, copy) NSNumber *_Nullable majorVersion;

/**
 * Minor version of the image
 */
@property(nonatomic, copy) NSNumber *_Nullable minorVersion;

/**
 * Revision version of the image
 */
@property(nonatomic, copy) NSNumber *_Nullable revisionVersion;

- (instancetype)init;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
