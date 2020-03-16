//
//  ADJPackageBuilder.m
//  Adjust SDK
//
//  Created by Christian Wellenbrock (@wellle) on 3rd July 2013.
//  Copyright (c) 2013-2018 Adjust GmbH. All rights reserved.
//

#import "ADJUtil.h"
#import "ADJAttribution.h"
#import "ADJAdjustFactory.h"
#import "ADJPackageBuilder.h"
#import "ADJActivityPackage.h"
#import "NSData+ADJAdditions.h"
#import "UIDevice+ADJAdditions.h"

@interface ADJPackageBuilder()

@property (nonatomic, assign) double createdAt;

@property (nonatomic, weak) ADJConfig *adjustConfig;

@property (nonatomic, weak) ADJDeviceInfo *deviceInfo;

@property (nonatomic, copy) ADJActivityState *activityState;

@property (nonatomic, weak) ADJSessionParameters *sessionParameters;

@end

@implementation ADJPackageBuilder

#pragma mark - Object lifecycle methods

- (id)initWithDeviceInfo:(ADJDeviceInfo *)deviceInfo
           activityState:(ADJActivityState *)activityState
                  config:(ADJConfig *)adjustConfig
       sessionParameters:(ADJSessionParameters *)sessionParameters
               createdAt:(double)createdAt {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.createdAt = createdAt;
    self.deviceInfo = deviceInfo;
    self.adjustConfig = adjustConfig;
    self.activityState = activityState;
    self.sessionParameters = sessionParameters;

    return self;
}

#pragma mark - Public methods

- (ADJActivityPackage *)buildSessionPackage:(BOOL)isInDelay {
    NSMutableDictionary *parameters = [self getSessionParameters:isInDelay];
    ADJActivityPackage *sessionPackage = [self defaultActivityPackage];
    sessionPackage.path = @"/session";
    sessionPackage.activityKind = ADJActivityKindSession;
    sessionPackage.suffix = @"";
    sessionPackage.parameters = parameters;
    return sessionPackage;
}

