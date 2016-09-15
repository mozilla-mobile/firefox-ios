//
//  ADJDeviceInfo.m
//  adjust
//
//  Created by Pedro Filipe on 17/10/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJDeviceInfo.h"
#import "UIDevice+ADJAdditions.h"
#import "NSString+ADJAdditions.h"
#import "ADJUtil.h"

static NSString * const kWiFi   = @"WIFI";
static NSString * const kWWAN   = @"WWAN";

@implementation ADJDeviceInfo

+ (ADJDeviceInfo *) deviceInfoWithSdkPrefix:(NSString *)sdkPrefix {
    return [[ADJDeviceInfo alloc] initWithSdkPrefix:sdkPrefix];
}

- (id) initWithSdkPrefix:(NSString *)sdkPrefix {
    self = [super init];
    if (self == nil) return nil;

    UIDevice *device = UIDevice.currentDevice;
    NSLocale *locale = NSLocale.currentLocale;
    NSBundle *bundle = NSBundle.mainBundle;
    NSDictionary *infoDictionary = bundle.infoDictionary;

    self.trackingEnabled  = UIDevice.currentDevice.adjTrackingEnabled;
    self.idForAdvertisers = UIDevice.currentDevice.adjIdForAdvertisers;
    self.fbAttributionId  = UIDevice.currentDevice.adjFbAttributionId;
    self.vendorId         = UIDevice.currentDevice.adjVendorId;
    self.bundeIdentifier  = [infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey];
    self.bundleVersion    = [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey];
    self.bundleShortVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.languageCode     = [locale objectForKey:NSLocaleLanguageCode];
    self.countryCode      = [locale objectForKey:NSLocaleCountryCode];
    self.osName           = @"ios";
    self.deviceType       = device.adjDeviceType;
    self.deviceName       = device.adjDeviceName;
    self.systemVersion    = device.systemVersion;

    if (sdkPrefix == nil) {
        self.clientSdk        = ADJUtil.clientSdk;
    } else {
        self.clientSdk = [NSString stringWithFormat:@"%@@%@", sdkPrefix, ADJUtil.clientSdk];
    }

    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    ADJDeviceInfo* copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy.idForAdvertisers = [self.idForAdvertisers copyWithZone:zone];
        copy.fbAttributionId = [self.fbAttributionId copyWithZone:zone];
        copy.trackingEnabled = self.trackingEnabled;
        copy.vendorId = [self.vendorId copyWithZone:zone];
        copy.pushToken = [self.pushToken copyWithZone:zone];
        copy.clientSdk = [self.clientSdk copyWithZone:zone];
        copy.bundeIdentifier = [self.bundeIdentifier copyWithZone:zone];
        copy.bundleVersion = [self.bundleVersion copyWithZone:zone];
        copy.bundleShortVersion = [self.bundleShortVersion copyWithZone:zone];
        copy.deviceType = [self.deviceType copyWithZone:zone];
        copy.deviceName = [self.deviceName copyWithZone:zone];
        copy.osName = [self.osName copyWithZone:zone];
        copy.systemVersion = [self.systemVersion copyWithZone:zone];
        copy.languageCode = [self.languageCode copyWithZone:zone];
        copy.countryCode = [self.countryCode copyWithZone:zone];
    }
    
    return copy;
}

@end
