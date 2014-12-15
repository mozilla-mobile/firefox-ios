//
//  NSManagedObjectContext+MagicalThreading.m
//  Magical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "NSManagedObjectContext+MagicalThreading.h"
#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#include <libkern/OSAtomic.h>

static NSString const * kMagicalRecordManagedObjectContextKey = @"MagicalRecord_NSManagedObjectContextForThreadKey";
static NSString const * kMagicalRecordManagedObjectContextCacheVersionKey = @"MagicalRecord_CacheVersionOfNSManagedObjectContextForThreadKey";
static volatile int32_t contextsCacheVersion = 0;


@implementation NSManagedObjectContext (MagicalThreading)

+ (void)MR_resetContextForCurrentThread
{
    [[NSManagedObjectContext MR_contextForCurrentThread] reset];
}

+ (void) MR_clearNonMainThreadContextsCache
{
	OSAtomicIncrement32(&contextsCacheVersion);
}

+ (NSManagedObjectContext *) MR_contextForCurrentThread;
{
	if ([NSThread isMainThread])
	{
		return [self MR_defaultContext];
	}
	else
	{
		// contextsCacheVersion can change (atomically) at any time, so grab a copy to ensure that we always
		// use the same value throughout the remainder of this method. We are OK with this method returning
		// an outdated context if MR_clearNonMainThreadContextsCache is called from another thread while this
		// method is being executed. This behavior is unrelated to our choice to use a counter for synchronization.
		// We would have the same behavior if we used @synchronized() (or any other lock-based synchronization
		// method) since MR_clearNonMainThreadContextsCache would have to wait until this method finished before
		// it could acquire the mutex, resulting in us still returning an outdated context in that case as well.
		int32_t targetCacheVersionForContext = contextsCacheVersion;

		NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
		NSManagedObjectContext *threadContext = [threadDict objectForKey:kMagicalRecordManagedObjectContextKey];
		NSNumber *currentCacheVersionForContext = [threadDict objectForKey:kMagicalRecordManagedObjectContextCacheVersionKey];
		NSAssert((threadContext && currentCacheVersionForContext) || (!threadContext && !currentCacheVersionForContext),
                 @"The Magical Record keys should either both be present or neither be present, otherwise we're in an inconsistent state!");
		if ((threadContext == nil) || (currentCacheVersionForContext == nil) || ((int32_t)[currentCacheVersionForContext integerValue] != targetCacheVersionForContext))
		{
			threadContext = [self MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
			[threadDict setObject:threadContext forKey:kMagicalRecordManagedObjectContextKey];
			[threadDict setObject:[NSNumber numberWithInteger:targetCacheVersionForContext]
                           forKey:kMagicalRecordManagedObjectContextCacheVersionKey];
		}
		return threadContext;
	}
}

+ (void) MR_clearContextForCurrentThread {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kMagicalRecordManagedObjectContextKey];
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kMagicalRecordManagedObjectContextCacheVersionKey];
}

@end