- (ADJActivityPackage *)buildEventPackage:(ADJEvent *)event
                                isInDelay:(BOOL)isInDelay {
    NSMutableDictionary *parameters = [self getEventParameters:isInDelay forEventPackage:event];
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

- (ADJActivityPackage *)buildInfoPackage:(NSString *)infoSource {
    NSMutableDictionary *parameters = [self getInfoParameters:infoSource];
    ADJActivityPackage *infoPackage = [self defaultActivityPackage];
    infoPackage.path = @"/sdk_info";
    infoPackage.activityKind = ADJActivityKindInfo;
    infoPackage.suffix = @"";
    infoPackage.parameters = parameters;
    return infoPackage;
}

- (ADJActivityPackage *)buildAdRevenuePackage:(NSString *)source payload:(NSData *)payload {
    NSMutableDictionary *parameters = [self getAdRevenueParameters:source payload:payload];
    ADJActivityPackage *adRevenuePackage = [self defaultActivityPackage];
    adRevenuePackage.path = @"/ad_revenue";
    adRevenuePackage.activityKind = ADJActivityKindAdRevenue;
    adRevenuePackage.suffix = @"";
    adRevenuePackage.parameters = parameters;
    return adRevenuePackage;
}

- (ADJActivityPackage *)buildClickPackage:(NSString *)clickSource {
    NSMutableDictionary *parameters = [self getClickParameters:clickSource];
    ADJActivityPackage *clickPackage = [self defaultActivityPackage];
    clickPackage.path = @"/sdk_click";
    clickPackage.activityKind = ADJActivityKindClick;
    clickPackage.suffix = @"";
    clickPackage.parameters = parameters;
    return clickPackage;
}

- (ADJActivityPackage *)buildAttributionPackage:(NSString *)initiatedBy {
    NSMutableDictionary *parameters = [self getAttributionParameters:initiatedBy];
    ADJActivityPackage *attributionPackage = [self defaultActivityPackage];
    attributionPackage.path = @"/attribution";
    attributionPackage.activityKind = ADJActivityKindAttribution;
    attributionPackage.suffix = @"";
    attributionPackage.parameters = parameters;
    return attributionPackage;
}

- (ADJActivityPackage *)buildGdprPackage {
    NSMutableDictionary *parameters = [self getGdprParameters];
    ADJActivityPackage *gdprPackage = [self defaultActivityPackage];
    gdprPackage.path = @"/gdpr_forget_device";
    gdprPackage.activityKind = ADJActivityKindGdpr;
    gdprPackage.suffix = @"";
    gdprPackage.parameters = parameters;
    return gdprPackage;
}

+ (void)parameters:(NSMutableDictionary *)parameters setDictionary:(NSDictionary *)dictionary forKey:(NSString *)key {
    if (dictionary == nil) {
        return;
    }
    if (dictionary.count == 0) {
        return;
    }
    if (dictionary.count == 0) {
        return;
    }

    NSDictionary *convertedDictionary = [ADJUtil convertDictionaryValues:dictionary];
    [ADJPackageBuilder parameters:parameters setDictionaryJson:convertedDictionary forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setString:(NSString *)value forKey:(NSString *)key {
    if (value == nil || [value isEqualToString:@""]) {
        return;
    }
    [parameters setObject:value forKey:key];
}

#pragma mark - Private & helper methods

- (NSMutableDictionary *)getSessionParameters:(BOOL)isInDelay {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appSecret forKey:@"app_secret"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appToken forKey:@"app_token"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil getUpdateTime] forKey:@"app_updated_at"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleVersion forKey:@"app_version"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleShortVersion forKey:@"app_version_short"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"attribution_deeplink"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundeIdentifier forKey:@"bundle_id"];
    [ADJPackageBuilder parameters:parameters setNumberInt:[ADJUtil readReachabilityFlags] forKey:@"connectivity_type"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.countryCode forKey:@"country"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.cpuSubtype forKey:@"cpu_type"];
    [ADJPackageBuilder parameters:parameters setDate1970:self.createdAt forKey:@"created_at"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.defaultTracker forKey:@"default_tracker"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceName forKey:@"device_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceType forKey:@"device_type"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.environment forKey:@"environment"];
    [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.eventBufferingEnabled forKey:@"event_buffering_enabled"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.fbAnonymousId forKey:@"fb_anon_id"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.machineModel forKey:@"hardware_name"];
    [ADJPackageBuilder parameters:parameters setString:UIDevice.currentDevice.adjIdForAdvertisers forKey:@"idfa"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.vendorId forKey:@"idfv"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.installReceiptBase64 forKey:@"install_receipt"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil getInstallTime] forKey:@"installed_at"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.languageCode forKey:@"language"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"needs_response_details"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osBuild forKey:@"os_build"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osName forKey:@"os_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.systemVersion forKey:@"os_version"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.secretId forKey:@"secret_id"];
    [ADJPackageBuilder parameters:parameters setInt:UIDevice.currentDevice.adjTrackingEnabled forKey:@"tracking_enabled"];

    if (self.adjustConfig.isDeviceKnown) {
        [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.isDeviceKnown forKey:@"device_known"];
    }

    if (self.activityState != nil) {
        [ADJPackageBuilder parameters:parameters setDuration:self.activityState.lastInterval forKey:@"last_interval"];
        [ADJPackageBuilder parameters:parameters setString:self.activityState.deviceToken forKey:@"push_token"];
        [ADJPackageBuilder parameters:parameters setInt:self.activityState.sessionCount forKey:@"session_count"];
        [ADJPackageBuilder parameters:parameters setDuration:self.activityState.sessionLength forKey:@"session_length"];
        [ADJPackageBuilder parameters:parameters setInt:self.activityState.subsessionCount forKey:@"subsession_count"];
        [ADJPackageBuilder parameters:parameters setDuration:self.activityState.timeSpent forKey:@"time_spent"];
        if (self.activityState.isPersisted) {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"persistent_ios_uuid"];
        } else {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"ios_uuid"];
        }
    }

    if (!isInDelay) {
        [ADJPackageBuilder parameters:parameters setDictionary:self.sessionParameters.callbackParameters forKey:@"callback_params"];
        [ADJPackageBuilder parameters:parameters setDictionary:self.sessionParameters.partnerParameters forKey:@"partner_params"];
    }

#if !TARGET_OS_TV
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil readMCC] forKey:@"mcc"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil readMNC] forKey:@"mnc"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil readCurrentRadioAccessTechnology] forKey:@"network_type"];
#endif

    return parameters;
}

