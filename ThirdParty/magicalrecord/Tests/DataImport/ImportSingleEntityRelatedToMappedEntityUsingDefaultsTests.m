//
//  ImportSingleEntityRelatedToMappedEntityUsingDefaults.m
//  Magical Record
//
//  Created by Saul Mora on 8/11/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MappedEntity.h"
#import "SingleEntityRelatedToMappedEntityUsingDefaults.h"
#import "MagicalDataImportTestCase.h"

@interface ImportSingleEntityRelatedToMappedEntityUsingDefaultsTests : MagicalDataImportTestCase

@end

@implementation ImportSingleEntityRelatedToMappedEntityUsingDefaultsTests

- (Class)testEntityClass
{
    return [SingleEntityRelatedToMappedEntityUsingDefaults class];
}

- (void)setupTestData
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];

    MappedEntity *testMappedEntity = [MappedEntity MR_createEntityInContext:context];

    testMappedEntity.mappedEntityID = @42;
    testMappedEntity.sampleAttribute = @"This attribute created as part of the test case setup";

    SingleEntityRelatedToMappedEntityUsingDefaults *entity = [SingleEntityRelatedToMappedEntityUsingDefaults MR_createEntityInContext:context];
    entity.singleEntityRelatedToMappedEntityUsingDefaultsID = @24;

    [context MR_saveToPersistentStoreAndWait];
}

- (void)testImportMappedEntityViaToOneRelationship
{
    SingleEntityRelatedToMappedEntityUsingDefaults *entity = [[self testEntityClass] MR_importFromObject:self.testEntityData];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];

    id testRelatedEntity = entity.mappedEntity;

    XCTAssertNotNil(testRelatedEntity, @"Entity should not be nil");

    NSString *string = [testRelatedEntity sampleAttribute];
    NSRange stringRange = [string rangeOfString:@"sample json file"];

    XCTAssert(stringRange.length > 0, @"Could not find 'sample json file' in '%@'", string);

    NSNumber *numberOfEntities = [MappedEntity MR_numberOfEntities];
    XCTAssertEqualObjects(numberOfEntities, @1, @"Expected 1 entity, got %@", numberOfEntities);
}

@end
