//
//  ImportSingleEntityRelatedToManyMappedEntitiesUsingListOfPrimaryKeysTests.m
//  Magical Record
//
//  Created by Saul Mora on 9/1/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalDataImportTestCase.h"
#import "MappedEntity.h"
#import "SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey.h"

@interface ImportSingleEntityRelatedToManyMappedEntitiesUsingListOfPrimaryKeysTests : MagicalDataImportTestCase

@end

@implementation ImportSingleEntityRelatedToManyMappedEntitiesUsingListOfPrimaryKeysTests

- (Class) testEntityClass
{
    return [SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey class];
}

- (void) setupTestData
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];

    MappedEntity *related = nil;
    for (int i = 0; i < 10; i++) 
    {
        MappedEntity *testMappedEntity = [MappedEntity createInContext:context];
        testMappedEntity.testMappedEntityIDValue = i;
        testMappedEntity.sampleAttribute = [NSString stringWithFormat:@"test attribute %d", i];
        related = testMappedEntity;
    }
    
    SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *entity = [SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey createInContext:context];
    entity.testPrimaryKeyValue = 84;
    [entity addMappedEntitiesObject:related];
    
    [context MR_saveToPersistentStoreAndWait];
}

- (void) testDataImportUsingListOfPrimaryKeyIDs
{
    SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *testEntity = [[self testEntityClass] MR_importFromObject:self.testEntityData];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    assertThat([SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey numberOfEntities], is(equalToInteger(1)));
    assertThat([MappedEntity numberOfEntities], is(equalToInteger(10)));

    assertThat(testEntity.mappedEntities, hasCountOf(5));
    for (MappedEntity *relatedEntity in testEntity.mappedEntities)
    {
        assertThat(relatedEntity.sampleAttribute, containsString(@"test attribute"));
    }
}

//- (void) testDataUpdateWithLookupInfoInDataSet
//{
//    SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *testEntity = [[self testEntityClass] MR_updateFromObject:self.testEntityData];
//    [[NSManagedObjectContext MR_defaultContext] MR_save];
//
//    assertThat([SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey numberOfEntities], is(equalToInteger(1)));
//    assertThat([MappedEntity numberOfEntities], is(equalToInteger(10)));
//               
//    assertThat(testEntity, is(notNilValue()));
//    assertThat(testEntity.testPrimaryKey, is(equalToInteger(84)));
//    assertThat(testEntity.mappedEntities, hasCountOf(5));
//
//    for (MappedEntity *relatedEntity in testEntity.mappedEntities)
//    {
//        assertThat(relatedEntity.sampleAttribute, containsString(@"test attribute"));
//    }
//}

//- (void) testDataUpdateWithoutLookupData
//{
//    SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *testEntity =
//    [SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey findFirstByAttribute:@"testPrimaryKey" withValue:[NSNumber numberWithInt:84]];
//    
//    assertThat(testEntity, is(notNilValue()));
//    
//    [testEntity MR_updateValuesForKeysWithObject:self.testEntityData];
//}

@end
