//
//  NSPersistentStoreCoordinator+MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import "MagicalRecordLogging.h"

static NSPersistentStoreCoordinator *defaultCoordinator_ = nil;
NSString * const kMagicalRecordPSCDidCompleteiCloudSetupNotification = @"kMagicalRecordPSCDidCompleteiCloudSetupNotification";
NSString * const kMagicalRecordPSCMismatchWillDeleteStore = @"kMagicalRecordPSCMismatchWillDeleteStore";
NSString * const kMagicalRecordPSCMismatchDidDeleteStore = @"kMagicalRecordPSCMismatchDidDeleteStore";
NSString * const kMagicalRecordPSCMismatchWillRecreateStore = @"kMagicalRecordPSCMismatchWillRecreateStore";
NSString * const kMagicalRecordPSCMismatchDidRecreateStore = @"kMagicalRecordPSCMismatchDidRecreateStore";
NSString * const kMagicalRecordPSCMismatchCouldNotDeleteStore = @"kMagicalRecordPSCMismatchCouldNotDeleteStore";
NSString * const kMagicalRecordPSCMismatchCouldNotRecreateStore = @"kMagicalRecordPSCMismatchCouldNotRecreateStore";

@interface NSDictionary (MagicalRecordMerging)

- (NSMutableDictionary*) MR_dictionaryByMergingDictionary:(NSDictionary*)d; 

@end 

@interface MagicalRecord (iCloudPrivate)

+ (void) setICloudEnabled:(BOOL)enabled;

@end

@implementation NSPersistentStoreCoordinator (MagicalRecord)

+ (NSPersistentStoreCoordinator *) MR_defaultStoreCoordinator
{
    if (defaultCoordinator_ == nil && [MagicalRecord shouldAutoCreateDefaultPersistentStoreCoordinator])
    {
        [self MR_setDefaultStoreCoordinator:[self MR_newPersistentStoreCoordinator]];
    }
	return defaultCoordinator_;
}

+ (void) MR_setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	defaultCoordinator_ = coordinator;
    
    if (defaultCoordinator_ != nil)
    {
        NSArray *persistentStores = [defaultCoordinator_ persistentStores];
        
        if ([persistentStores count] && [NSPersistentStore MR_defaultPersistentStore] == nil)
        {
            [NSPersistentStore MR_setDefaultPersistentStore:[persistentStores firstObject]];
        }
    }
}

- (void) MR_createPathToStoreFileIfNeccessary:(NSURL *)urlForStore
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *pathToStore = [urlForStore URLByDeletingLastPathComponent];
    
    NSError *error = nil;
    BOOL pathWasCreated = [fileManager createDirectoryAtPath:[pathToStore path] withIntermediateDirectories:YES attributes:nil error:&error];

    if (!pathWasCreated) 
    {
        [MagicalRecord handleErrors:error];
    }
}

- (NSPersistentStore *) MR_addSqliteStoreNamed:(id)storeFileName withOptions:(__autoreleasing NSDictionary *)options
{
    NSURL *url = [storeFileName isKindOfClass:[NSURL class]] ? storeFileName : [NSPersistentStore MR_urlForStoreName:storeFileName];
    NSError *error = nil;
    
    [self MR_createPathToStoreFileIfNeccessary:url];
    
    NSPersistentStore *store = [self addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:url
                                                        options:options
                                                          error:&error];
    
    if (!store) 
    {
        if ([MagicalRecord shouldDeleteStoreOnModelMismatch])
        {
            BOOL isMigrationError = (([error code] == NSPersistentStoreIncompatibleVersionHashError) || ([error code] == NSMigrationMissingSourceModelError) || ([error code] == NSMigrationError));
            if ([[error domain] isEqualToString:NSCocoaErrorDomain] && isMigrationError)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kMagicalRecordPSCMismatchWillDeleteStore object:nil];
                
                NSError * deleteStoreError;
                // Could not open the database, so... kill it! (AND WAL bits)
                NSString *rawURL = [url absoluteString];
                NSURL *shmSidecar = [NSURL URLWithString:[rawURL stringByAppendingString:@"-shm"]];
                NSURL *walSidecar = [NSURL URLWithString:[rawURL stringByAppendingString:@"-wal"]];
                [[NSFileManager defaultManager] removeItemAtURL:url error:&deleteStoreError];
                [[NSFileManager defaultManager] removeItemAtURL:shmSidecar error:nil];
                [[NSFileManager defaultManager] removeItemAtURL:walSidecar error:nil];

                MRLogWarn(@"Removed incompatible model version: %@", [url lastPathComponent]);
                if(deleteStoreError) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMagicalRecordPSCMismatchCouldNotDeleteStore object:nil userInfo:@{@"Error":deleteStoreError}];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMagicalRecordPSCMismatchDidDeleteStore object:nil];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kMagicalRecordPSCMismatchWillRecreateStore object:nil];
                // Try one more time to create the store
                store = [self addPersistentStoreWithType:NSSQLiteStoreType
                                           configuration:nil
                                                     URL:url
                                                 options:options
                                                   error:&error];
                if (store)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMagicalRecordPSCMismatchDidRecreateStore object:nil];
                    // If we successfully added a store, remove the error that was initially created
                    error = nil;
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMagicalRecordPSCMismatchCouldNotRecreateStore object:nil userInfo:@{@"Error":error}];
                }
            }
        }
        [MagicalRecord handleErrors:error];
    }
    return store;
}

