//
//  SentryFileManager.h
//  Sentry
//
//  Created by Daniel Griesser on 23/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)
#import <Sentry/SentryDefines.h>
#else
#import "SentryDefines.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class SentryEvent, SentryBreadcrumb, SentryDsn;

@interface SentryFileManager : NSObject
SENTRY_NO_INIT

- (_Nullable instancetype)initWithDsn:(SentryDsn *)dsn didFailWithError:(NSError **)error;

- (NSString *)storeEvent:(SentryEvent *)event;

- (NSString *)storeBreadcrumb:(SentryBreadcrumb *)crumb;
- (NSString *)storeBreadcrumb:(SentryBreadcrumb *)crumb maxCount:(NSUInteger)maxCount;

+ (BOOL)createDirectoryAtPath:(NSString *)path withError:(NSError **)error;

- (void)deleteAllStoredEvents;

- (void)deleteAllStoredBreadcrumbs;

- (void)deleteAllFolders;

- (NSArray<NSDictionary<NSString *, id> *> *)getAllStoredEvents;

- (NSArray<NSDictionary<NSString *, id> *> *)getAllStoredBreadcrumbs;

- (BOOL)removeFileAtPath:(NSString *)path;

- (NSArray<NSString *> *)allFilesInFolder:(NSString *)path;

- (NSString *)storeDictionary:(NSDictionary *)dictionary toPath:(NSString *)path;

@property(nonatomic, assign) NSUInteger maxEvents;
@property(nonatomic, assign) NSUInteger maxBreadcrumbs;

@end

NS_ASSUME_NONNULL_END
