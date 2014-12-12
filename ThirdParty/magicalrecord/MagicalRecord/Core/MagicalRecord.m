//
//  MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "CoreData+MagicalRecord.h"

NSString * const kMagicalRecordCleanedUpNotification = @"kMagicalRecordCleanedUpNotification";

@interface MagicalRecord (Internal)

+ (void) cleanUpStack;
+ (void) cleanUpErrorHanding;

@end

@interface NSManagedObjectContext (MagicalRecordInternal)

+ (void) MR_cleanUp;

@end


@implementation MagicalRecord

+ (MagicalRecordVersionNumber) version
{
    return MagicalRecordVersionNumber2_3;
}

+ (void) cleanUp
{
    [self cleanUpErrorHanding];
    [self cleanUpStack];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:kMagicalRecordCleanedUpNotification
                                      object:nil
                                    userInfo:nil];
}

+ (void) cleanUpStack;
{
	[NSManagedObjectContext MR_cleanUp];
	[NSManagedObjectModel MR_setDefaultManagedObjectModel:nil];
	[NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:nil];
	[NSPersistentStore MR_setDefaultPersistentStore:nil];
}

+ (NSString *) currentStack
{
    NSMutableString *status = [NSMutableString stringWithString:@"Current Default Core Data Stack: ---- \n"];

    [status appendFormat:@"Model:           %@\n", [[NSManagedObjectModel MR_defaultManagedObjectModel] entityVersionHashesByName]];
    [status appendFormat:@"Coordinator:     %@\n", [NSPersistentStoreCoordinator MR_defaultStoreCoordinator]];
    [status appendFormat:@"Store:           %@\n", [NSPersistentStore MR_defaultPersistentStore]];
    [status appendFormat:@"Default Context: %@\n", [[NSManagedObjectContext MR_defaultContext] MR_description]];
    [status appendFormat:@"Context Chain:   \n%@\n", [[NSManagedObjectContext MR_defaultContext] MR_parentChain]];

    return status;
}

+ (void) setDefaultModelNamed:(NSString *)modelName;
{
    NSManagedObjectModel *model = [NSManagedObjectModel MR_managedObjectModelNamed:modelName];
    [NSManagedObjectModel MR_setDefaultManagedObjectModel:model];
}

+ (void) setDefaultModelFromClass:(Class)modelClass;
{
    NSBundle *bundle = [NSBundle bundleForClass:modelClass];
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
    [NSManagedObjectModel MR_setDefaultManagedObjectModel:model];
}

+ (NSString *) defaultStoreName;
{
    NSString *defaultName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey];
    if (defaultName == nil)
    {
        defaultName = kMagicalRecordDefaultStoreFileName;
    }
    if (![defaultName hasSuffix:@"sqlite"]) 
    {
        defaultName = [defaultName stringByAppendingPathExtension:@"sqlite"];
    }

    return defaultName;
}


#pragma mark - initialize

+ (void) initialize;
{
    if (self == [MagicalRecord class]) 
    {
#ifdef MR_SHORTHAND
        [self swizzleShorthandMethods];
#endif
        [self setShouldAutoCreateManagedObjectModel:YES];
        [self setShouldAutoCreateDefaultPersistentStoreCoordinator:NO];
#ifdef DEBUG
        [self setShouldDeleteStoreOnModelMismatch:YES];
#else
        [self setShouldDeleteStoreOnModelMismatch:NO];
#endif
    }
}

@end


