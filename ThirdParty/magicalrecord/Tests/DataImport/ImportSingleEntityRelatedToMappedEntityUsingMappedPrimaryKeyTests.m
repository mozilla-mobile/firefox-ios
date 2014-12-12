//
//  ImportSingleEntityRelatedToMappedEntityUsingMappedPrimaryKey.m
//  Magical Record
//
//  Created by Saul Mora on 8/11/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MappedEntity.h"
#import "SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey.h"
#import "MagicalDataImportTestCase.h"

@interface ImportSingleEntityRelatedToMappedEntityUsingMappedPrimaryKeyTests : MagicalDataImportTestCase

@end

@implementation ImportSingleEntityRelatedToMappedEntityUsingMappedPrimaryKeyTests

- (void)setupTestData
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];

    MappedEntity *testMappedEntity = [MappedEntity MR_createEntityInContext:context];

    testMappedEntity.testMappedEntityID = @42;
    testMappedEntity.sampleAttribute = @"This attribute created as part of the test case setup";

    [context MR_saveToPersistentStoreAndWait];
}

- (Class)testEntityClass
{
    return [SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey class];
}

- (void)testImportMappedEntityRelatedViaToOneRelationship
{
    SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey *entity = [[self testEntityClass] MR_importFromObject:self.testEntityData];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];

    id testRelatedEntity = entity.mappedEntity;

    //verify mapping in relationship description userinfo
    NSEntityDescription *mappedEntity = [entity entity];
    NSRelationshipDescription *testRelationship = [[mappedEntity propertiesByName] valueForKey:@"mappedEntity"];
    XCTAssertEqualObjects([[testRelationship userInfo] valueForKey:kMagicalRecordImportRelationshipMapKey], @"someRandomAttributeName", @"Expected 'someRandomAttributeName' got '%@'", [[testRelationship userInfo] valueForKey:kMagicalRecordImportRelationshipMapKey]);

    NSNumber *numberOfEntities = [SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey MR_numberOfEntities];
    XCTAssertEqualObjects(numberOfEntities, @1, @"Expected count of 1 entity, got %@", numberOfEntities);

    NSNumber *numberOfMappedEntities = [MappedEntity MR_numberOfEntities];
    XCTAssertEqualObjects(numberOfMappedEntities, @1, @"Expected count of 1 entity, got %@", numberOfMappedEntities);

    XCTAssertNotNil(testRelatedEntity, @"testRelatedEntity should not be nil");

    NSRange stringRange = [[testRelatedEntity sampleAttribute] rangeOfString:@"sample json file"];

    XCTAssertTrue(stringRange.length > 0, @"Did not find 'sample json file' in %@", [testRelatedEntity sampleAttribute]);
}

- (void)testImportMappedEntityUsingPrimaryRelationshipKey
{
    SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey *entity = [[self testEntityClass] MR_importFromObject:self.testEntityData];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];

    id testRelatedEntity = entity.mappedEntity;

    //verify mapping in relationship description userinfo
    NSEntityDescription *mappedEntity = [entity entity];
    NSRelationshipDescription *testRelationship = [[mappedEntity propertiesByName] valueForKey:@"mappedEntity"];
    NSString *mapKey = [[testRelationship userInfo] valueForKey:kMagicalRecordImportRelationshipMapKey];
    XCTAssertEqualObjects(mapKey, @"someRandomAttributeName", @"Expected 'someRandomAttributeName' got '%@'", mapKey);

    NSNumber *entityCount = [SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey MR_numberOfEntities];
    XCTAssertEqualObjects(entityCount, @1, @"Expected count of 1 entity, got %@", entityCount);

    NSNumber *mappedEntityCount = [MappedEntity MR_numberOfEntities];
    XCTAssertEqualObjects(mappedEntityCount, @1, @"Expected count of 1 entity, got %@", mappedEntityCount);

    NSNumber *mappedEntityID = [testRelatedEntity testMappedEntityID];
    XCTAssertEqualObjects(mappedEntityID, @42, @"Expected testMappedEntityID to be '42', got '%@'", mappedEntityID);

    XCTAssertNotNil(testRelatedEntity, @"testRelatedEntity should not be nil");

    NSRange stringRange = [[testRelatedEntity sampleAttribute] rangeOfString:@"sample json file"];
    XCTAssertTrue(stringRange.length > 0, @"Did not find 'sample json file' in %@", [testRelatedEntity sampleAttribute]);
}

@end
