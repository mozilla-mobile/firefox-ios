//
//  NSPersistentStore+MagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "MagicalRecord.h"
#import <CoreData/CoreData.h>

// option to autodelete store if it already exists

extern NSString * const kMagicalRecordDefaultStoreFileName;


@interface NSPersistentStore (MagicalRecord)

+ (NSURL *) MR_defaultLocalStoreUrl;

+ (NSPersistentStore *) MR_defaultPersistentStore;
+ (void) MR_setDefaultPersistentStore:(NSPersistentStore *) store;

+ (NSURL *) MR_urlForStoreName:(NSString *)storeFileName;
+ (NSURL *) MR_cloudURLForUbiqutiousContainer:(NSString *)bucketName;

@end


