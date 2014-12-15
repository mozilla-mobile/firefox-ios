//
//  Created by Tony Arnold on 25/03/2014.
//  Copyright (c) 2014 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecordTestBase.h"
#import "SingleEntityWithNoRelationships.h"

@interface MagicalRecordActionsTests : MagicalRecordTestBase

@end

@implementation MagicalRecordActionsTests

#pragma mark - Synchronous Saves

- (void)testSynchronousSaveActionSaves
{
    __block NSManagedObjectID *objectId;

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];

        expect([inserted hasChanges]).to.beTruthy();

        [localContext obtainPermanentIDsForObjects:@[inserted] error:nil];
        objectId = [inserted objectID];
    }];

    expect(objectId).toNot.beNil();

    XCTestExpectation *rootSavingExpectation = [self expectationWithDescription:@"Root Saving Context Fetch Object"];
    NSManagedObjectContext *rootSavingContext = [NSManagedObjectContext MR_rootSavingContext];

    [rootSavingContext performBlock:^{
        NSError *fetchError;
        NSManagedObject *fetchedObject = [rootSavingContext existingObjectWithID:objectId error:&fetchError];

        expect(fetchedObject).toNot.beNil();
        expect(fetchError).to.beNil();
        expect([fetchedObject hasChanges]).to.beFalsy();

        [rootSavingExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testSynchronousSaveActionMakesInsertedEntitiesAvailableInTheDefaultContext
{
    __block NSManagedObjectID *objectId;

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];

        expect([inserted hasChanges]).to.beTruthy();

        [localContext obtainPermanentIDsForObjects:@[inserted] error:nil];
        objectId = [inserted objectID];
    }];

    expect(objectId).toNot.beNil();

    XCTestExpectation *rootSavingExpectation = [self expectationWithDescription:@"Root Saving Context Fetch Object"];
    NSManagedObjectContext *rootSavingContext = [NSManagedObjectContext MR_rootSavingContext];

    [rootSavingContext performBlock:^{
        NSError *fetchError;
        NSManagedObject *fetchedObject = [rootSavingContext existingObjectWithID:objectId error:&fetchError];

        expect(fetchedObject).toNot.beNil();
        expect(fetchError).to.beNil();
        expect([fetchedObject hasChanges]).to.beFalsy();

        [rootSavingExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testSynchronousSaveActionMakesUpdatesToEntitiesAvailableToTheDefaultContext
{
    __block NSManagedObjectID *objectId;
    __block NSManagedObject *fetchedObject;

    NSString *const kTestAttributeKey = @"booleanTestAttribute";

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];

        [inserted setValue:@YES forKey:kTestAttributeKey];

        expect([inserted hasChanges]).to.beTruthy();

        [localContext obtainPermanentIDsForObjects:@[inserted] error:nil];
        objectId = [inserted objectID];
    }];

    XCTestExpectation *rootSavingExpectation = [self expectationWithDescription:@"Root Saving Context Fetch Object"];
    NSManagedObjectContext *rootSavingContext = [NSManagedObjectContext MR_rootSavingContext];

    [rootSavingContext performBlock:^{
        fetchedObject = [rootSavingContext objectWithID:objectId];
        expect([fetchedObject valueForKey:kTestAttributeKey]).to.beTruthy();

        [rootSavingExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSManagedObject *changed = [localContext objectWithID:objectId];

        [changed setValue:@NO forKey:kTestAttributeKey];
    }];

    rootSavingExpectation = [self expectationWithDescription:@"Root Saving Context Fetch Object"];

    [rootSavingContext performBlock:^{
        fetchedObject = [rootSavingContext objectWithID:objectId];

        // Async since the merge to the main thread context after persistence
        expect([fetchedObject valueForKey:kTestAttributeKey]).to.beFalsy();

        [rootSavingExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

#pragma mark - Asynchronous Saves

- (void)testAsynchronousSaveActionSaves
{
    __block BOOL saveSuccessState = NO;
    __block NSError *saveError;
    __block NSManagedObjectID *objectId;

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];

        expect([inserted hasChanges]).to.beTruthy();

        [localContext obtainPermanentIDsForObjects:@[inserted] error:nil];
        objectId = [inserted objectID];

        expect(objectId).toNot.beNil();
    } completion:^(BOOL contextDidSave, NSError *error) {
        saveSuccessState = contextDidSave;
        saveError = error;

        expect(saveSuccessState).to.beTruthy();
        expect(saveError).to.beNil();

        NSManagedObjectContext *rootSavingContext = [NSManagedObjectContext MR_rootSavingContext];

        [rootSavingContext performBlock:^{
            NSError *existingObjectError;
            NSManagedObject *existingObject = [rootSavingContext existingObjectWithID:objectId error:&existingObjectError];

            expect(existingObject).toNot.beNil();
            expect([existingObject hasChanges]).to.beFalsy();
            expect(existingObjectError).to.beNil();
        }];
    }];

}

- (void)testAsynchronousSaveActionCallsCompletionBlockOnTheMainThread
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Save Completed"];

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];
    } completion:^(BOOL contextDidSave, NSError *error) {
        expect([NSThread isMainThread]).to.beTruthy();

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testAsynchronousSaveActionMakesInsertedEntitiesAvailableInTheDefaultContext
{
    __block NSManagedObjectID *objectId;

    XCTestExpectation *contextSavedExpectation = [self expectationWithDescription:@"Context Did Save"];

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];

        expect([inserted hasChanges]).to.beTruthy();

        [localContext obtainPermanentIDsForObjects:@[inserted] error:nil];
        objectId = [inserted objectID];
    } completion:^(BOOL contextDidSave, NSError *error) {
        expect(contextDidSave).to.beTruthy();

        NSManagedObjectContext *rootSavingContext = [NSManagedObjectContext MR_rootSavingContext];

        [rootSavingContext performBlock:^{
            NSManagedObject *fetchedObject = [rootSavingContext objectWithID:objectId];
            expect(fetchedObject).toNot.beNil();
            expect([fetchedObject hasChanges]).to.beFalsy();

            [contextSavedExpectation fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testAsynchronousSaveActionMakesUpdatesToEntitiesAvailableToTheDefaultContext
{
    __block NSManagedObjectID *objectId;
    __block NSManagedObject *fetchedObject;

    NSString *const kTestAttributeKey = @"booleanTestAttribute";

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];

        [inserted setValue:@YES forKey:kTestAttributeKey];

        expect([inserted hasChanges]).to.beTruthy();

        [localContext obtainPermanentIDsForObjects:@[inserted] error:nil];
        objectId = [inserted objectID];
    }];

    NSManagedObjectContext *rootSavingContext = [NSManagedObjectContext MR_rootSavingContext];

    [rootSavingContext performBlockAndWait:^{
        fetchedObject = [[NSManagedObjectContext MR_rootSavingContext] objectWithID:objectId];
        expect([fetchedObject valueForKey:kTestAttributeKey]).to.beTruthy();
    }];

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSManagedObject *changed = [localContext objectWithID:objectId];
        
        [changed setValue:@NO forKey:kTestAttributeKey];
    } completion:^(BOOL contextDidSave, NSError *error) {
        [rootSavingContext performBlockAndWait:^{
            fetchedObject = [rootSavingContext objectWithID:objectId];
            expect(fetchedObject).toNot.beNil();
            expect([fetchedObject valueForKey:kTestAttributeKey]).to.beFalsy();
        }];
    }];
}