- (NSMutableDictionary *)getEventParameters:(BOOL)isInDelay forEventPackage:(ADJEvent *)event {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appSecret forKey:@"app_secret"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appToken forKey:@"app_token"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleVersion forKey:@"app_version"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleShortVersion forKey:@"app_version_short"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"attribution_deeplink"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundeIdentifier forKey:@"bundle_id"];
    [ADJPackageBuilder parameters:parameters setNumberInt:[ADJUtil readReachabilityFlags] forKey:@"connectivity_type"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.countryCode forKey:@"country"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.cpuSubtype forKey:@"cpu_type"];
    [ADJPackageBuilder parameters:parameters setDate1970:self.createdAt forKey:@"created_at"];
    [ADJPackageBuilder parameters:parameters setString:event.currency forKey:@"currency"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceName forKey:@"device_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceType forKey:@"device_type"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.environment forKey:@"environment"];
    [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.eventBufferingEnabled forKey:@"event_buffering_enabled"];
    [ADJPackageBuilder parameters:parameters setString:event.callbackId forKey:@"event_callback_id"];
    [ADJPackageBuilder parameters:parameters setString:event.eventToken forKey:@"event_token"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.fbAnonymousId forKey:@"fb_anon_id"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.machineModel forKey:@"hardware_name"];
    [ADJPackageBuilder parameters:parameters setString:UIDevice.currentDevice.adjIdForAdvertisers forKey:@"idfa"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.vendorId forKey:@"idfv"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.installReceiptBase64 forKey:@"install_receipt"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.languageCode forKey:@"language"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"needs_response_details"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osBuild forKey:@"os_build"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osName forKey:@"os_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.systemVersion forKey:@"os_version"];
    [ADJPackageBuilder parameters:parameters setNumber:event.revenue forKey:@"revenue"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.secretId forKey:@"secret_id"];
    [ADJPackageBuilder parameters:parameters setInt:UIDevice.currentDevice.adjTrackingEnabled forKey:@"tracking_enabled"];

    if (self.adjustConfig.isDeviceKnown) {
        [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.isDeviceKnown forKey:@"device_known"];
    }

    if (self.activityState != nil) {
        [ADJPackageBuilder parameters:parameters setInt:self.activityState.eventCount forKey:@"event_count"];
        [ADJPackageBuilder parameters:parameters setString:self.activityState.deviceToken forKey:@"push_token"];
        [ADJPackageBuilder parameters:parameters setInt:self.activityState.sessionCount forKey:@"session_count"];
        [ADJPackageBuilder parameters:parameters setDuration:self.activityState.sessionLength forKey:@"session_length"];
        [ADJPackageBuilder parameters:parameters setInt:self.activityState.subsessionCount forKey:@"subsession_count"];
        [ADJPackageBuilder parameters:parameters setDuration:self.activityState.timeSpent forKey:@"time_spent"];
        if (self.activityState.isPersisted) {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"persistent_ios_uuid"];
        } else {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"ios_uuid"];
        }
    }

    if (!isInDelay) {
        NSDictionary *mergedCallbackParameters = [ADJUtil mergeParameters:self.sessionParameters.callbackParameters
                                                                   source:event.callbackParameters
                                                            parameterName:@"Callback"];
        NSDictionary *mergedPartnerParameters = [ADJUtil mergeParameters:self.sessionParameters.partnerParameters
                                                                  source:event.partnerParameters
                                                           parameterName:@"Partner"];

        [ADJPackageBuilder parameters:parameters setDictionary:mergedCallbackParameters forKey:@"callback_params"];
        [ADJPackageBuilder parameters:parameters setDictionary:mergedPartnerParameters forKey:@"partner_params"];
    }

    if (event.emptyReceipt) {
        NSString *emptyReceipt = @"empty";
        [ADJPackageBuilder parameters:parameters setString:emptyReceipt forKey:@"receipt"];
        [ADJPackageBuilder parameters:parameters setString:event.transactionId forKey:@"transaction_id"];
    } else if (event.receipt != nil) {
        NSString *receiptBase64 = [event.receipt adjEncodeBase64];
        [ADJPackageBuilder parameters:parameters setString:receiptBase64 forKey:@"receipt"];
        [ADJPackageBuilder parameters:parameters setString:event.transactionId forKey:@"transaction_id"];
    }

