//
//  ADJEvent.m
//  adjust
//
//  Created by Pedro Filipe on 15/10/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJEvent.h"
#import "ADJAdjustFactory.h"
#import "ADJUtil.h"

#pragma mark -
@interface ADJEvent()
@property (nonatomic, weak) id<ADJLogger> logger;
@property (nonatomic, strong) NSMutableDictionary* callbackMutableParameters;
@property (nonatomic, strong) NSMutableDictionary* partnerMutableParameters;
@end

@implementation ADJEvent

+ (ADJEvent *)eventWithEventToken:(NSString *)eventToken {
    return [[ADJEvent alloc] initWithEventToken:eventToken];
}

- (id) initWithEventToken:(NSString *)eventToken {
    self = [super init];
    if (self == nil) return nil;

    self.logger = ADJAdjustFactory.logger;

    if (![self checkEventToken:eventToken]) return self;

    _eventToken = eventToken;

    return self;
}

- (void) addCallbackParameter:(NSString *)key
                        value:(NSString *)value
{
    if (![ADJUtil isValidParameter:key
                     attributeType:@"key"
                     parameterName:@"Callback"]) return;

    if (![ADJUtil isValidParameter:value
                     attributeType:@"value"
                     parameterName:@"Callback"]) return;

    if (self.callbackMutableParameters == nil) {
        self.callbackMutableParameters = [[NSMutableDictionary alloc] init];
    }

    if ([self.callbackMutableParameters objectForKey:key]) {
        [self.logger warn:@"key %@ was overwritten", key];
    }

    [self.callbackMutableParameters setObject:value forKey:key];
}

- (void) addPartnerParameter:(NSString *)key
                       value:(NSString *)value {

    if (![ADJUtil isValidParameter:key
                     attributeType:@"key"
                     parameterName:@"Partner"]) return;

    if (![ADJUtil isValidParameter:value
                     attributeType:@"value"
                     parameterName:@"Partner"]) return;

    if (self.partnerMutableParameters == nil) {
        self.partnerMutableParameters = [[NSMutableDictionary alloc] init];
    }

    if ([self.partnerMutableParameters objectForKey:key]) {
        [self.logger warn:@"key %@ was overwritten", key];
    }

    [self.partnerMutableParameters setObject:value forKey:key];
}

- (void) setRevenue:(double) amount currency:(NSString *)currency{
    NSNumber * revenue = [NSNumber numberWithDouble:amount];

    if (![self checkRevenue:revenue currency:currency]) return;

    _revenue = revenue;
    _currency = currency;
}

- (void) setTransactionId:(NSString *)transactionId {
    _transactionId = transactionId;
}

- (NSDictionary *) callbackParameters {
    return (NSDictionary *) self.callbackMutableParameters;
}

- (NSDictionary *) partnerParameters {
    return (NSDictionary *) self.partnerMutableParameters;
}

- (BOOL) checkEventToken:(NSString *)eventToken {
    if ([ADJUtil isNull:eventToken]) {
        [self.logger error:@"Missing Event Token"];
        return NO;
    }

    if (eventToken.length != 6) {
        [self.logger error:@"Malformed Event Token '%@'", eventToken];
        return NO;
    }

    return YES;
}

- (BOOL) checkRevenue:(NSNumber*) revenue
             currency:(NSString*) currency
{
    if (![ADJUtil isNull:revenue]) {
        double amount =  [revenue doubleValue];
        if (amount < 0.0) {
            [self.logger error:@"Invalid amount %.5f", amount];
            return NO;
        }

        if ([ADJUtil isNull:currency]) {
            [self.logger error:@"Currency must be set with revenue"];
            return NO;
        }

        if ([currency isEqualToString:@""]) {
            [self.logger error:@"Currency is empty"];
            return NO;
        }
    } else {
        if ([ADJUtil isNotNull:currency]) {
            [self.logger error:@"Revenue must be set with currency"];
            return NO;
        }
    }

    return YES;
}

- (BOOL) isValid {
    return self.eventToken != nil;
}

- (void) setReceipt:(NSData *)receipt transactionId:(NSString *)transactionId {
    if (![self checkReceipt:receipt transactionId:transactionId]) return;

    if ([ADJUtil isNull:receipt] || [receipt length] == 0) {
        _emptyReceipt = YES;
    }
    _receipt = receipt;
    _transactionId = transactionId;
}

- (BOOL) checkReceipt:(NSData *)receipt transactionId:(NSString *)transactionId {
    if ([ADJUtil isNotNull:receipt] && [ADJUtil isNull:transactionId]) {
        [self.logger error:@"Missing transactionId"];
        return NO;
    }
    return YES;
}

-(id)copyWithZone:(NSZone *)zone
{
    ADJEvent* copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy->_eventToken = [self.eventToken copyWithZone:zone];
        copy->_revenue = [self.revenue copyWithZone:zone];
        copy->_currency = [self.currency copyWithZone:zone];
        copy.callbackMutableParameters = [self.callbackMutableParameters copyWithZone:zone];
        copy.partnerMutableParameters = [self.partnerMutableParameters copyWithZone:zone];
        copy->_transactionId = [self.transactionId copyWithZone:zone];
        copy->_receipt = [self.receipt copyWithZone:zone];
        copy->_emptyReceipt = self.emptyReceipt;
    }
    return copy;
}

@end
