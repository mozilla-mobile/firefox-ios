//
//  ADJActivityState.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-02.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJActivityState.h"
#import "UIDevice+ADJAdditions.h"

static const int kTransactionIdCount = 10;

#pragma mark public implementation
@implementation ADJActivityState

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    // create UUID for new devices
    self.uuid = [UIDevice.currentDevice adjCreateUuid];

    self.eventCount      = 0;
    self.sessionCount    = 0;
    self.subsessionCount = -1; // -1 means unknown
    self.sessionLength   = -1;
    self.timeSpent       = -1;
    self.lastActivity    = -1;
    self.lastInterval    = -1;
    self.transactionIds  = [NSMutableArray arrayWithCapacity:kTransactionIdCount];
    self.enabled         = YES;
    self.askingAttribution           = NO;

    return self;
}

- (void)resetSessionAttributes:(double)now {
    self.subsessionCount = 1;
    self.sessionLength   = 0;
    self.timeSpent       = 0;
    self.lastActivity    = now;
    self.lastInterval    = -1;
}

- (void)addTransactionId:(NSString *)transactionId {
    if (self.transactionIds == nil) { // create array
        self.transactionIds = [NSMutableArray arrayWithCapacity:kTransactionIdCount];
    }

    if (self.transactionIds.count == kTransactionIdCount) {
        [self.transactionIds removeObjectAtIndex:0]; // make space
    }

    [self.transactionIds addObject:transactionId]; // add new ID
}

- (BOOL)findTransactionId:(NSString *)transactionId {
    return [self.transactionIds containsObject:transactionId];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ec:%d sc:%d ssc:%d ask:%d sl:%.1f ts:%.1f la:%.1f",
            self.eventCount, self.sessionCount, self.subsessionCount, self.askingAttribution, self.sessionLength,
            self.timeSpent, self.lastActivity];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self == nil) return nil;

    self.eventCount        = [decoder decodeIntForKey:@"eventCount"];
    self.sessionCount      = [decoder decodeIntForKey:@"sessionCount"];
    self.subsessionCount   = [decoder decodeIntForKey:@"subsessionCount"];
    self.sessionLength     = [decoder decodeDoubleForKey:@"sessionLength"];
    self.timeSpent         = [decoder decodeDoubleForKey:@"timeSpent"];
    self.lastActivity      = [decoder decodeDoubleForKey:@"lastActivity"];

    // default values for migrating devices
    if ([decoder containsValueForKey:@"uuid"]) {
        self.uuid              = [decoder decodeObjectForKey:@"uuid"];
    }

    if (self.uuid == nil) {
        self.uuid = [UIDevice.currentDevice adjCreateUuid];
    }

    if ([decoder containsValueForKey:@"transactionIds"]) {
        self.transactionIds    = [decoder decodeObjectForKey:@"transactionIds"];
    }

    if (self.transactionIds == nil) {
        self.transactionIds = [NSMutableArray arrayWithCapacity:kTransactionIdCount];
    }

    if ([decoder containsValueForKey:@"enabled"]) {
        self.enabled           = [decoder decodeBoolForKey:@"enabled"];
    } else {
        self.enabled = YES;
    }

    if ([decoder containsValueForKey:@"askingAttribution"]) {
        self.askingAttribution = [decoder decodeBoolForKey:@"askingAttribution"];
    } else {
        self.askingAttribution = NO;
    }

    self.lastInterval = -1;

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:self.eventCount         forKey:@"eventCount"];
    [encoder encodeInt:self.sessionCount       forKey:@"sessionCount"];
    [encoder encodeInt:self.subsessionCount    forKey:@"subsessionCount"];
    [encoder encodeDouble:self.sessionLength   forKey:@"sessionLength"];
    [encoder encodeDouble:self.timeSpent       forKey:@"timeSpent"];
    [encoder encodeDouble:self.lastActivity    forKey:@"lastActivity"];
    [encoder encodeObject:self.uuid            forKey:@"uuid"];
    [encoder encodeObject:self.transactionIds  forKey:@"transactionIds"];
    [encoder encodeBool:self.enabled           forKey:@"enabled"];
    [encoder encodeBool:self.askingAttribution forKey:@"askingAttribution"];
}

-(id)copyWithZone:(NSZone *)zone
{
    ADJActivityState* copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy.sessionCount      = self.sessionCount;
        copy.subsessionCount   = self.subsessionCount;
        copy.sessionLength     = self.sessionLength;
        copy.timeSpent         = self.timeSpent;
        copy.uuid              = [self.uuid copyWithZone:zone];
        copy.lastInterval      = self.lastInterval;
        copy.eventCount        = self.eventCount;
        copy.enabled           = self.enabled;
        copy.lastActivity      = self.lastActivity;
        copy.askingAttribution = self.askingAttribution;
        // transactionIds not copied
    }
    
    return copy;
}

@end