#if !TARGET_OS_TV
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil readMCC] forKey:@"mcc"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil readMNC] forKey:@"mnc"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil readCurrentRadioAccessTechnology] forKey:@"network_type"];
#endif

    return parameters;
}

- (NSMutableDictionary *)getInfoParameters:(NSString *)source {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appToken forKey:@"app_token"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appSecret forKey:@"app_secret"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"attribution_deeplink"];
    [ADJPackageBuilder parameters:parameters setDate1970:self.createdAt forKey:@"created_at"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.environment forKey:@"environment"];
    [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.eventBufferingEnabled forKey:@"event_buffering_enabled"];
    [ADJPackageBuilder parameters:parameters setString:UIDevice.currentDevice.adjIdForAdvertisers forKey:@"idfa"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.vendorId forKey:@"idfv"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"needs_response_details"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.secretId forKey:@"secret_id"];
    [ADJPackageBuilder parameters:parameters setString:source forKey:@"source"];

    if (self.adjustConfig.isDeviceKnown) {
        [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.isDeviceKnown forKey:@"device_known"];
    }

    if (self.activityState != nil) {
        [ADJPackageBuilder parameters:parameters setString:self.activityState.deviceToken forKey:@"push_token"];
        if (self.activityState.isPersisted) {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"persistent_ios_uuid"];
        } else {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"ios_uuid"];
        }
    }

    return parameters;
}

- (NSMutableDictionary *)getAdRevenueParameters:(NSString *)source payload:(NSData *)payload {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appToken forKey:@"app_token"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appSecret forKey:@"app_secret"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"attribution_deeplink"];
    [ADJPackageBuilder parameters:parameters setDate1970:self.createdAt forKey:@"created_at"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.environment forKey:@"environment"];
    [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.eventBufferingEnabled forKey:@"event_buffering_enabled"];
    [ADJPackageBuilder parameters:parameters setString:UIDevice.currentDevice.adjIdForAdvertisers forKey:@"idfa"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.vendorId forKey:@"idfv"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"needs_response_details"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.secretId forKey:@"secret_id"];
    [ADJPackageBuilder parameters:parameters setString:source forKey:@"source"];
    [ADJPackageBuilder parameters:parameters setData:payload forKey:@"payload"];

    if (self.adjustConfig.isDeviceKnown) {
        [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.isDeviceKnown forKey:@"device_known"];
    }

    if (self.activityState != nil) {
        [ADJPackageBuilder parameters:parameters setString:self.activityState.deviceToken forKey:@"push_token"];
        if (self.activityState.isPersisted) {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"persistent_ios_uuid"];
        } else {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"ios_uuid"];
        }
    }

    return parameters;
}


