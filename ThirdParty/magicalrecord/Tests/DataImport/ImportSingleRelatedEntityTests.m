//
//  ImportSingleEntityWithRelatedEntitiesTests.m
//  Magical Record
//
//  Created by Saul Mora on 7/23/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalDataImportTestCase.h"
#import "SingleRelatedEntity.h"
#import "AbstractRelatedEntity.h"
#import "ConcreteRelatedEntity.h"
#import "MappedEntity.h"

@interface ImportSingleRelatedEntityTests : MagicalDataImportTestCase

@property (nonatomic, retain) SingleRelatedEntity *singleTestEntity;

@end

@implementation ImportSingleRelatedEntityTests

@synthesize singleTestEntity = _singleTestEntity;

- (void)setupTestData
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];

    MappedEntity *testMappedEntity = [MappedEntity MR_createEntityInContext:context];

    testMappedEntity.testMappedEntityID = @42;
    testMappedEntity.sampleAttribute = @"This attribute created as part of the test case setup";

    [context MR_saveToPersistentStoreAndWait];
}

- (void)setUp
{
    [super setUp];

    self.singleTestEntity = [SingleRelatedEntity MR_importFromObject:self.testEntityData];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

- (void)testImportAnEntityRelatedToAbstractEntityViaToOneRelationshop
{
    XCTAssertNotNil(self.singleTestEntity, @"singleTestEntity should not be nil");

    id testRelatedEntity = self.singleTestEntity.testAbstractToOneRelationship;

    XCTAssertNotNil(testRelatedEntity, @"testRelatedEntity should not be nil");

    NSRange stringRange = [[testRelatedEntity sampleBaseAttribute] rangeOfString:@"BASE"];
    XCTAssertTrue(stringRange.length > 0, @"Expected to find 'BASE' in string '%@' but did not", [testRelatedEntity sampleBaseAttribute]);

    XCTAssertFalse([testRelatedEntity respondsToSelector:@selector(sampleConcreteAttribute)], @"testRelatedEntity should respond to selector sampleConcreteAttribute");
}

- (void)testImportAnEntityRelatedToAbstractEntityViaToManyRelationship
{
    XCTAssertNotNil(self.singleTestEntity, @"singleTestEntity should not be nil");

    NSUInteger relationshipCount = [self.singleTestEntity.testAbstractToManyRelationship count];
    XCTAssertEqual(relationshipCount, (NSUInteger)2, @"Expected relationship count to be 2, received %zd", relationshipCount);

    id testRelatedEntity = [self.singleTestEntity.testAbstractToManyRelationship anyObject];

    XCTAssertNotNil(testRelatedEntity, @"testRelatedEntity should not be nil");

    NSRange stringRange = [[testRelatedEntity sampleBaseAttribute] rangeOfString:@"BASE"];
    XCTAssertTrue(stringRange.length > 0, @"Expected to find 'BASE' in string '%@' but did not", [testRelatedEntity sampleBaseAttribute]);

    XCTAssertFalse([testRelatedEntity respondsToSelector:@selector(sampleConcreteAttribute)], @"testRelatedEntity should respond to selector sampleConcreteAttribute");
}

#pragma mark - Subentity tests

- (void)testImportAnEntityRelatedToAConcreteSubEntityViaToOneRelationship
{
    id testRelatedEntity = self.singleTestEntity.testConcreteToOneRelationship;

    XCTAssertNotNil(testRelatedEntity, @"testRelatedEntity should not be nil");

    NSRange stringRange = [[testRelatedEntity sampleBaseAttribute] rangeOfString:@"BASE"];
    XCTAssertTrue(stringRange.length > 0, @"Expected to find 'BASE' in string '%@' but did not", [testRelatedEntity sampleBaseAttribute]);

    stringRange = [[testRelatedEntity sampleConcreteAttribute] rangeOfString:@"DESCENDANT"];
    XCTAssertTrue(stringRange.length > 0, @"Expected to find 'DESCENDANT' in string '%@' but did not", [testRelatedEntity sampleConcreteAttribute]);
}

- (void)testImportAnEntityRelatedToASubEntityViaToManyRelationship
{
    NSUInteger relationshipCount = [self.singleTestEntity.testConcreteToManyRelationship count];
    XCTAssertEqual(relationshipCount, (NSUInteger)3, @"Expected relationship count to be 3, received %zd", relationshipCount);

    id testRelatedEntity = [self.singleTestEntity.testConcreteToManyRelationship anyObject];
    XCTAssertNotNil(testRelatedEntity, @"testRelatedEntity should not be nil");

    NSRange stringRange = [[testRelatedEntity sampleBaseAttribute] rangeOfString:@"BASE"];
    XCTAssertTrue(stringRange.length > 0, @"Expected to find 'BASE' in string '%@' but did not", [testRelatedEntity sampleBaseAttribute]);

    stringRange = [[testRelatedEntity sampleConcreteAttribute] rangeOfString:@"DESCENDANT"];
    XCTAssertTrue(stringRange.length > 0, @"Expected to find 'DESCENDANT' in string '%@' but did not", [testRelatedEntity sampleConcreteAttribute]);
}

// TODO: Test ordered to many relationships

@end
