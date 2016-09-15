//
//  ADJDelegateTest.m
//  adjust
//
//  Created by Pedro Filipe on 10/12/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJDelegateTest.h"
#import "ADJLoggerMock.h"
#import "ADJAdjustFactory.h"

static NSString * const prefix = @"ADJDelegateTest ";

@interface ADJDelegateTest()

@property (nonatomic, strong) ADJLoggerMock *loggerMock;

@end

@implementation ADJDelegateTest

- (id) init {
    self = [super init];
    if (self == nil) return nil;

    self.loggerMock = (ADJLoggerMock *) [ADJAdjustFactory logger];

    [self.loggerMock test:[prefix stringByAppendingFormat:@"init"]];

    return self;
}

- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"adjustAttributionChanged, %@", attribution]];
}

@end
