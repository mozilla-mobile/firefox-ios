//
//  Import SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyTests.m
//  Magical Record
//
//  Created by Saul Mora on 8/16/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey.h"
#import "MagicalDataImportTestCase.h"

@interface ImportSingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyTests : MagicalDataImportTestCase

@end

@implementation ImportSingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyTests

- (Class)testEntityClass
{
    return [SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey class];
}

- (void)testImportData
{
    SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *entity = [[self testEntityClass] MR_importFromObject:self.testEntityData];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];

    XCTAssertNotNil(entity, @"Entity should not be nil");

    NSUInteger mappedEntitiesCount = [entity.mappedEntities count];
    XCTAssertEqual(mappedEntitiesCount, (NSUInteger)4, @"Expected 4 mapped entities, received %zd", mappedEntitiesCount);
}

@end
