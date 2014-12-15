//
//  MagicalRecord+iCloud.m
//  Magical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecord+iCloud.h"
#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalRecord.h"

static BOOL _iCloudEnabled = NO;

@implementation MagicalRecord (iCloud)

#pragma mark - iCloud Methods

+ (BOOL) isICloudEnabled;
{
    return _iCloudEnabled;
}

+ (void) setICloudEnabled:(BOOL)enabled;
{
    @synchronized(self)
    {
        _iCloudEnabled = enabled;
    }
}

+ (void) setupCoreDataStackWithiCloudContainer:(NSString *)containerID localStoreNamed:(NSString *)localStore;
{
    NSString *contentNameKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleIdentifierKey];
    [self setupCoreDataStackWithiCloudContainer:containerID
                                 contentNameKey:contentNameKey
                                localStoreNamed:localStore
                        cloudStorePathComponent:nil];
}

+ (void) setupCoreDataStackWithiCloudContainer:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)pathSubcomponent;
{
    [self setupCoreDataStackWithiCloudContainer:containerID 
                                 contentNameKey:contentNameKey
                                localStoreNamed:localStoreName
                        cloudStorePathComponent:pathSubcomponent
                                     completion:nil];
}

+ (void) setupCoreDataStackWithiCloudContainer:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)pathSubcomponent completion:(void(^)(void))completion;
{
    NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator MR_coordinatorWithiCloudContainerID:containerID
                                                                                                   contentNameKey:contentNameKey 
                                                                                                  localStoreNamed:localStoreName 
                                                                                          cloudStorePathComponent:pathSubcomponent
                                                                                                       completion:completion];
    [NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:coordinator];
    [NSManagedObjectContext MR_initializeDefaultContextWithCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithiCloudContainer:(NSString *)containerID localStoreAtURL:(NSURL *)storeURL
{
    NSString *contentNameKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleIdentifierKey];
    [self setupCoreDataStackWithiCloudContainer:containerID
                                 contentNameKey:contentNameKey
                                localStoreAtURL:storeURL
                        cloudStorePathComponent:nil];
}

+ (void) setupCoreDataStackWithiCloudContainer:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)pathSubcomponent
{
    [self setupCoreDataStackWithiCloudContainer:containerID
                                 contentNameKey:contentNameKey
                                localStoreAtURL:storeURL
                        cloudStorePathComponent:pathSubcomponent
                                     completion:nil];
}

+ (void) setupCoreDataStackWithiCloudContainer:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)pathSubcomponent completion:(void (^)(void))completion
{
    NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator MR_coordinatorWithiCloudContainerID:containerID contentNameKey:contentNameKey localStoreAtURL:storeURL cloudStorePathComponent:pathSubcomponent completion:completion];
    
    [NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:coordinator];
    [NSManagedObjectContext MR_initializeDefaultContextWithCoordinator:coordinator];
}

@end
