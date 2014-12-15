//
//  MagicalDataImportTestCase.h
//  Magical Record
//
//  Created by Saul Mora on 8/16/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecordTestBase.h"

@interface MagicalDataImportTestCase : MagicalRecordTestBase

@property (nonatomic, strong) id testEntityData;
@property (nonatomic, strong) id testEntity;

- (Class) testEntityClass;
- (void) setupTestData;

@end
