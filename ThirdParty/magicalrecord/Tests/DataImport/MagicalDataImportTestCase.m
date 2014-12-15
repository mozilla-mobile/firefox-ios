//
//  MagicalDataImportTestCase.m
//  Magical Record
//
//  Created by Saul Mora on 8/16/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalDataImportTestCase.h"
#import "FixtureHelpers.h"

@implementation MagicalDataImportTestCase

- (void)setUp
{
    [super setUp];

    [self setupTestData];

    self.testEntityData = [self dataFromJSONFixture];
}

- (Class)testEntityClass;
{
    return [NSManagedObject class];
}

- (void)setupTestData
{
    // Implement this in your subclasses
}

@end
