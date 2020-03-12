//
//  ADJSuccessResponseData.m
//  adjust
//
//  Created by Pedro Filipe on 05/01/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJSessionSuccess.h"

@implementation ADJSessionSuccess

#pragma mark - Public methods

- (id)init {
    self = [super init];
    
    if (self == nil) {
        return nil;
    }

    return self;
}

+ (ADJSessionSuccess *)sessionSuccessResponseData {
    return [[ADJSessionSuccess alloc] init];
}

#pragma mark - NSCopying protocol methods

- (id)copyWithZone:(NSZone *)zone {
    ADJSessionSuccess *copy = [[[self class] allocWithZone:zone] init];

    if (copy) {
        copy.message = [self.message copyWithZone:zone];
        copy.timeStamp = [self.timeStamp copyWithZone:zone];
        copy.adid = [self.adid copyWithZone:zone];
        copy.jsonResponse = [self.jsonResponse copyWithZone:zone];
    }

    return copy;
}

#pragma mark - NSObject protocol methods

- (NSString *)description {
    return [NSString stringWithFormat: @"Session Success msg:%@ time:%@ adid:%@ json:%@",
            self.message,
            self.timeStamp,
            self.adid,
            self.jsonResponse];
}

@end