- (void) MR_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey storeIdentifier:(id)storeIdentifier cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURL *cloudURL = [NSPersistentStore MR_cloudURLForUbiqutiousContainer:containerID];
        if (subPathComponent)
        {
            cloudURL = [cloudURL URLByAppendingPathComponent:subPathComponent];
        }
        
        [MagicalRecord setICloudEnabled:cloudURL != nil];
        
        NSDictionary *options = [[self class] MR_autoMigrationOptions];
        if (cloudURL)   //iCloud is available
        {
            NSDictionary *iCloudOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                           contentNameKey, NSPersistentStoreUbiquitousContentNameKey,
                                           cloudURL, NSPersistentStoreUbiquitousContentURLKey, nil];
            options = [options MR_dictionaryByMergingDictionary:iCloudOptions];
        }
        else
        {
            MRLogWarn(@"iCloud is not enabled");
        }


        if ([self respondsToSelector:@selector(performBlockAndWait:)])
        {
            [self performSelector:@selector(performBlockAndWait:) withObject:^{
                [self MR_addSqliteStoreNamed:storeIdentifier withOptions:options];
            }];
        }
        else
        {
            [self lock];
            [self MR_addSqliteStoreNamed:storeIdentifier withOptions:options];
            [self unlock];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([NSPersistentStore MR_defaultPersistentStore] == nil)
            {
                [NSPersistentStore MR_setDefaultPersistentStore:[[self persistentStores] firstObject]];
            }
            if (completionBlock)
            {
                completionBlock();
            }
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            [notificationCenter postNotificationName:kMagicalRecordPSCDidCompleteiCloudSetupNotification object:nil];
        });
    });
}



#pragma mark - Public Instance Methods

- (NSPersistentStore *) MR_addInMemoryStore
{
    NSError *error = nil;
    NSPersistentStore *store = [self addPersistentStoreWithType:NSInMemoryStoreType
                                                  configuration:nil 
                                                            URL:nil
                                                        options:nil
                                                          error:&error];
    if (!store)
    {
        [MagicalRecord handleErrors:error];
    }
    return store;
}

+ (NSDictionary *) MR_autoMigrationOptions;
{
    // Adding the journalling mode recommended by apple
    NSMutableDictionary *sqliteOptions = [NSMutableDictionary dictionary];
    [sqliteOptions setObject:@"WAL" forKey:@"journal_mode"];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             sqliteOptions, NSSQLitePragmasOption,
                             nil];
    return options;
}

- (NSPersistentStore *) MR_addAutoMigratingSqliteStoreNamed:(NSString *) storeFileName;
{
    NSDictionary *options = [[self class] MR_autoMigrationOptions];
    return [self MR_addSqliteStoreNamed:storeFileName withOptions:options];
}

- (NSPersistentStore *) MR_addAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL
{
    NSDictionary *options = [[self class] MR_autoMigrationOptions];
    return [self MR_addSqliteStoreNamed:storeURL withOptions:options];
}


#pragma mark - Public Class Methods


