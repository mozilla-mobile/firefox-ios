//
//  Created by Tony Arnold on 25/03/2014.
//  Copyright (c) 2014 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecordTestBase.h"
#import "SingleEntityWithNoRelationships.h"

@interface NSManagedObjectContextMagicalSavesTests : MagicalRecordTestBase

@end

@implementation NSManagedObjectContextMagicalSavesTests

- (void)testSaveToSelfOnlyWhenSaveIsSynchronous
{
    NSManagedObjectContext *parentContext = [NSManagedObjectContext MR_defaultContext];
    NSManagedObjectContext *childContext = [NSManagedObjectContext MR_contextWithParent:parentContext];

    XCTestExpectation *childContextSavedExpectation = [self expectationWithDescription:@"Child Context Did Save"];

    __block NSManagedObjectID *insertedObjectID;

    [childContext performBlockAndWait:^{
        SingleEntityWithNoRelationships *insertedObject = [SingleEntityWithNoRelationships MR_createEntityInContext:childContext];

        expect([insertedObject hasChanges]).to.beTruthy();

        NSError *obtainIDsError;
        BOOL obtainIDsResult = [childContext obtainPermanentIDsForObjects:@[insertedObject] error:&obtainIDsError];

        expect(obtainIDsResult).to.beTruthy();
        expect(obtainIDsError).to.beNil();

        insertedObjectID = [insertedObject objectID];

        expect(insertedObjectID).toNot.beNil();
        expect([insertedObjectID isTemporaryID]).to.beFalsy();
        
        [childContext MR_saveOnlySelfAndWait];

        [childContextSavedExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];

    XCTestExpectation *parentContextSavedExpectation = [self expectationWithDescription:@"Parent Context Did Save"];
    childContextSavedExpectation = [self expectationWithDescription:@"Child Context Did Save"];

    [parentContext performBlockAndWait:^{
        NSManagedObject *parentContextFetchedObject = [parentContext objectRegisteredForID:insertedObjectID];

        // Saving a child context moves the saved changes up to the parent, but does
        //  not save them, leaving the parent context with changes
        expect(parentContextFetchedObject).toNot.beNil();
        expect([parentContextFetchedObject hasChanges]).to.beTruthy();

        [childContext performBlockAndWait:^{
            NSManagedObject *childContextFetchedObject = [childContext objectRegisteredForID:insertedObjectID];

            // The child context should not have changes after the save
            expect(childContextFetchedObject).toNot.beNil();
            expect([childContextFetchedObject hasChanges]).to.beFalsy();

            [childContextSavedExpectation fulfill];
        }];

        [parentContextSavedExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testSaveToSelfOnlyWhenSaveIsAsynchronous
{
    NSManagedObjectContext *parentContext = [NSManagedObjectContext MR_defaultContext];
    NSManagedObjectContext *childContext = [NSManagedObjectContext MR_contextWithParent:parentContext];

    XCTestExpectation *childContextExpectation = [self expectationWithDescription:@"Child Context Completed Work"];
    XCTestExpectation *childContextSaveExpectation = [self expectationWithDescription:@"Child Context Saved"];
    XCTestExpectation *parentContextExpectation = [self expectationWithDescription:@"Parent Context Completed Work"];

    [childContext performBlock:^{
        SingleEntityWithNoRelationships *insertedObject = [SingleEntityWithNoRelationships MR_createEntityInContext:childContext];

        expect([insertedObject hasChanges]).to.beTruthy();

        NSError *obtainIDsError;
        BOOL obtainIDsResult = [childContext obtainPermanentIDsForObjects:@[insertedObject] error:&obtainIDsError];

        expect(obtainIDsResult).to.beTruthy();
        expect(obtainIDsError).to.beNil();

        NSManagedObjectID *insertedObjectID = [insertedObject objectID];

        expect(insertedObjectID).toNot.beNil();
        expect([insertedObjectID isTemporaryID]).to.beFalsy();

        [childContext MR_saveOnlySelfWithCompletion:^(BOOL contextDidSave, NSError *error) {
            expect(contextDidSave).to.beTruthy();
            expect(error).to.beNil();

            [childContext performBlock:^{
                NSManagedObject *childContextFetchedObject = [childContext objectRegisteredForID:insertedObjectID];

                // The child context should not have changes after the save
                expect(childContextFetchedObject).toNot.beNil();
                expect([childContextFetchedObject hasChanges]).to.beFalsy();

                [childContextSaveExpectation fulfill];
            }];

            [parentContext performBlock:^{
                NSManagedObject *parentContextFetchedObject = [parentContext objectRegisteredForID:insertedObjectID];

                // Saving a child context moves the saved changes up to the parent, but does
                //  not save them, leaving the parent context with changes
                expect(parentContextFetchedObject).toNot.beNil();
                expect([parentContextFetchedObject hasChanges]).to.beTruthy();

                [parentContextExpectation fulfill];
            }];
        }];

        [childContextExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testSaveToSelfOnlyWhenSaveIsAsynchronousCallsMainThreadOnCompletion
{
    NSManagedObjectContext *defaultContext = [NSManagedObjectContext MR_defaultContext];

    __block BOOL completionBlockCalled = NO;
    __block BOOL completionBlockIsOnMainThread = NO;

    NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:defaultContext];

    expect([inserted hasChanges]).to.beTruthy();

    XCTestExpectation *contextSavedExpectation = [self expectationWithDescription:@"Context Did Save"];

    [defaultContext MR_saveOnlySelfWithCompletion:^(BOOL contextDidSave, NSError *error) {
        expect([NSThread isMainThread]).to.beTruthy();

        [contextSavedExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testSaveToPersistentStoreWhenSaveIsSynchronous
{
    NSManagedObjectContext *parentContext = [NSManagedObjectContext MR_defaultContext];
    NSManagedObjectContext *childContext = [NSManagedObjectContext MR_contextWithParent:parentContext];

    XCTestExpectation *childContextExpectation = [self expectationWithDescription:@"Child Context Completed Work"];
    XCTestExpectation *parentContextExpectation = [self expectationWithDescription:@"Parent Context Completed Work"];

    [childContext performBlock:^{
        SingleEntityWithNoRelationships *insertedObject = [SingleEntityWithNoRelationships MR_createEntityInContext:childContext];

        expect([insertedObject hasChanges]).to.beTruthy();

        NSError *obtainIDsError;
        BOOL obtainIDsResult = [childContext obtainPermanentIDsForObjects:@[insertedObject] error:&obtainIDsError];

        expect(obtainIDsResult).to.beTruthy();
        expect(obtainIDsError).to.beNil();

        NSManagedObjectID *insertedObjectID = [insertedObject objectID];

        expect(insertedObjectID).toNot.beNil();
        expect([insertedObjectID isTemporaryID]).to.beFalsy();

        [childContext MR_saveToPersistentStoreAndWait];

        [parentContext performBlock:^{
            NSError *fetchExistingObjectFromParentContextError;
            NSManagedObject *parentContextFetchedObject = [parentContext existingObjectWithID:insertedObjectID error:&fetchExistingObjectFromParentContextError];

            // Saving to the persistent store should save to all parent contexts,
            //  leaving no changes
            expect(fetchExistingObjectFromParentContextError).to.beNil();
            expect(parentContextFetchedObject).toNot.beNil();
            expect([parentContextFetchedObject hasChanges]).to.beFalsy();

            [parentContextExpectation fulfill];
        }];

        NSManagedObject *childContextFetchedObject = [childContext objectRegisteredForID:insertedObjectID];

        // The child context should not have changes after the save
        expect(childContextFetchedObject).toNot.beNil();
        expect([childContextFetchedObject hasChanges]).to.beFalsy();

        [childContextExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testSaveToPersistentStoreWhenSaveIsAsynchronous
{
    NSManagedObjectContext *parentContext = [NSManagedObjectContext MR_defaultContext];
    NSManagedObjectContext *childContext = [NSManagedObjectContext MR_contextWithParent:parentContext];

    XCTestExpectation *childContextExpectation = [self expectationWithDescription:@"Child Context Completed Work"];
    XCTestExpectation *childContextSavedExpectation = [self expectationWithDescription:@"Child Context Saved"];

    [childContext performBlock:^{
        SingleEntityWithNoRelationships *insertedObject = [SingleEntityWithNoRelationships MR_createEntityInContext:childContext];

        expect([insertedObject hasChanges]).to.beTruthy();

        NSError *obtainIDsError;
        BOOL obtainIDsResult = [childContext obtainPermanentIDsForObjects:@[insertedObject] error:&obtainIDsError];

        expect(obtainIDsResult).to.beTruthy();
        expect(obtainIDsError).to.beNil();

        NSManagedObjectID *insertedObjectID = [insertedObject objectID];

        expect(insertedObjectID).toNot.beNil();
        expect([insertedObjectID isTemporaryID]).to.beFalsy();


        [childContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
            expect(contextDidSave).to.beTruthy();
            expect(error).to.beNil();

            [parentContext performBlockAndWait:^{
                NSError *fetchExistingObjectFromParentContextError;
                NSManagedObject *parentContextFetchedObject = [parentContext existingObjectWithID:insertedObjectID error:&fetchExistingObjectFromParentContextError];

                // Saving to the persistent store should save to all parent contexts,
                //  leaving no changes
                expect(fetchExistingObjectFromParentContextError).to.beNil();
                expect(parentContextFetchedObject).toNot.beNil();
                expect([parentContextFetchedObject hasChanges]).to.beFalsy();
            }];

            [childContext performBlockAndWait:^{
                NSManagedObject *childContextFetchedObject = [childContext objectRegisteredForID:insertedObjectID];

                // The child context should not have changes after the save
                expect(childContextFetchedObject).toNot.beNil();
                expect([childContextFetchedObject hasChanges]).to.beFalsy();
            }];

            [childContextSavedExpectation fulfill];
        }];

        [childContextExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testThatSavedObjectsHavePermanentIDs
{
    NSManagedObjectContext *defaultContext = [NSManagedObjectContext MR_defaultContext];
    SingleEntityWithNoRelationships *entity = [SingleEntityWithNoRelationships MR_createEntityInContext:defaultContext];
    
    expect([[entity objectID] isTemporaryID]).to.beTruthy();
    
    [defaultContext MR_saveOnlySelfAndWait];
    
    expect([[entity objectID] isTemporaryID]).to.beFalsy();
}

@end