- (NSMutableDictionary *)getClickParameters:(NSString *)source {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appSecret forKey:@"app_secret"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appToken forKey:@"app_token"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil getUpdateTime] forKey:@"app_updated_at"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleVersion forKey:@"app_version"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleShortVersion forKey:@"app_version_short"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"attribution_deeplink"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundeIdentifier forKey:@"bundle_id"];
    [ADJPackageBuilder parameters:parameters setDictionary:self.sessionParameters.callbackParameters forKey:@"callback_params"];
    [ADJPackageBuilder parameters:parameters setDate:self.clickTime forKey:@"click_time"];
    [ADJPackageBuilder parameters:parameters setNumberInt:[ADJUtil readReachabilityFlags] forKey:@"connectivity_type"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.countryCode forKey:@"country"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.cpuSubtype forKey:@"cpu_type"];
    [ADJPackageBuilder parameters:parameters setDate1970:self.createdAt forKey:@"created_at"];
    [ADJPackageBuilder parameters:parameters setString:self.deeplink forKey:@"deeplink"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.defaultTracker forKey:@"default_tracker"];
    [ADJPackageBuilder parameters:parameters setDictionary:self.attributionDetails forKey:@"details"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceName forKey:@"device_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceType forKey:@"device_type"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.environment forKey:@"environment"];
    [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.eventBufferingEnabled forKey:@"event_buffering_enabled"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.fbAnonymousId forKey:@"fb_anon_id"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.machineModel forKey:@"hardware_name"];
    [ADJPackageBuilder parameters:parameters setString:UIDevice.currentDevice.adjIdForAdvertisers forKey:@"idfa"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.vendorId forKey:@"idfv"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.installReceiptBase64 forKey:@"install_receipt"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil getInstallTime] forKey:@"installed_at"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.languageCode forKey:@"language"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"needs_response_details"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osBuild forKey:@"os_build"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osName forKey:@"os_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.systemVersion forKey:@"os_version"];
    [ADJPackageBuilder parameters:parameters setDictionary:self.deeplinkParameters forKey:@"params"];
    [ADJPackageBuilder parameters:parameters setDictionary:self.sessionParameters.partnerParameters forKey:@"partner_params"];
    [ADJPackageBuilder parameters:parameters setDate:self.purchaseTime forKey:@"purchase_time"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.secretId forKey:@"secret_id"];
    [ADJPackageBuilder parameters:parameters setString:source forKey:@"source"];
    [ADJPackageBuilder parameters:parameters setInt:UIDevice.currentDevice.adjTrackingEnabled forKey:@"tracking_enabled"];

    if (self.adjustConfig.isDeviceKnown) {
        [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.isDeviceKnown forKey:@"device_known"];
    }

    if (self.activityState != nil) {
        [ADJPackageBuilder parameters:parameters setDuration:self.activityState.lastInterval forKey:@"last_interval"];
        [ADJPackageBuilder parameters:parameters setString:self.activityState.deviceToken forKey:@"push_token"];
        [ADJPackageBuilder parameters:parameters setInt:self.activityState.sessionCount forKey:@"session_count"];
        [ADJPackageBuilder parameters:parameters setDuration:self.activityState.sessionLength forKey:@"session_length"];
        [ADJPackageBuilder parameters:parameters setInt:self.activityState.subsessionCount forKey:@"subsession_count"];
        [ADJPackageBuilder parameters:parameters setDuration:self.activityState.timeSpent forKey:@"time_spent"];
        if (self.activityState.isPersisted) {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"persistent_ios_uuid"];
        } else {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"ios_uuid"];
        }
    }

    if (self.attribution != nil) {
        [ADJPackageBuilder parameters:parameters setString:self.attribution.adgroup forKey:@"adgroup"];
        [ADJPackageBuilder parameters:parameters setString:self.attribution.campaign forKey:@"campaign"];
        [ADJPackageBuilder parameters:parameters setString:self.attribution.creative forKey:@"creative"];
        [ADJPackageBuilder parameters:parameters setString:self.attribution.trackerName forKey:@"tracker"];
    }

#if !TARGET_OS_TV
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil readMCC] forKey:@"mcc"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil readMNC] forKey:@"mnc"];
    [ADJPackageBuilder parameters:parameters setString:[ADJUtil readCurrentRadioAccessTechnology] forKey:@"network_type"];
#endif

    return parameters;
}

- (NSMutableDictionary *)getAttributionParameters:(NSString *)initiatedBy {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appToken forKey:@"app_token"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appSecret forKey:@"app_secret"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleVersion forKey:@"app_version"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleShortVersion forKey:@"app_version_short"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"attribution_deeplink"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundeIdentifier forKey:@"bundle_id"];
    [ADJPackageBuilder parameters:parameters setDate1970:self.createdAt forKey:@"created_at"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceName forKey:@"device_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceType forKey:@"device_type"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.environment forKey:@"environment"];
    [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.eventBufferingEnabled forKey:@"event_buffering_enabled"];
    [ADJPackageBuilder parameters:parameters setString:UIDevice.currentDevice.adjIdForAdvertisers forKey:@"idfa"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.vendorId forKey:@"idfv"];
    [ADJPackageBuilder parameters:parameters setString:initiatedBy forKey:@"initiated_by"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"needs_response_details"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osBuild forKey:@"os_build"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osName forKey:@"os_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.systemVersion forKey:@"os_version"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.secretId forKey:@"secret_id"];

    if (self.adjustConfig.isDeviceKnown) {
        [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.isDeviceKnown forKey:@"device_known"];
    }

    if (self.activityState != nil) {
        if (self.activityState.isPersisted) {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"persistent_ios_uuid"];
        } else {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"ios_uuid"];
        }
    }

    return parameters;
}