+ (NSPersistentStoreCoordinator *) MR_coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *) storeFileName
{
    NSManagedObjectModel *model = [NSManagedObjectModel MR_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [coordinator MR_addAutoMigratingSqliteStoreNamed:storeFileName];
    
    //HACK: lame solution to fix automigration error "Migration failed after first pass"
    if ([[coordinator persistentStores] count] == 0) 
    {
        [coordinator performSelector:@selector(MR_addAutoMigratingSqliteStoreNamed:) withObject:storeFileName afterDelay:0.5];
    }

    return coordinator;
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL
{
    NSManagedObjectModel *model = [NSManagedObjectModel MR_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [coordinator MR_addAutoMigratingSqliteStoreAtURL:storeURL];
    
    //HACK: lame solution to fix automigration error "Migration failed after first pass"
    if ([[coordinator persistentStores] count] == 0)
    {
        [coordinator performSelector:@selector(MR_addAutoMigratingSqliteStoreAtURL:) withObject:storeURL afterDelay:0.5];
    }
    
    return coordinator;
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithInMemoryStore
{
	NSManagedObjectModel *model = [NSManagedObjectModel MR_defaultManagedObjectModel];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

    [coordinator MR_addInMemoryStore];

    return coordinator;
}

+ (NSPersistentStoreCoordinator *) MR_newPersistentStoreCoordinator
{
	NSPersistentStoreCoordinator *coordinator = [self MR_coordinatorWithSqliteStoreNamed:[MagicalRecord defaultStoreName]];

    return coordinator;
}

- (void) MR_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent;
{
    [self MR_addiCloudContainerID:containerID 
                   contentNameKey:contentNameKey 
                  localStoreNamed:localStoreName
          cloudStorePathComponent:subPathComponent
                       completion:nil];
}

- (void) MR_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)subPathComponent
{
    [self MR_addiCloudContainerID:containerID
                   contentNameKey:contentNameKey
                  localStoreAtURL:storeURL
          cloudStorePathComponent:subPathComponent
                       completion:nil];
}

- (void) MR_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionBlock;
{
    [self MR_addiCloudContainerID:containerID
                   contentNameKey:contentNameKey
                  storeIdentifier:localStoreName
          cloudStorePathComponent:subPathComponent
                       completion:completionBlock]; 
}

- (void) MR_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionBlock;
{
    [self MR_addiCloudContainerID:containerID
                   contentNameKey:contentNameKey
                  storeIdentifier:storeURL
          cloudStorePathComponent:subPathComponent
                       completion:completionBlock];   
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithiCloudContainerID:(NSString *)containerID 
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreNamed:(NSString *)localStoreName
                                               cloudStorePathComponent:(NSString *)subPathComponent;
{
    return [self MR_coordinatorWithiCloudContainerID:containerID 
                                      contentNameKey:contentNameKey
                                     localStoreNamed:localStoreName
                             cloudStorePathComponent:subPathComponent
                                          completion:nil];
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithiCloudContainerID:(NSString *)containerID
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreAtURL:(NSURL *)storeURL
                                               cloudStorePathComponent:(NSString *)subPathComponent
{
    return [self MR_coordinatorWithiCloudContainerID:containerID
                               contentNameKey:contentNameKey
                              localStoreAtURL:storeURL
                      cloudStorePathComponent:subPathComponent
                                   completion:nil];
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithiCloudContainerID:(NSString *)containerID 
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreNamed:(NSString *)localStoreName
                                               cloudStorePathComponent:(NSString *)subPathComponent
                                                            completion:(void(^)(void))completionHandler;
{
    NSManagedObjectModel *model = [NSManagedObjectModel MR_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc MR_addiCloudContainerID:containerID 
                  contentNameKey:contentNameKey
                 localStoreNamed:localStoreName
         cloudStorePathComponent:subPathComponent
                      completion:completionHandler];
    
    return psc;
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithiCloudContainerID:(NSString *)containerID
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreAtURL:(NSURL *)storeURL
                                               cloudStorePathComponent:(NSString *)subPathComponent
                                                            completion:(void (^)(void))completionHandler
{
    NSManagedObjectModel *model = [NSManagedObjectModel MR_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc MR_addiCloudContainerID:containerID
                  contentNameKey:contentNameKey
                 localStoreAtURL:storeURL
         cloudStorePathComponent:subPathComponent
                      completion:completionHandler];
    
    return psc;
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithPersistentStore:(NSPersistentStore *)persistentStore;
{
    NSManagedObjectModel *model = [NSManagedObjectModel MR_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc MR_addSqliteStoreNamed:[persistentStore URL] withOptions:nil];

    return psc;
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithSqliteStoreNamed:(NSString *)storeFileName withOptions:(NSDictionary *)options
{
    NSManagedObjectModel *model = [NSManagedObjectModel MR_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc MR_addSqliteStoreNamed:storeFileName withOptions:options];
    return psc;
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL withOptions:(NSDictionary *)options
{
    NSManagedObjectModel *model = [NSManagedObjectModel MR_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc MR_addSqliteStoreNamed:storeURL withOptions:options];
    return psc;
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithSqliteStoreNamed:(NSString *)storeFileName
{
	return [self MR_coordinatorWithSqliteStoreNamed:storeFileName withOptions:nil];
}

+ (NSPersistentStoreCoordinator *) MR_coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL
{
    return [self MR_coordinatorWithSqliteStoreAtURL:storeURL withOptions:nil];
}

@end


@implementation NSDictionary (Merging) 

- (NSMutableDictionary *) MR_dictionaryByMergingDictionary:(NSDictionary *)d;
{
    NSMutableDictionary *mutDict = [self mutableCopy];
    [mutDict addEntriesFromDictionary:d];
    return mutDict; 
} 

@end 
