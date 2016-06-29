//
//  ADJPackageBuilder.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-03.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJPackageBuilder.h"
#import "ADJActivityPackage.h"
#import "ADJUtil.h"
#import "ADJAttribution.h"
#import "NSData+ADJAdditions.h"

@interface ADJPackageBuilder()

@property (nonatomic, copy) ADJDeviceInfo* deviceInfo;
@property (nonatomic, copy) ADJActivityState *activityState;
@property (nonatomic, copy) ADJConfig *adjustConfig;
@property (nonatomic, assign) double createdAt;

@end

#pragma mark -
@implementation ADJPackageBuilder

- (id)initWithDeviceInfo:(ADJDeviceInfo *)deviceInfo
           activityState:(ADJActivityState *)activityState
                  config:(ADJConfig *)adjustConfig
               createdAt:(double)createdAt
{
    self = [super init];
    if (self == nil) return nil;

    self.deviceInfo = deviceInfo;
    self.activityState = activityState;
    self.adjustConfig = adjustConfig;
    self.createdAt = createdAt;

    return self;
}

- (ADJActivityPackage *)buildSessionPackage {
    NSMutableDictionary *parameters = [self defaultParameters];
    [self parameters:parameters setDuration:self.activityState.lastInterval forKey:@"last_interval"];
    [self parameters:parameters setString:self.adjustConfig.defaultTracker forKey:@"default_tracker"];

    ADJActivityPackage *sessionPackage = [self defaultActivityPackage];
    sessionPackage.path = @"/session";
    sessionPackage.activityKind = ADJActivityKindSession;
    sessionPackage.suffix = @"";
    sessionPackage.parameters = parameters;

    return sessionPackage;
}

- (ADJActivityPackage *)buildEventPackage:(ADJEvent *) event{
    NSMutableDictionary *parameters = [self defaultParameters];
    [self parameters:parameters setInt:self.activityState.eventCount forKey:@"event_count"];
    [self parameters:parameters setNumber:event.revenue forKey:@"revenue"];
    [self parameters:parameters setString:event.currency forKey:@"currency"];
    [self parameters:parameters setString:event.eventToken forKey:@"event_token"];

    [self parameters:parameters setDictionary:event.callbackParameters forKey:@"callback_params"];
    [self parameters:parameters setDictionary:event.partnerParameters forKey:@"partner_params"];

    if (event.emptyReceipt) {
        NSString *emptyReceipt = @"empty";
        [self parameters:parameters setString:emptyReceipt forKey:@"receipt"];
        [self parameters:parameters setString:event.transactionId forKey:@"transaction_id"];
    }
    else if (event.receipt != nil) {
        NSString *receiptBase64 = [event.receipt adjEncodeBase64];
        [self parameters:parameters setString:receiptBase64 forKey:@"receipt"];
        [self parameters:parameters setString:event.transactionId forKey:@"transaction_id"];
    }

    ADJActivityPackage *eventPackage = [self defaultActivityPackage];
    eventPackage.path = @"/event";
    eventPackage.activityKind = ADJActivityKindEvent;
    eventPackage.suffix = [self eventSuffix:event];
    eventPackage.parameters = parameters;

    return eventPackage;
}

- (ADJActivityPackage *)buildClickPackage:(NSString *)clickSource
{
    NSMutableDictionary *parameters = [self idsParameters];

    [self parameters:parameters setString:clickSource                     forKey:@"source"];
    [self parameters:parameters setDictionary:self.deeplinkParameters forKey:@"params"];
    [self parameters:parameters setDate:self.clickTime                    forKey:@"click_time"];
    [self parameters:parameters setDate:self.purchaseTime                 forKey:@"purchase_time"];

    if (self.attribution != nil) {
        [self parameters:parameters setString:self.attribution.trackerName  forKey:@"tracker"];
        [self parameters:parameters setString:self.attribution.campaign     forKey:@"campaign"];
        [self parameters:parameters setString:self.attribution.adgroup      forKey:@"adgroup"];
        [self parameters:parameters setString:self.attribution.creative     forKey:@"creative"];
    }
    [self parameters:parameters setDictionary:self.iadDetails forKey:@"details"];

    ADJActivityPackage *clickPackage = [self defaultActivityPackage];
    clickPackage.path = @"/sdk_click";
    clickPackage.activityKind = ADJActivityKindClick;
    clickPackage.suffix = @"";
    clickPackage.parameters = parameters;

    return clickPackage;
}

