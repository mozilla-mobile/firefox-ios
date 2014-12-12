//
//  NSManagedObjectContext+MagicalRecord.m
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import "MagicalRecordLogging.h"
#import <objc/runtime.h>

static NSString * const MagicalRecordContextWorkingName = @"MagicalRecordContextWorkingName";

static NSManagedObjectContext *MagicalRecordRootSavingContext;
static NSManagedObjectContext *MagicalRecordDefaultContext;

static id MagicalRecordUbiquitySetupNotificationObserver;

@implementation NSManagedObjectContext (MagicalRecord)

#pragma mark - Setup

+ (void) MR_initializeDefaultContextWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
    NSAssert(coordinator, @"Provided coordinator cannot be nil!");
    if (MagicalRecordDefaultContext == nil)
    {
        NSManagedObjectContext *rootContext = [self MR_contextWithStoreCoordinator:coordinator];
        [self MR_setRootSavingContext:rootContext];

        NSManagedObjectContext *defaultContext = [self MR_newMainQueueContext];
        [self MR_setDefaultContext:defaultContext];

        [defaultContext setParentContext:rootContext];
    }
}

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) MR_defaultContext
{
    @synchronized(self) {
        NSAssert(MagicalRecordDefaultContext != nil, @"Default context is nil! Did you forget to initialize the Core Data Stack?");
        return MagicalRecordDefaultContext;
    }
}

+ (NSManagedObjectContext *) MR_rootSavingContext;
{
    return MagicalRecordRootSavingContext;
}

#pragma mark - Context Creation

+ (NSManagedObjectContext *) MR_context
{
    return [self MR_contextWithParent:[self MR_rootSavingContext]];
}

+ (NSManagedObjectContext *) MR_contextWithParent:(NSManagedObjectContext *)parentContext
{
    NSManagedObjectContext *context = [self MR_newPrivateQueueContext];
    [context setParentContext:parentContext];
    [context MR_obtainPermanentIDsBeforeSaving];
    return context;
}

+ (NSManagedObjectContext *) MR_contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	NSManagedObjectContext *context = nil;
    if (coordinator != nil)
	{
        context = [self MR_newPrivateQueueContext];
        [context performBlockAndWait:^{
            [context setPersistentStoreCoordinator:coordinator];
            MRLogVerbose(@"Created new context %@ with store coordinator: %@", [context MR_workingName], coordinator);
        }];
    }
    return context;
}

+ (NSManagedObjectContext *) MR_newMainQueueContext
{
    NSManagedObjectContext *context = [[self alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    MRLogInfo(@"Created new main queue context: %@", context);
    return context;
}

+ (NSManagedObjectContext *) MR_newPrivateQueueContext
{
    NSManagedObjectContext *context = [[self alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    MRLogInfo(@"Created new private queue context: %@", context);
    return context;
}

#pragma mark - Debugging

- (void) MR_setWorkingName:(NSString *)workingName
{
    [[self userInfo] setObject:workingName forKey:MagicalRecordContextWorkingName];
}

- (NSString *) MR_workingName
{
    NSString *workingName = [[self userInfo] objectForKey:MagicalRecordContextWorkingName];

    if ([workingName length] == 0)
    {
        workingName = @"Untitled Context";
    }

    return workingName;
}

- (NSString *) MR_description
{
    NSString *onMainThread = [NSThread isMainThread] ? @"the main thread" : @"a background thread";

    __block NSString *workingName;

    [self performBlockAndWait:^{
        workingName = [self MR_workingName];
    }];

    return [NSString stringWithFormat:@"<%@ (%p): %@> on %@", NSStringFromClass([self class]), self, workingName, onMainThread];
}

- (NSString *) MR_parentChain
{
    NSMutableString *familyTree = [@"\n" mutableCopy];
    NSManagedObjectContext *currentContext = self;
    do
    {
        [familyTree appendFormat:@"- %@ (%p) %@\n", [currentContext MR_workingName], currentContext, (currentContext == self ? @"(*)" : @"")];
    }
    while ((currentContext = [currentContext parentContext]));

    return [NSString stringWithString:familyTree];
}

#pragma mark - Helpers

+ (void) MR_resetDefaultContext
{
    NSManagedObjectContext *defaultContext = [NSManagedObjectContext MR_defaultContext];
    NSAssert(NSConfinementConcurrencyType == [defaultContext concurrencyType], @"Do not call this method on a confinement context.");

    if ([NSThread isMainThread] == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self MR_resetDefaultContext];
        });

        return;
    }

    [defaultContext reset];
}

- (void) MR_deleteObjects:(id <NSFastEnumeration>)objects
{
    for (NSManagedObject *managedObject in objects)
    {
        [self deleteObject:managedObject];
    }
}

#pragma mark - Notification Handlers

- (void) MR_contextWillSave:(NSNotification *)notification
{
    NSManagedObjectContext *context = [notification object];
    NSSet *insertedObjects = [context insertedObjects];

    if ([insertedObjects count])
    {
        MRLogVerbose(@"Context '%@' is about to save: obtaining permanent IDs for %lu new inserted object(s).", [context MR_workingName], (unsigned long)[insertedObjects count]);
        NSError *error = nil;
        BOOL success = [context obtainPermanentIDsForObjects:[insertedObjects allObjects] error:&error];
        if (!success)
        {
            [MagicalRecord handleErrors:error];
        }
    }
}

+ (void) rootContextDidSave:(NSNotification *)notification
{
    if ([notification object] != [self MR_rootSavingContext])
    {
        return;
    }

    if ([NSThread isMainThread] == NO)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self rootContextDidSave:notification];
        });

        return;
    }

    [[self MR_defaultContext] mergeChangesFromContextDidSaveNotification:notification];
}