#pragma mark - Deprecated Tests
// TA: 4th October 2014 — these tests never completes under Xcode 6, so I'm disabling it. It's removed entirely in MR 3.0.
//
//- (void)testCurrentThreadSynchronousSaveActionSaves
//{
//    __block NSManagedObjectID *objectId;
//
//    [MagicalRecord saveUsingCurrentThreadContextWithBlockAndWait:^(NSManagedObjectContext *localContext) {
//        NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];
//
//        expect([inserted hasChanges]).to.beTruthy();
//
//        [localContext obtainPermanentIDsForObjects:@[inserted] error:nil];
//        objectId = [inserted objectID];
//    }];
//
//    expect(objectId).toNot.beNil();
//
//    XCTestExpectation *rootSavingExpectation = [self expectationWithDescription:@"Root Saving Context Fetch Object"];
//
//    NSManagedObjectContext *rootSavingContext = [NSManagedObjectContext MR_rootSavingContext];
//
//    [rootSavingContext performBlock:^{
//        NSError *fetchError;
//        NSManagedObject *fetchedObject = [rootSavingContext existingObjectWithID:objectId error:&fetchError];
//
//        expect(fetchedObject).toNot.beNil();
//        expect(fetchError).to.beNil();
//        expect([fetchedObject hasChanges]).to.beFalsy();
//
//        [rootSavingExpectation fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:5.0f handler:nil];
//}
//
//- (void)testCurrentThreadAsynchronousSaveActionSaves
//{
//    __block NSManagedObjectID *objectId;
//
//    XCTestExpectation *saveCompleteExpectation = [self expectationWithDescription:@"Save Completed"];
//
//    [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
//        NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];
//
//        expect([inserted hasChanges]).to.beTruthy();
//
//        [localContext obtainPermanentIDsForObjects:@[inserted] error:nil];
//        objectId = [inserted objectID];
//        expect(objectId).toNot.beNil();
//
//    } completion:^(BOOL contextDidSave, NSError *error) {
//        expect(contextDidSave).to.beTruthy();
//        expect(error).to.beNil();
//
//        [saveCompleteExpectation fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:5.0f handler:nil];
//
//    XCTestExpectation *rootSavingExpectation = [self expectationWithDescription:@"Root Saving Context Fetch Object"];
//    NSManagedObjectContext *rootSavingContext = [NSManagedObjectContext MR_rootSavingContext];
//
//    [rootSavingContext performBlock:^{
//        NSManagedObject *fetchedObject = [rootSavingContext objectRegisteredForID:objectId];
//
//        expect(fetchedObject).toNot.beNil();
//        expect([fetchedObject hasChanges]).to.beFalsy();
//
//        [rootSavingExpectation fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:5.0f handler:nil];
//}
//
//- (void)testCurrentThreadAsynchronousSaveActionCallsCompletionBlockOnTheMainThread
//{
//    XCTestExpectation *saveCompleteExpectation = [self expectationWithDescription:@"Save Completed"];
//
//    [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
//        [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];
//    } completion:^(BOOL contextDidSave, NSError *error) {
//        // Ignore the success state — we only care that this block is executed on the main thread
//        expect([NSThread isMainThread]).to.beTruthy();
//
//        [saveCompleteExpectation fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:5.0f handler:nil];
//}

@end