- (ADJActivityPackage *)buildAttributionPackage {
    NSMutableDictionary *parameters = [self idsParameters];

    ADJActivityPackage *attributionPackage = [self defaultActivityPackage];
    attributionPackage.path = @"/attribution";
    attributionPackage.activityKind = ADJActivityKindAttribution;
    attributionPackage.suffix = @"";
    attributionPackage.parameters = parameters;

    return attributionPackage;
}

#pragma mark private
- (ADJActivityPackage *)defaultActivityPackage {
    ADJActivityPackage *activityPackage = [[ADJActivityPackage alloc] init];
    activityPackage.clientSdk = self.deviceInfo.clientSdk;
    return activityPackage;
}

- (NSMutableDictionary *)idsParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [self injectDeviceInfoIds:self.deviceInfo
               intoParameters:parameters];
    [self injectConfig:self.adjustConfig intoParameters:parameters];
    [self injectCreatedAt:self.createdAt intoParameters:parameters];

    return parameters;
}

- (NSMutableDictionary *)defaultParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [self injectDeviceInfo:self.deviceInfo
            intoParameters:parameters];
    [self injectConfig:self.adjustConfig intoParameters:parameters];
    [self injectActivityState:self.activityState intoParamters:parameters];
    [self injectCreatedAt:self.createdAt intoParameters:parameters];

    return parameters;
}

- (void) injectDeviceInfoIds:(ADJDeviceInfo *)deviceInfo
           intoParameters:(NSMutableDictionary *) parameters
{
    [self parameters:parameters setString:deviceInfo.idForAdvertisers  forKey:@"idfa"];
    [self parameters:parameters setString:deviceInfo.vendorId          forKey:@"idfv"];
}

- (void) injectDeviceInfo:(ADJDeviceInfo *)deviceInfo
           intoParameters:(NSMutableDictionary *) parameters
{
    [self injectDeviceInfoIds:deviceInfo
               intoParameters:parameters];
    [self parameters:parameters setString:deviceInfo.fbAttributionId   forKey:@"fb_id"];
    [self parameters:parameters setInt:deviceInfo.trackingEnabled      forKey:@"tracking_enabled"];
    [self parameters:parameters setString:deviceInfo.pushToken         forKey:@"push_token"];
    [self parameters:parameters setString:deviceInfo.bundeIdentifier   forKey:@"bundle_id"];
    [self parameters:parameters setString:deviceInfo.bundleVersion     forKey:@"app_version"];
    [self parameters:parameters setString:deviceInfo.bundleShortVersion forKey:@"app_version_short"];
    [self parameters:parameters setString:deviceInfo.deviceType        forKey:@"device_type"];
    [self parameters:parameters setString:deviceInfo.deviceName        forKey:@"device_name"];
    [self parameters:parameters setString:deviceInfo.osName            forKey:@"os_name"];
    [self parameters:parameters setString:deviceInfo.systemVersion     forKey:@"os_version"];
    [self parameters:parameters setString:deviceInfo.languageCode      forKey:@"language"];
    [self parameters:parameters setString:deviceInfo.countryCode       forKey:@"country"];
}

- (void)injectConfig:(ADJConfig*) adjustConfig
       intoParameters:(NSMutableDictionary *) parameters
{
    [self parameters:parameters setString:adjustConfig.appToken        forKey:@"app_token"];
    [self parameters:parameters setString:adjustConfig.environment     forKey:@"environment"];
    [self parameters:parameters setBool:adjustConfig.hasDelegate forKey:@"needs_attribution_data"];
}