#pragma mark - Private Methods

+ (void) MR_cleanUp
{
    [self MR_setDefaultContext:nil];
    [self MR_setRootSavingContext:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self MR_clearNonMainThreadContextsCache];
#pragma clang diagnostic pop
}

- (void) MR_obtainPermanentIDsBeforeSaving
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(MR_contextWillSave:)
                                                 name:NSManagedObjectContextWillSaveNotification
                                               object:self];
}

+ (void) MR_setDefaultContext:(NSManagedObjectContext *)moc
{
    if (MagicalRecordDefaultContext)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:MagicalRecordDefaultContext];
    }

    NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator MR_defaultStoreCoordinator];
    if (MagicalRecordUbiquitySetupNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:MagicalRecordUbiquitySetupNotificationObserver];
        MagicalRecordUbiquitySetupNotificationObserver = nil;
    }

    if ([MagicalRecord isICloudEnabled])
    {
        [MagicalRecordDefaultContext MR_stopObservingiCloudChangesInCoordinator:coordinator];
    }

    MagicalRecordDefaultContext = moc;
    [MagicalRecordDefaultContext MR_setWorkingName:@"MagicalRecord Default Context"];

    if ((MagicalRecordDefaultContext != nil) && ([self MR_rootSavingContext] != nil)) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(rootContextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:[self MR_rootSavingContext]];
    }

    [moc MR_obtainPermanentIDsBeforeSaving];
    if ([MagicalRecord isICloudEnabled])
    {
        [MagicalRecordDefaultContext MR_observeiCloudChangesInCoordinator:coordinator];
    }
    else
    {
        // If icloud is NOT enabled at the time of this method being called, listen for it to be setup later, and THEN set up observing cloud changes
        MagicalRecordUbiquitySetupNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMagicalRecordPSCDidCompleteiCloudSetupNotification
                                                                                            object:nil
                                                                                             queue:[NSOperationQueue mainQueue]
                                                                                        usingBlock:^(NSNotification *note) {
                                                                                            [[NSManagedObjectContext MR_defaultContext] MR_observeiCloudChangesInCoordinator:coordinator];
                                                                                        }];
    }
    MRLogInfo(@"Set default context: %@", MagicalRecordDefaultContext);
}

+ (void)MR_setRootSavingContext:(NSManagedObjectContext *)context
{
    if (MagicalRecordRootSavingContext)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:MagicalRecordRootSavingContext];
    }

    MagicalRecordRootSavingContext = context;
    
    [context performBlock:^{
        [context MR_obtainPermanentIDsBeforeSaving];
        [MagicalRecordRootSavingContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [MagicalRecordRootSavingContext MR_setWorkingName:@"MagicalRecord Root Saving Context"];
    }];

    MRLogInfo(@"Set root saving context: %@", MagicalRecordRootSavingContext);
}

@end

#pragma mark - Deprecated Methods — DO NOT USE
@implementation NSManagedObjectContext (MagicalRecordDeprecated)

+ (NSManagedObjectContext *) MR_contextWithoutParent
{
    return [self MR_newPrivateQueueContext];
}

+ (NSManagedObjectContext *) MR_newContext
{
    return [self MR_context];
}

+ (NSManagedObjectContext *) MR_newContextWithParent:(NSManagedObjectContext *)parentContext
{
    return [self MR_contextWithParent:parentContext];
}

+ (NSManagedObjectContext *) MR_newContextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    return [self MR_contextWithStoreCoordinator:coordinator];
}

@end
