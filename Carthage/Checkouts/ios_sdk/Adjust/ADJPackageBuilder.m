//
//  ADJPackageBuilder.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-03.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJUtil.h"
#import "ADJAttribution.h"
#import "ADJPackageBuilder.h"
#import "ADJActivityPackage.h"
#import "NSData+ADJAdditions.h"
#import "ADJAdjustFactory.h"

@interface ADJPackageBuilder()

@property (nonatomic, assign) double createdAt;

@property (nonatomic, weak) ADJDeviceInfo* deviceInfo;
@property (nonatomic, copy) ADJActivityState *activityState;
@property (nonatomic, weak) ADJConfig *adjustConfig;

@end

@implementation ADJPackageBuilder

#pragma mark - Object lifecycle methods

- (id)initWithDeviceInfo:(ADJDeviceInfo *)deviceInfo
           activityState:(ADJActivityState *)activityState
                  config:(ADJConfig *)adjustConfig
               createdAt:(double)createdAt {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.createdAt = createdAt;
    self.deviceInfo = deviceInfo;
    self.adjustConfig = adjustConfig;
    self.activityState = activityState;

    return self;
}

#pragma mark - Public methods

- (ADJActivityPackage *)buildSessionPackage:(ADJSessionParameters *)sessionParameters
                                  isInDelay:(BOOL)isInDelay {
    NSMutableDictionary *parameters = [self defaultParameters];
    [ADJPackageBuilder parameters:parameters setDuration:self.activityState.lastInterval forKey:@"last_interval"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.defaultTracker forKey:@"default_tracker"];
    if (!isInDelay) {
        [ADJPackageBuilder parameters:parameters setDictionary:sessionParameters.callbackParameters forKey:@"callback_params"];
        [ADJPackageBuilder parameters:parameters setDictionary:sessionParameters.partnerParameters forKey:@"partner_params"];
    }
    ADJActivityPackage *sessionPackage = [self defaultActivityPackage];
    sessionPackage.path = @"/session";
    sessionPackage.activityKind = ADJActivityKindSession;
    sessionPackage.suffix = @"";
    sessionPackage.parameters = parameters;

    return sessionPackage;
}

- (ADJActivityPackage *)buildEventPackage:(ADJEvent *)event
                        sessionParameters:(ADJSessionParameters *)sessionParameters
                                isInDelay:(BOOL)isInDelay {
    NSMutableDictionary *parameters = [self defaultParameters];
    [ADJPackageBuilder parameters:parameters setInt:self.activityState.eventCount forKey:@"event_count"];
    [ADJPackageBuilder parameters:parameters setNumber:event.revenue forKey:@"revenue"];
    [ADJPackageBuilder parameters:parameters setString:event.currency forKey:@"currency"];
    [ADJPackageBuilder parameters:parameters setString:event.eventToken forKey:@"event_token"];

    if (!isInDelay) {
        NSDictionary * mergedCallbackParameters = [ADJUtil mergeParameters:sessionParameters.callbackParameters
                                                                    source:event.callbackParameters
                                                             parameterName:@"Callback"];
        NSDictionary * mergedPartnerParameters = [ADJUtil mergeParameters:sessionParameters.partnerParameters
                                                                   source:event.partnerParameters
                                                            parameterName:@"Partner"];
        [ADJPackageBuilder parameters:parameters setDictionary:mergedCallbackParameters forKey:@"callback_params"];
        [ADJPackageBuilder parameters:parameters setDictionary:mergedPartnerParameters forKey:@"partner_params"];
    }
    if (event.emptyReceipt) {
        NSString *emptyReceipt = @"empty";
        [ADJPackageBuilder parameters:parameters setString:emptyReceipt forKey:@"receipt"];
        [ADJPackageBuilder parameters:parameters setString:event.transactionId forKey:@"transaction_id"];
    }
    else if (event.receipt != nil) {
        NSString *receiptBase64 = [event.receipt adjEncodeBase64];
        [ADJPackageBuilder parameters:parameters setString:receiptBase64 forKey:@"receipt"];
        [ADJPackageBuilder parameters:parameters setString:event.transactionId forKey:@"transaction_id"];
    }

    ADJActivityPackage *eventPackage = [self defaultActivityPackage];
    eventPackage.path = @"/event";
    eventPackage.activityKind = ADJActivityKindEvent;
    eventPackage.suffix = [self eventSuffix:event];
    eventPackage.parameters = parameters;

    if (isInDelay) {
        eventPackage.callbackParameters = event.callbackParameters;
        eventPackage.partnerParameters = event.partnerParameters;
    }

    return eventPackage;
}

