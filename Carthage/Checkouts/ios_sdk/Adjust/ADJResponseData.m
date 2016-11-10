//
//  ADJResponseData.m
//  adjust
//
//  Created by Pedro Filipe on 07/12/15.
//  Copyright © 2015 adjust GmbH. All rights reserved.
//

#import "ADJResponseData.h"
#import "ADJActivityKind.h"

@implementation ADJResponseData

+ (ADJResponseData *)responseData {
    return [[ADJResponseData alloc] init];
}

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    return self;
}

+ (id)buildResponseData:(ADJActivityPackage *)activityPackage {
    if (activityPackage == nil) {
        return [[ADJUnknowResponseData alloc] init];
    }

    ADJResponseData * responseData = nil;

    switch (activityPackage.activityKind) {
        case ADJActivityKindSession:
            responseData = [[ADJSessionResponseData alloc] init];
            break;
        case ADJActivityKindEvent:
            responseData = [[ADJEventResponseData alloc] initWithActivityPackage:activityPackage];
            break;
        case ADJActivityKindClick:
            responseData = [[ADJClickResponseData alloc] init];
            break;
        case ADJActivityKindAttribution:
            responseData = [[ADJAttributionResponseData alloc] init];
            break;
        default:
            responseData = [[ADJUnknowResponseData alloc] init];
            break;
    }

    responseData.activityKind = activityPackage.activityKind;

    return responseData;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"message:%@ timestamp:%@ adid:%@ success:%d willRetry:%d attribution:%@ json:%@",
            self.message, self.timeStamp, self.adid, self.success, self.willRetry, self.attribution, self.jsonResponse];
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone
{
    ADJResponseData* copy = [[[self class] allocWithZone:zone] init];

    if (copy) {
        copy.message      = [self.message copyWithZone:zone];
        copy.timeStamp    = [self.timeStamp copyWithZone:zone];
        copy.adid         = [self.adid copyWithZone:zone];
        copy.success      = self.success;
        copy.willRetry    = self.willRetry;
        copy.jsonResponse = [self.jsonResponse copyWithZone:zone];
        copy.attribution  = [self.attribution copyWithZone:zone];
    }

    return copy;
}

@end

@implementation ADJSessionResponseData

- (id)initWithActivityPackage:(ADJActivityPackage *)activityPackage {
    self = [super init];
    if (self == nil) return nil;

    return self;
}

- (ADJSessionSuccess *)successResponseData {
    ADJSessionSuccess * successResponseData = [ADJSessionSuccess sessionSuccessResponseData];
    successResponseData.message = self.message;
    successResponseData.timeStamp = self.timeStamp;
    successResponseData.adid = self.adid;
    successResponseData.jsonResponse = self.jsonResponse;

    return successResponseData;
}

- (ADJSessionFailure *)failureResponseData {
    ADJSessionFailure * failureResponseData = [ADJSessionFailure sessionFailureResponseData];
    failureResponseData.message = self.message;
    failureResponseData.timeStamp = self.timeStamp;
    failureResponseData.adid = self.adid;
    failureResponseData.willRetry = self.willRetry;
    failureResponseData.jsonResponse = self.jsonResponse;

    return failureResponseData;
}

-(id)copyWithZone:(NSZone *)zone
{
    ADJSessionResponseData* copy = [super copyWithZone:zone];
    return copy;
}

@end

@implementation ADJEventResponseData

+ (ADJEventResponseData *)responseDataWithActivityPackage:(ADJActivityPackage *)activityPackage {
    return [[ADJEventResponseData alloc] initWithActivityPackage:activityPackage];
}

- (id)initWithActivityPackage:(ADJActivityPackage *)activityPackage {
    self = [super init];
    if (self == nil) return nil;

    self.eventToken = [activityPackage.parameters objectForKey:@"event_token"];

    return self;
}

- (ADJEventSuccess *)successResponseData {
    ADJEventSuccess * successResponseData = [ADJEventSuccess eventSuccessResponseData];
    successResponseData.message = self.message;
    successResponseData.timeStamp = self.timeStamp;
    successResponseData.adid = self.adid;
    successResponseData.eventToken = self.eventToken;
    successResponseData.jsonResponse = self.jsonResponse;

    return successResponseData;
}

- (ADJEventFailure *)failureResponseData {
    ADJEventFailure * failureResponseData = [ADJEventFailure eventFailureResponseData];
    failureResponseData.message = self.message;
    failureResponseData.timeStamp = self.timeStamp;
    failureResponseData.adid = self.adid;
    failureResponseData.eventToken = self.eventToken;
    failureResponseData.willRetry = self.willRetry;
    failureResponseData.jsonResponse = self.jsonResponse;

    return failureResponseData;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"message:%@ timestamp:%@ adid:%@ eventToken:%@ success:%d willRetry:%d attribution:%@ json:%@",
            self.message, self.timeStamp, self.adid, self.eventToken, self.success, self.willRetry, self.attribution, self.jsonResponse];
}

-(id)copyWithZone:(NSZone *)zone
{
    ADJEventResponseData* copy = [super copyWithZone:zone];

    if (copy) {
        copy.eventToken   = [self.eventToken copyWithZone:zone];
    }

    return copy;
}

@end

@implementation ADJAttributionResponseData

- (id)initWithActivityPackage:(ADJActivityPackage *)activityPackage {
    self = [super init];
    if (self == nil) return nil;

    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    ADJAttributionResponseData* copy = [super copyWithZone:zone];
    return copy;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"message:%@ timestamp:%@ adid:%@ success:%d willRetry:%d attribution:%@ deeplink:%@ json:%@",
            self.message, self.timeStamp, self.adid, self.success, self.willRetry, self.attribution, self.deeplink, self.jsonResponse];
}


@end

@implementation ADJClickResponseData

- (id)initWithActivityPackage:(ADJActivityPackage *)activityPackage {
    self = [super init];
    if (self == nil) return nil;

    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    ADJClickResponseData* copy = [super copyWithZone:zone];
    return copy;
}

@end

@implementation ADJUnknowResponseData

- (id)initWithActivityPackage:(ADJActivityPackage *)activityPackage {
    self = [super init];
    if (self == nil) return nil;

    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    ADJUnknowResponseData* copy = [super copyWithZone:zone];
    return copy;
}

@end
