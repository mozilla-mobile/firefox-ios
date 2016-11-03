//
//  ADJFailureResponseData.m
//  adjust
//
//  Created by Pedro Filipe on 05/01/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJSessionFailure.h"

@implementation ADJSessionFailure

+ (ADJSessionFailure *)sessionFailureResponseData {
    return [[ADJSessionFailure alloc] init];
}

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone
{
    ADJSessionFailure* copy = [[[self class] allocWithZone:zone] init];

    if (copy) {
        copy.message            = [self.message copyWithZone:zone];
        copy.timeStamp          = [self.timeStamp copyWithZone:zone];
        copy.adid               = [self.adid copyWithZone:zone];
        copy.willRetry          = self.willRetry;
        copy.jsonResponse       = [self.jsonResponse copyWithZone:zone];
    }

    return copy;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat: @"Session Failure msg:%@ time:%@ adid:%@ retry:%@ json:%@",
            self.message,
            self.timeStamp,
            self.adid,
            self.willRetry ? @"YES" : @"NO",
            self.jsonResponse];
}

@end
