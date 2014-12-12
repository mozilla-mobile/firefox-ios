//
//  ImportSingleEntityRelatedToMappedEntityWithSecondaryMappingsTests.m
//  Magical Record
//
//  Created by Saul Mora on 8/18/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//
#import "MagicalDataImportTestCase.h"
#import "SingleEntityRelatedToMappedEntityWithSecondaryMappings.h"
#import "MappedEntity.h"

@interface ImportSingleEntityRelatedToMappedEntityWithSecondaryMappingsTests : MagicalDataImportTestCase

@end

@implementation ImportSingleEntityRelatedToMappedEntityWithSecondaryMappingsTests

- (Class)testEntityClass
{
    return [SingleEntityRelatedToMappedEntityWithSecondaryMappings class];
}

- (void)testImportMappedAttributeUsingSecondaryMappedKeyName
{
    SingleEntityRelatedToMappedEntityWithSecondaryMappings *entity = [[self testEntityClass] MR_importFromObject:self.testEntityData];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];

    XCTAssertNotNil(entity, @"Entity should not be nil");

    NSRange stringRange = [[entity secondaryMappedAttribute] rangeOfString:@"sample json file"];
    XCTAssertTrue(stringRange.length > 0, @"Expected string not contained withing secondary mapped attribute. Got %@", [entity secondaryMappedAttribute]);
}

@end
