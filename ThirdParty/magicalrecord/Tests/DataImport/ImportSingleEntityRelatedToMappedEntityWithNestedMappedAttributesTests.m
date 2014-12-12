//
//  ImportSingleEntityRelatedToMappedEntityWithNestedMappedAttributesTests.m
//  Magical Record
//
//  Created by Saul Mora on 8/16/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalDataImportTestCase.h"
#import "MappedEntity.h"
#import "SingleEntityRelatedToMappedEntityWithNestedMappedAttributes.h"

@interface ImportSingleEntityRelatedToMappedEntityWithNestedMappedAttributesTests : MagicalDataImportTestCase

@end

@implementation ImportSingleEntityRelatedToMappedEntityWithNestedMappedAttributesTests

- (Class)testEntityClass
{
    return [SingleEntityRelatedToMappedEntityWithNestedMappedAttributes class];
}

- (void)testDataImport
{
    SingleEntityRelatedToMappedEntityWithNestedMappedAttributes *entity = [[self testEntityClass] MR_importFromObject:self.testEntityData];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];

    XCTAssertNotNil(entity.mappedEntity, @"mappedEntity should not be nil");
    XCTAssertEqualObjects(entity.mappedEntity.mappedEntityID, @42, @"Expected mappedEntityID to be 42, got %@", entity.mappedEntity.mappedEntityID);

    NSRange stringRange = [entity.mappedEntity.nestedAttribute rangeOfString:@"nested value"];
    XCTAssertTrue(stringRange.length > 0, @"nestedAttribute did not contain 'nested value': %@", entity.mappedEntity.nestedAttribute);
}

@end