- (ADJActivityPackage *)buildClickPackage:(NSString *)clickSource {
    NSMutableDictionary *parameters = [self idsParameters];

    [ADJPackageBuilder parameters:parameters setString:clickSource                     forKey:@"source"];
    [ADJPackageBuilder parameters:parameters setDictionary:self.deeplinkParameters forKey:@"params"];
    [ADJPackageBuilder parameters:parameters setDate:self.clickTime                    forKey:@"click_time"];
    [ADJPackageBuilder parameters:parameters setDate:self.purchaseTime                 forKey:@"purchase_time"];

    if (self.attribution != nil) {
        [ADJPackageBuilder parameters:parameters setString:self.attribution.trackerName  forKey:@"tracker"];
        [ADJPackageBuilder parameters:parameters setString:self.attribution.campaign     forKey:@"campaign"];
        [ADJPackageBuilder parameters:parameters setString:self.attribution.adgroup      forKey:@"adgroup"];
        [ADJPackageBuilder parameters:parameters setString:self.attribution.creative     forKey:@"creative"];
    }
    [ADJPackageBuilder parameters:parameters setDictionary:self.iadDetails forKey:@"details"];
    [ADJPackageBuilder parameters:parameters setString:self.deeplink forKey:@"deeplink"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceToken forKey:@"push_token"];

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

#pragma mark - Private & helper methods
- (ADJActivityPackage *)defaultActivityPackage {
    ADJActivityPackage *activityPackage = [[ADJActivityPackage alloc] init];
    activityPackage.clientSdk = self.deviceInfo.clientSdk;

    return activityPackage;
}

- (NSMutableDictionary *)idsParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [self injectDeviceInfoIds:self.deviceInfo   intoParameters:parameters];
    [self injectConfig:self.adjustConfig        intoParameters:parameters];
    [self injectCommonParameters:parameters];

    return parameters;
}

- (NSMutableDictionary *)defaultParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [self injectDeviceInfo:self.deviceInfo          intoParameters:parameters];
    [self injectConfig:self.adjustConfig            intoParameters:parameters];
    [self injectActivityState:self.activityState    intoParamters:parameters];
    [self injectCommonParameters:parameters];

    return parameters;
}

- (void)injectCommonParameters:(NSMutableDictionary *)parameters {
    [ADJPackageBuilder parameters:parameters setDate1970:self.createdAt forKey:@"created_at"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"attribution_deeplink"];
}

- (void) injectDeviceInfoIds:(ADJDeviceInfo *)deviceInfo
           intoParameters:(NSMutableDictionary *) parameters
{
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.idForAdvertisers  forKey:@"idfa"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.vendorId          forKey:@"idfv"];
}

- (void) injectDeviceInfo:(ADJDeviceInfo *)deviceInfo
           intoParameters:(NSMutableDictionary *) parameters
{
    [self injectDeviceInfoIds:deviceInfo
               intoParameters:parameters];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.fbAttributionId   forKey:@"fb_id"];
    [ADJPackageBuilder parameters:parameters setInt:deviceInfo.trackingEnabled      forKey:@"tracking_enabled"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.bundeIdentifier   forKey:@"bundle_id"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.bundleVersion     forKey:@"app_version"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.bundleShortVersion forKey:@"app_version_short"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.deviceType        forKey:@"device_type"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.deviceName        forKey:@"device_name"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.osName            forKey:@"os_name"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.systemVersion     forKey:@"os_version"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.languageCode      forKey:@"language"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.countryCode       forKey:@"country"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.machineModel      forKey:@"hardware_name"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.cpuSubtype       forKey:@"cpu_type"];
    [ADJPackageBuilder parameters:parameters setString:deviceInfo.installReceiptBase64 forKey:@"install_receipt"];
}