- (NSMutableDictionary *)getGdprParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appToken forKey:@"app_token"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.appSecret forKey:@"app_secret"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleVersion forKey:@"app_version"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundleShortVersion forKey:@"app_version_short"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"attribution_deeplink"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.bundeIdentifier forKey:@"bundle_id"];
    [ADJPackageBuilder parameters:parameters setDate1970:self.createdAt forKey:@"created_at"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceName forKey:@"device_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.deviceType forKey:@"device_type"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.environment forKey:@"environment"];
    [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.eventBufferingEnabled forKey:@"event_buffering_enabled"];
    [ADJPackageBuilder parameters:parameters setString:UIDevice.currentDevice.adjIdForAdvertisers forKey:@"idfa"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.vendorId forKey:@"idfv"];
    [ADJPackageBuilder parameters:parameters setBool:YES forKey:@"needs_response_details"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osBuild forKey:@"os_build"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.osName forKey:@"os_name"];
    [ADJPackageBuilder parameters:parameters setString:self.deviceInfo.systemVersion forKey:@"os_version"];
    [ADJPackageBuilder parameters:parameters setString:self.adjustConfig.secretId forKey:@"secret_id"];

    if (self.adjustConfig.isDeviceKnown) {
        [ADJPackageBuilder parameters:parameters setBool:self.adjustConfig.isDeviceKnown forKey:@"device_known"];
    }

    if (self.activityState != nil) {
        if (self.activityState.isPersisted) {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"persistent_ios_uuid"];
        } else {
            [ADJPackageBuilder parameters:parameters setString:self.activityState.uuid forKey:@"ios_uuid"];
        }
    }

    return parameters;
}

- (ADJActivityPackage *)defaultActivityPackage {
    ADJActivityPackage *activityPackage = [[ADJActivityPackage alloc] init];
    activityPackage.clientSdk = self.deviceInfo.clientSdk;
    return activityPackage;
}

- (NSString *)eventSuffix:(ADJEvent *)event {
    if (event.revenue == nil) {
        return [NSString stringWithFormat:@"'%@'", event.eventToken];
    } else {
        return [NSString stringWithFormat:@"(%.5f %@, '%@')", [event.revenue doubleValue], event.currency, event.eventToken];
    }
}

+ (void)parameters:(NSMutableDictionary *)parameters setInt:(int)value forKey:(NSString *)key {
    if (value < 0) {
        return;
    }
    NSString *valueString = [NSString stringWithFormat:@"%d", value];
    [ADJPackageBuilder parameters:parameters setString:valueString forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setDate1970:(double)value forKey:(NSString *)key {
    if (value < 0) {
        return;
    }
    NSString *dateString = [ADJUtil formatSeconds1970:value];
    [ADJPackageBuilder parameters:parameters setString:dateString forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setDate:(NSDate *)value forKey:(NSString *)key {
    if (value == nil) {
        return;
    }
    NSString *dateString = [ADJUtil formatDate:value];
    [ADJPackageBuilder parameters:parameters setString:dateString forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setDuration:(double)value forKey:(NSString *)key {
    if (value < 0) {
        return;
    }
    int intValue = round(value);
    [ADJPackageBuilder parameters:parameters setInt:intValue forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setDictionaryJson:(NSDictionary *)dictionary forKey:(NSString *)key {
    if (dictionary == nil) {
        return;
    }
    if (dictionary.count == 0) {
        return;
    }
    if (![NSJSONSerialization isValidJSONObject:dictionary]) {
        return;
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *dictionaryString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [ADJPackageBuilder parameters:parameters setString:dictionaryString forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setBool:(BOOL)value forKey:(NSString *)key {
    int valueInt = [[NSNumber numberWithBool:value] intValue];
    [ADJPackageBuilder parameters:parameters setInt:valueInt forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setNumber:(NSNumber *)value forKey:(NSString *)key {
    if (value == nil) {
        return;
    }
    NSString *numberString = [NSString stringWithFormat:@"%.5f", [value doubleValue]];
    [ADJPackageBuilder parameters:parameters setString:numberString forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setNumberInt:(NSNumber *)value forKey:(NSString *)key {
    if (value == nil) {
        return;
    }
    [ADJPackageBuilder parameters:parameters setInt:[value intValue] forKey:key];
}

+ (void)parameters:(NSMutableDictionary *)parameters setData:(NSData *)value forKey:(NSString *)key {
    if (value == nil) {
        return;
    }
    [ADJPackageBuilder parameters:parameters
                        setString:[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding]
                           forKey:key];
}

@end
