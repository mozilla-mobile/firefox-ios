//
//  ADJAttribution.m
//  adjust
//
//  Created by Pedro Filipe on 29/10/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJAttribution.h"
#import "NSString+ADJAdditions.h"
#import "ADJUtil.h"

@implementation ADJAttribution

+ (ADJAttribution *)dataWithJsonDict:(NSDictionary *)jsonDict {
    return [[ADJAttribution alloc] initWithJsonDict:jsonDict];
}

- (id)initWithJsonDict:(NSDictionary *)jsonDict {
    self = [super init];
    if (self == nil) return nil;

    if ([ADJUtil isNull:jsonDict]) {
        return nil;
    }

    self.trackerToken = [jsonDict objectForKey:@"tracker_token"];
    self.trackerName  = [jsonDict objectForKey:@"tracker_name"];
    self.network      = [jsonDict objectForKey:@"network"];
    self.campaign     = [jsonDict objectForKey:@"campaign"];
    self.adgroup      = [jsonDict objectForKey:@"adgroup"];
    self.creative     = [jsonDict objectForKey:@"creative"];
    self.clickLabel   = [jsonDict objectForKey:@"click_label"];

    return self;
}

- (BOOL)isEqualToAttribution:(ADJAttribution *)attribution {
    if (attribution == nil) {
        return NO;
    }
    if (![NSString adjIsEqual:self.trackerToken toString:attribution.trackerToken]) {
        return NO;
    }
    if (![NSString adjIsEqual:self.trackerName toString:attribution.trackerName]) {
        return NO;
    }
    if (![NSString adjIsEqual:self.network toString:attribution.network]) {
        return NO;
    }
    if (![NSString adjIsEqual:self.campaign toString:attribution.campaign]) {
        return NO;
    }
    if (![NSString adjIsEqual:self.adgroup toString:attribution.adgroup]) {
        return NO;
    }
    if (![NSString adjIsEqual:self.creative toString:attribution.creative]) {
        return NO;
    }
    if (![NSString adjIsEqual:self.clickLabel toString:attribution.clickLabel]) {
        return NO;
    }

    return YES;
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *responseDataDic = [NSMutableDictionary dictionary];

    if (self.trackerToken != nil) {
        [responseDataDic setObject:self.trackerToken forKey:@"trackerToken"];
    }

    if (self.trackerName != nil) {
        [responseDataDic setObject:self.trackerName forKey:@"trackerName"];
    }

    if (self.network != nil) {
        [responseDataDic setObject:self.network forKey:@"network"];
    }

    if (self.campaign != nil) {
        [responseDataDic setObject:self.campaign forKey:@"campaign"];
    }

    if (self.adgroup != nil) {
        [responseDataDic setObject:self.adgroup forKey:@"adgroup"];
    }

    if (self.creative != nil) {
        [responseDataDic setObject:self.creative forKey:@"creative"];
    }

    if (self.clickLabel != nil) {
        [responseDataDic setObject:self.clickLabel forKey:@"click_label"];
    }

    return responseDataDic;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"tt:%@ tn:%@ net:%@ cam:%@ adg:%@ cre:%@ cl:%@",
            self.trackerToken, self.trackerName, self.network, self.campaign,
            self.adgroup, self.creative, self.clickLabel];
}


#pragma mark - NSObject
- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[ADJAttribution class]]) {
        return NO;
    }

    return [self isEqualToAttribution:(ADJAttribution *)object];
}

- (NSUInteger)hash {
    return [self.trackerName hash];
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone
{
    ADJAttribution* copy = [[[self class] allocWithZone:zone] init];

    if (copy) {
        copy.trackerToken = [self.trackerToken copyWithZone:zone];
        copy.trackerName  = [self.trackerName copyWithZone:zone];
        copy.network      = [self.network copyWithZone:zone];
        copy.campaign     = [self.campaign copyWithZone:zone];
        copy.adgroup      = [self.adgroup copyWithZone:zone];
        copy.creative     = [self.creative copyWithZone:zone];
        copy.clickLabel   = [self.clickLabel copyWithZone:zone];
    }

    return copy;
}


#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self == nil) return nil;

    self.trackerToken = [decoder decodeObjectForKey:@"trackerToken"];
    self.trackerName  = [decoder decodeObjectForKey:@"trackerName"];
    self.network      = [decoder decodeObjectForKey:@"network"];
    self.campaign     = [decoder decodeObjectForKey:@"campaign"];
    self.adgroup      = [decoder decodeObjectForKey:@"adgroup"];
    self.creative     = [decoder decodeObjectForKey:@"creative"];
    self.clickLabel   = [decoder decodeObjectForKey:@"click_label"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.trackerToken forKey:@"trackerToken"];
    [encoder encodeObject:self.trackerName  forKey:@"trackerName"];
    [encoder encodeObject:self.network      forKey:@"network"];
    [encoder encodeObject:self.campaign     forKey:@"campaign"];
    [encoder encodeObject:self.adgroup      forKey:@"adgroup"];
    [encoder encodeObject:self.creative     forKey:@"creative"];
    [encoder encodeObject:self.clickLabel   forKey:@"click_label"];
}

@end
