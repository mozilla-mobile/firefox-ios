//
//  NSManagedObjectContext+MagicalSaves.m
//  Magical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "NSManagedObjectContext+MagicalSaves.h"
#import "MagicalRecord+ErrorHandling.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "MagicalRecord.h"
#import "MagicalRecordLogging.h"

@implementation NSManagedObjectContext (MagicalSaves)

- (void) MR_saveOnlySelfWithCompletion:(MRSaveCompletionHandler)completion;
{
    [self MR_saveWithOptions:MRSaveOptionNone completion:completion];
}

- (void) MR_saveOnlySelfAndWait;
{
    [self MR_saveWithOptions:MRSaveSynchronously completion:nil];
}

- (void) MR_saveToPersistentStoreWithCompletion:(MRSaveCompletionHandler)completion;
{
    [self MR_saveWithOptions:MRSaveParentContexts completion:completion];
}

- (void) MR_saveToPersistentStoreAndWait;
{
    [self MR_saveWithOptions:MRSaveParentContexts | MRSaveSynchronously completion:nil];
}

- (void) MR_saveWithOptions:(MRSaveOptions)saveOptions completion:(MRSaveCompletionHandler)completion;
{
    __block BOOL hasChanges = NO;

    if ([self concurrencyType] == NSConfinementConcurrencyType)
    {
        hasChanges = [self hasChanges];
    }
    else
    {
        [self performBlockAndWait:^{
            hasChanges = [self hasChanges];
        }];
    }

    if (!hasChanges)
    {
        MRLogVerbose(@"NO CHANGES IN ** %@ ** CONTEXT - NOT SAVING", [self MR_workingName]);

        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil);
            });
        }

        return;
    }

    BOOL shouldSaveParentContexts = ((saveOptions & MRSaveParentContexts) == MRSaveParentContexts);
    BOOL shouldSaveSynchronously = ((saveOptions & MRSaveSynchronously) == MRSaveSynchronously);
    BOOL shouldSaveSynchronouslyExceptRoot = ((saveOptions & MRSaveSynchronouslyExceptRootContext) == MRSaveSynchronouslyExceptRootContext);

    BOOL saveSynchronously = (shouldSaveSynchronously && !shouldSaveSynchronouslyExceptRoot) ||
                             (shouldSaveSynchronouslyExceptRoot && (self != [[self class] MR_rootSavingContext]));

    id saveBlock = ^{
        MRLogInfo(@"→ Saving %@", [self MR_description]);
        MRLogVerbose(@"→ Save Parents? %@", shouldSaveParentContexts ? @"YES" : @"NO");
        MRLogVerbose(@"→ Save Synchronously? %@", saveSynchronously ? @"YES" : @"NO");

        BOOL saveResult = NO;
        NSError *error = nil;

        @try
        {
            saveResult = [self save:&error];
        }
        @catch(NSException *exception)
        {
            MRLogError(@"Unable to perform save: %@", (id)[exception userInfo] ?: (id)[exception reason]);
        }
        @finally
        {
            [MagicalRecord handleErrors:error];

            if (saveResult && shouldSaveParentContexts && [self parentContext])
            {
                // Add/remove the synchronous save option from the mask if necessary
                MRSaveOptions modifiedOptions = saveOptions;

                if (saveSynchronously)
                {
                    modifiedOptions |= MRSaveSynchronously;
                }
                else
                {
                    modifiedOptions &= MRSaveSynchronously;
                }

                // If we're saving parent contexts, do so
                [[self parentContext] MR_saveWithOptions:modifiedOptions completion:completion];
            }
            else
            {
                if (saveResult)
                {
                    MRLogVerbose(@"→ Finished saving: %@", [self MR_description]);
                }

                if (completion)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(saveResult, error);
                    });
                }
            }
        }
    };

    if (saveSynchronously)
    {
        [self performBlockAndWait:saveBlock];
    }
    else
    {
        [self performBlock:saveBlock];
    }
}

@end

#pragma mark - Deprecated Methods — DO NOT USE
@implementation NSManagedObjectContext (MagicalSavesDeprecated)

- (void) MR_save;
{
    [self MR_saveToPersistentStoreAndWait];
}

- (void) MR_saveWithErrorCallback:(void (^)(NSError *error))errorCallback;
{
    [self MR_saveWithOptions:MRSaveSynchronously | MRSaveParentContexts completion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave && errorCallback)
        {
            errorCallback(error);
        }
    }];
}

- (void) MR_saveInBackgroundCompletion:(void (^)(void))completion;
{
    [self MR_saveOnlySelfWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (contextDidSave && completion)
        {
            completion();
        }
    }];
}

- (void) MR_saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback;
{
    [self MR_saveOnlySelfWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave && errorCallback)
        {
            errorCallback(error);
        }
    }];
}

- (void) MR_saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion;
{
    [self MR_saveOnlySelfWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (contextDidSave && completion)
        {
            completion();
        }
        else if (errorCallback)
        {
            errorCallback(error);
        }
    }];
}

- (void) MR_saveNestedContexts;
{
    [self MR_saveToPersistentStoreWithCompletion:nil];
}

- (void) MR_saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback;
{
    [self MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (!contextDidSave && errorCallback)
        {
            errorCallback(error);
        }
    }];
}

- (void) MR_saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion;
{
    [self MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (contextDidSave && completion)
        {
            completion();
        }
        else if (errorCallback)
        {
            errorCallback(error);
        }
    }];
}

@end
