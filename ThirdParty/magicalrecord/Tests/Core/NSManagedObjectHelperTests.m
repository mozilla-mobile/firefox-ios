//
//  NSManagedObjectHelperTests.m
//  Magical Record
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecordTestBase.h"
#import "SingleRelatedEntity.h"

@interface NSManagedObjectHelperTests : MagicalRecordTestBase

@end

@implementation NSManagedObjectHelperTests

- (void)testCreateFetchRequestForEntity
{
    NSFetchRequest *testRequest = [SingleRelatedEntity MR_requestAll];

    XCTAssertEqualObjects([[testRequest entity] name], NSStringFromClass([SingleRelatedEntity class]), @"Entity name should be the string representation of the entity's class");
}

- (void)testCanRequestFirstEntityWithPredicate
{
    NSPredicate *testPredicate = [NSPredicate predicateWithFormat:@"mappedStringAttribute = 'Test Predicate'"];
    NSFetchRequest *testRequest = [SingleRelatedEntity MR_requestFirstWithPredicate:testPredicate];

    XCTAssertEqual([testRequest fetchLimit], (NSUInteger)1, @"Fetch limit should be 1, got: %tu", [testRequest fetchLimit]);
    XCTAssertEqualObjects([testRequest predicate], [NSPredicate predicateWithFormat:@"mappedStringAttribute = 'Test Predicate'"], @"Predicate objects should be equal");
}

- (void)testCreateRequestForFirstEntity
{
    NSFetchRequest *testRequest = [SingleRelatedEntity MR_requestFirstByAttribute:@"mappedStringAttribute" withValue:nil];

    XCTAssertEqualObjects([[testRequest entity] name], NSStringFromClass([SingleRelatedEntity class]), @"Entity name should be the string representation of the entity's class");
    XCTAssertEqual([testRequest fetchLimit], (NSUInteger)1, @"Fetch limit should be 1, got: %tu", [testRequest fetchLimit]);
    XCTAssertEqual([testRequest fetchOffset], (NSUInteger)0, @"Fetch offset should be 0, got: %tu", [testRequest fetchOffset]);
    XCTAssertEqualObjects([testRequest predicate], [NSPredicate predicateWithFormat:@"mappedStringAttribute = nil"], @"Predicate objects should be equal");
}

- (void)testCanGetEntityDescriptionFromEntityClass
{
    NSEntityDescription *testDescription = [SingleRelatedEntity MR_entityDescription];

    XCTAssertNotNil(testDescription, @"Entity description should not be nil");
}

- (void)testCanCreateEntityInstance
{
    id testEntity = [SingleRelatedEntity MR_createEntity];

    XCTAssertNotNil(testEntity, @"Entity should not be nil");
}

- (void)testCanDeleteEntityInstance
{
    id testEntity = [SingleRelatedEntity MR_createEntity];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];

    XCTAssertFalse([testEntity isDeleted], @"Entity should not return true for isDeleted before MR_deleteEntity is sent");

    [testEntity MR_deleteEntity];

    XCTAssertNotNil(testEntity, @"Entity should not be nil after calling MR_deleteEntity");
    XCTAssertTrue([testEntity isDeleted], @"Entity should return true for isDeleted before MR_deleteEntity is sent");
}

- (void)testCanSearchForNumberOfAllEntities
{
    NSInteger numberOfTestEntitiesToCreate = 20;

    [self p_createSampleData:numberOfTestEntitiesToCreate];

    NSNumber *entityCount = [SingleRelatedEntity MR_numberOfEntities];
    XCTAssertEqualObjects(entityCount, @(numberOfTestEntitiesToCreate), @"Expected numberOfEntities to be %zd, got %@", numberOfTestEntitiesToCreate, entityCount);
}

- (void)testCanSearchForNumberOfEntitiesWithPredicate
{
    NSInteger numberOfTestEntitiesToCreate = 20;

    [self p_createSampleData:numberOfTestEntitiesToCreate];

    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"mappedStringAttribute = '1'"];
    NSNumber *entityCount = [SingleRelatedEntity MR_numberOfEntitiesWithPredicate:searchFilter];
    XCTAssertEqualObjects(entityCount, @5, @"Should return a count of 5, got %@", entityCount);
}

- (void)testRetrieveInstanceOfManagedObjectFromAnotherContextHasAPermanentObjectID
{
    NSManagedObject *insertedEntity = [SingleRelatedEntity MR_createEntity];

    XCTAssertTrue([[insertedEntity objectID] isTemporaryID], @"Object ID should be temporary until saved");

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSManagedObject *localEntity = [insertedEntity MR_inContext:localContext];
        XCTAssertFalse([[localEntity objectID] isTemporaryID], @"Object ID should not be temporary after save");
    }];
}

- (void)testCanDeleteEntityInstanceInOtherContext
{
    NSManagedObjectContext *defaultContext = [NSManagedObjectContext MR_defaultContext];

    [defaultContext performBlockAndWait:^{
        NSManagedObject *testEntity = [SingleRelatedEntity MR_createEntityInContext:defaultContext];

        [defaultContext MR_saveToPersistentStoreAndWait];

        XCTAssertFalse([testEntity isDeleted], @"Entity should not be deleted at this point");

        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            NSManagedObject *otherEntity = [testEntity MR_inContext:localContext];

            XCTAssertNotNil(otherEntity, @"Entity should not be nil");
            XCTAssertFalse([otherEntity isDeleted], @"Entity should not be deleted at this point");

            // Delete the object in the other context
            [testEntity MR_deleteEntityInContext:localContext];
            [localContext processPendingChanges];

            // The nested context entity should now be deleted
            XCTAssertTrue([localContext.deletedObjects containsObject:otherEntity], @"Entity should be listed as being deleted in the context");
            XCTAssertTrue([otherEntity isDeleted], @"Entity should now be deleted");
        }];
    }];
}

#pragma mark - Private Methods

- (void)p_createSampleData:(NSInteger)numberOfTestEntitiesToCreate
{
    for (int i = 0; i < numberOfTestEntitiesToCreate; i++) {
        SingleRelatedEntity *testEntity = [SingleRelatedEntity MR_createEntity];
        testEntity.mappedStringAttribute = [NSString stringWithFormat:@"%d", i / 5];
    }

    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfAndWait];
}

@end