- (void)injectConfig:(ADJConfig*) adjustConfig
       intoParameters:(NSMutableDictionary *) parameters
{
    [ADJPackageBuilder parameters:parameters setString:adjustConfig.appToken        forKey:@"app_token"];
    [ADJPackageBuilder parameters:parameters setString:adjustConfig.environment     forKey:@"environment"];
    [ADJPackageBuilder parameters:parameters setBool:adjustConfig.hasResponseDelegate forKey:@"needs_response_details"];
    [ADJPackageBuilder parameters:parameters setBool:adjustConfig.eventBufferingEnabled forKey:@"event_buffering_enabled"];
}

- (void) injectActivityState:(ADJActivityState *)activityState
               intoParamters:(NSMutableDictionary *)parameters {
    [ADJPackageBuilder parameters:parameters setInt:activityState.sessionCount       forKey:@"session_count"];
    [ADJPackageBuilder parameters:parameters setInt:activityState.subsessionCount    forKey:@"subsession_count"];
    [ADJPackageBuilder parameters:parameters setDuration:activityState.sessionLength forKey:@"session_length"];
    [ADJPackageBuilder parameters:parameters setDuration:activityState.timeSpent     forKey:@"time_spent"];
    [ADJPackageBuilder parameters:parameters setString:activityState.uuid            forKey:@"ios_uuid"];

    // Check if UUID was persisted or not.
    // If yes, assign it to persistent_ios_uuid parameter.
    // If not, assign it to ios_uuid parameter.
    if (activityState.isPersisted) {
       [ADJPackageBuilder parameters:parameters setString:activityState.uuid        forKey:@"persistent_ios_uuid"];
    } else {
       [ADJPackageBuilder parameters:parameters setString:activityState.uuid        forKey:@"ios_uuid"];
    }

}

- (NSString *)eventSuffix:(ADJEvent *)event {
    if (event.revenue == nil) {
        return [NSString stringWithFormat:@"'%@'", event.eventToken];
    } else {
        return [NSString stringWithFormat:@"(%.5f %@, '%@')", [event.revenue doubleValue], event.currency, event.eventToken];
    }
}

+ (void)parameters:(NSMutableDictionary *)parameters setString:(NSString *)value forKey:(NSString *)key {
    if (value == nil || [value isEqualToString:@""]) return;

    [parameters setObject:value forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setInt:(int)value forKey:(NSString *)key {
    if (value < 0) return;

    NSString *valueString = [NSString stringWithFormat:@"%d", value];
    [ADJPackageBuilder parameters:parameters setString:valueString forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setDate1970:(double)value forKey:(NSString *)key {
    if (value < 0) return;

    NSString *dateString = [ADJUtil formatSeconds1970:value];
    [ADJPackageBuilder parameters:parameters setString:dateString forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setDate:(NSDate *)value forKey:(NSString *)key {
    if (value == nil) return;

    NSString *dateString = [ADJUtil formatDate:value];
    [ADJPackageBuilder parameters:parameters setString:dateString forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setDuration:(double)value forKey:(NSString *)key {
    if (value < 0) return;

    int intValue = round(value);
    [ADJPackageBuilder parameters:parameters setInt:intValue forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setDictionaryJson:(NSDictionary *)dictionary forKey:(NSString *)key {
    if (dictionary == nil) return;
    if (dictionary.count == 0) return;
    if (![NSJSONSerialization isValidJSONObject:dictionary]) return;

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *dictionaryString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [ADJPackageBuilder parameters:parameters setString:dictionaryString forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setDictionary:(NSDictionary *)dictionary forKey:(NSString *)key {
    if (dictionary == nil) return;
    if (dictionary.count == 0) return;

    if (dictionary.count == 0) {
        return;
    }

    NSDictionary * convertedDictionary = [ADJUtil convertDictionaryValues:dictionary];

    [ADJPackageBuilder parameters:parameters setDictionaryJson:convertedDictionary forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setBool:(BOOL)value forKey:(NSString *)key {
    int valueInt = [[NSNumber numberWithBool:value] intValue];

    [ADJPackageBuilder parameters:parameters setInt:valueInt forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setNumber:(NSNumber *)value forKey:(NSString *)key {
    if (value == nil) return;

    NSString *numberString = [NSString stringWithFormat:@"%.5f", [value doubleValue]];

    [ADJPackageBuilder parameters:parameters setString:numberString forKey:key];
}

@end
