//
//  SentryBreadcrumbStore.h
//  Sentry
//
//  Created by Daniel Griesser on 22/05/2017.
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

@class SentryBreadcrumb, SentryFileManager;

NS_SWIFT_NAME(BreadcrumbStore)
@interface SentryBreadcrumbStore : NSObject <SentrySerializable>
SENTRY_NO_INIT

/*
 * This property defines how many breadcrumbs should be stored.
 * Change this to reflect you needs.
 */
@property(nonatomic, assign) NSUInteger maxBreadcrumbs;

/**
 * Init SentryBreadcrumbStore, should only be used internally
 *
 * @param fileManager SentryFileManager
 * @return SentryBreadcrumbStore
 */
- (instancetype)initWithFileManager:(SentryFileManager *)fileManager;

/**
 * Add a SentryBreadcrumb to the store
 * @param crumb SentryBreadcrumb
 */
- (void)addBreadcrumb:(SentryBreadcrumb *)crumb;

/**
 * Deletes all stored SentryBreadcrumbs
 */
- (void)clear;

/**
 * Returns the number of stored SentryBreadcrumbs
 * This number can be higher than maxBreadcrumbs since we
 * only remove breadcrumbs over the limit once we sent them
 * @return number of SentryBreadcrumb
 */
- (NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
