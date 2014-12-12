//
//  ImportMultipleEntitiesWithNoPrimaryKeyTests.m
//  MagicalRecord
//
//  Created by Sérgio Estêvão on 09/01/2014.
//  Copyright (c) 2014 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalDataImportTestCase.h"
#import <XCTest/XCTest.h>
#import "FixtureHelpers.h"
#import "SingleEntityWithNoRelationships.h"

@interface ImportMultipleEntitiesWithNoPrimaryKeyTests : MagicalDataImportTestCase

@property (nonatomic, retain) NSArray * arrayOfTestEntity;

@end

@implementation ImportMultipleEntitiesWithNoPrimaryKeyTests

- (void)setUp
{
    [super setUp];
    
    self.arrayOfTestEntity = [SingleEntityWithNoRelationships MR_importFromArray:self.testEntityData];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testImportOfMultipleEntities
{
    XCTAssertNotNil(self.arrayOfTestEntity, @"arrayOfTestEntity should not be nil");
    XCTAssertEqual(self.arrayOfTestEntity.count, (NSUInteger)4, @"arrayOfTestEntity should have 4 entities");
}

@end
