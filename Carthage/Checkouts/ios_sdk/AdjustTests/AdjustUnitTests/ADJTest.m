//
//  ADJTest.m
//  adjust
//
//  Created by Pedro Filipe on 15/05/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import "ADJTest.h"
#import "ADJAdjustFactory.h"

@implementation ADJTest

- (void)setUp
{
    [super setUp];
    self.loggerMock = [[ADJLoggerMock alloc] init];
}

- (void)tearDown
{
    [super tearDown];
}

@end