- (void) injectActivityState:(ADJActivityState *)activityState
               intoParamters:(NSMutableDictionary *)parameters {
    [self parameters:parameters setInt:activityState.sessionCount       forKey:@"session_count"];
    [self parameters:parameters setInt:activityState.subsessionCount    forKey:@"subsession_count"];
    [self parameters:parameters setDuration:activityState.sessionLength forKey:@"session_length"];
    [self parameters:parameters setDuration:activityState.timeSpent     forKey:@"time_spent"];
    [self parameters:parameters setString:activityState.uuid            forKey:@"ios_uuid"];

}

- (void)injectCreatedAt:(double) createdAt
      intoParameters:(NSMutableDictionary *) parameters
{
    [self parameters:parameters setDate1970:createdAt forKey:@"created_at"];
}

- (NSString *)eventSuffix:(ADJEvent*)event {
    if (event.revenue == nil) {
        return [NSString stringWithFormat:@"'%@'", event.eventToken];
    } else {
        return [NSString stringWithFormat:@"(%.5f %@, '%@')", [event.revenue doubleValue], event.currency, event.eventToken];
    }
}

- (void)parameters:(NSMutableDictionary *)parameters setString:(NSString *)value forKey:(NSString *)key {
    if (value == nil || [value isEqualToString:@""]) return;

    [parameters setObject:value forKey:key];
}

- (void)parameters:(NSMutableDictionary *)parameters setInt:(int)value forKey:(NSString *)key {
    if (value < 0) return;

    NSString *valueString = [NSString stringWithFormat:@"%d", value];
    [self parameters:parameters setString:valueString forKey:key];
}

- (void)parameters:(NSMutableDictionary *)parameters setDate1970:(double)value forKey:(NSString *)key {
    if (value < 0) return;

    NSString *dateString = [ADJUtil formatSeconds1970:value];
    [self parameters:parameters setString:dateString forKey:key];
}

- (void)parameters:(NSMutableDictionary *)parameters setDate:(NSDate *)value forKey:(NSString *)key {
    if (value == nil) return;

    NSString *dateString = [ADJUtil formatDate:value];
    [self parameters:parameters setString:dateString forKey:key];
}

- (void)parameters:(NSMutableDictionary *)parameters setDuration:(double)value forKey:(NSString *)key {
    if (value < 0) return;

    int intValue = round(value);
    [self parameters:parameters setInt:intValue forKey:key];
}

- (void)parameters:(NSMutableDictionary *)parameters setDictionaryJson:(NSDictionary *)dictionary forKey:(NSString *)key {
    if (dictionary == nil) return;
    if (dictionary.count == 0) return;
    if (![NSJSONSerialization isValidJSONObject:dictionary]) return;

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *dictionaryString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [self parameters:parameters setString:dictionaryString forKey:key];
}

- (void)parameters:(NSMutableDictionary *)parameters setDictionary:(NSDictionary *)dictionary forKey:(NSString *)key {
    if (dictionary == nil) return;
    if (dictionary.count == 0) return;

    NSDictionary * convertedDictionary = [ADJUtil convertDictionaryValues:dictionary];

    [self parameters:parameters setDictionaryJson:convertedDictionary forKey:key];
}

- (void)parameters:(NSMutableDictionary *)parameters setBool:(BOOL)value forKey:(NSString *)key {
    int valueInt = [[NSNumber numberWithBool:value] intValue];

    [self parameters:parameters setInt:valueInt forKey:key];
}

- (void)parameters:(NSMutableDictionary *)parameters setNumber:(NSNumber *)value forKey:(NSString *)key {
    if (value == nil) return;

    NSString *numberString = [NSString stringWithFormat:@"%.5f", [value doubleValue]];

    [self parameters:parameters setString:numberString forKey:key];
}

@end

