//
//  UIDevice+ADJAdditions.m
//  Adjust
//
//  Created by Christian Wellenbrock on 23.07.12.
//  Copyright (c) 2012-2014 adjust GmbH. All rights reserved.
//

#import "UIDevice+ADJAdditions.h"
#import "NSString+ADJAdditions.h"

#import <sys/sysctl.h>

#if !ADJUST_NO_IDFA
#import <AdSupport/ASIdentifierManager.h>
#endif

#if !ADJUST_NO_IAD && !TARGET_OS_TV
#import <iAd/iAd.h>
#endif

#import "ADJAdjustFactory.h"

@implementation UIDevice(ADJAdditions)

- (BOOL)adjTrackingEnabled {
#if ADJUST_NO_IDFA
    return NO;
#else

    // return [[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled];
    NSString *className = [NSString adjJoin:@"A", @"S", @"identifier", @"manager", nil];
    Class class = NSClassFromString(className);
    if (class == nil) {
        return NO;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

    NSString *keyManager = [NSString adjJoin:@"shared", @"manager", nil];
    SEL selManager = NSSelectorFromString(keyManager);
    if (![class respondsToSelector:selManager]) {
        return NO;
    }
    id manager = [class performSelector:selManager];

    NSString *keyEnabled = [NSString adjJoin:@"is", @"advertising", @"tracking", @"enabled", nil];
    SEL selEnabled = NSSelectorFromString(keyEnabled);
    if (![manager respondsToSelector:selEnabled]) {
        return NO;
    }
    BOOL enabled = (BOOL)[manager performSelector:selEnabled];
    return enabled;

#pragma clang diagnostic pop
#endif
}

- (NSString *)adjIdForAdvertisers {
#if ADJUST_NO_IDFA
    return @"";
#else

    // return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSString *className = [NSString adjJoin:@"A", @"S", @"identifier", @"manager", nil];
    Class class = NSClassFromString(className);
    if (class == nil) {
        return @"";
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

    NSString *keyManager = [NSString adjJoin:@"shared", @"manager", nil];
    SEL selManager = NSSelectorFromString(keyManager);
    if (![class respondsToSelector:selManager]) {
        return @"";
    }
    id manager = [class performSelector:selManager];

    NSString *keyIdentifier = [NSString adjJoin:@"advertising", @"identifier", nil];
    SEL selIdentifier = NSSelectorFromString(keyIdentifier);
    if (![manager respondsToSelector:selIdentifier]) {
        return @"";
    }
    id identifier = [manager performSelector:selIdentifier];

    NSString *keyString = [NSString adjJoin:@"UUID", @"string", nil];
    SEL selString = NSSelectorFromString(keyString);
    if (![identifier respondsToSelector:selString]) {
        return @"";
    }
    NSString *string = [identifier performSelector:selString];
    return string;

#pragma clang diagnostic pop
#endif
}

- (NSString *)adjFbAttributionId {
#if ADJUST_NO_UIPASTEBOARD || defined (TARGET_OS_TV)
    return @"";
#else
    NSString *result = [UIPasteboard pasteboardWithName:@"fb_app_attribution" create:NO].string;
    if (result == nil) return @"";
    return result;
#endif
}

- (NSString *)adjDeviceType {
    NSString *type = [self.model stringByReplacingOccurrencesOfString:@" " withString:@""];
    return type;
}

- (NSString *)adjDeviceName {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *name = malloc(size);
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    NSString *machine = [NSString stringWithUTF8String:name];
    free(name);
    return machine;
}

- (NSString *)adjCreateUuid {
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef stringRef = CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    NSString *uuidString = (__bridge_transfer NSString*)stringRef;
    NSString *lowerUuid = [uuidString lowercaseString];
    CFRelease(newUniqueId);
    return lowerUuid;
}

- (NSString *)adjVendorId {
    if ([UIDevice.currentDevice respondsToSelector:@selector(identifierForVendor)]) {
        return [UIDevice.currentDevice.identifierForVendor UUIDString];
    }
    return @"";
}

- (void) adjSetIad:(ADJActivityHandler *) activityHandler
       triesV3Left:(int)triesV3Left
{
    id<ADJLogger> logger = [ADJAdjustFactory logger];
    [logger debug:@"iAd with %d tries to read v3", triesV3Left];

#if ADJUST_NO_IAD || TARGET_OS_TV
    [logger debug:@"ADJUST_NO_IAD or TARGET_OS_TV set"];
    return;
#else
    [logger debug:@"ADJUST_NO_IAD or TARGET_OS_TV not set"];

    // [[ADClient sharedClient] ...]
    Class ADClientClass = NSClassFromString(@"ADClient");
    if (ADClientClass == nil) {
        return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL sharedClientSelector = NSSelectorFromString(@"sharedClient");
    if (![ADClientClass respondsToSelector:sharedClientSelector]) {
        return;
    }
    id ADClientSharedClientInstance = [ADClientClass performSelector:sharedClientSelector];

    if (ADClientSharedClientInstance == nil) {
        return;
    }

    // if no tries for iad v3 left -> iad v2
    if (triesV3Left == 0) {
        [self adjSetIadWithDates:activityHandler ADClientSharedClientInstance:ADClientSharedClientInstance];
        return;
    }

    BOOL isIadV3Avaliable = [self adjSetIadWithDetails:activityHandler
                     ADClientSharedClientInstance:ADClientSharedClientInstance
                                      retriesLeft:(triesV3Left - 1)];

    // if no tries for iad v3 left -> iad v2
    if (!isIadV3Avaliable) {
        [self adjSetIadWithDates:activityHandler ADClientSharedClientInstance:ADClientSharedClientInstance];
    }
#pragma clang diagnostic pop
#endif
}

- (BOOL)adjSetIadWithDetails:(ADJActivityHandler *)activityHandler
ADClientSharedClientInstance:(id)ADClientSharedClientInstance
                 retriesLeft:(int)retriesLeft
{
    SEL iadDetailsSelector = NSSelectorFromString(@"requestAttributionDetailsWithBlock:");

    if (![ADClientSharedClientInstance respondsToSelector:iadDetailsSelector]) {
        return NO;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [ADClientSharedClientInstance performSelector:iadDetailsSelector
                                       withObject:^(NSDictionary *attributionDetails, NSError *error) {
                                           [activityHandler setIadDetails:attributionDetails error:error retriesLeft:retriesLeft];
                                       }];
#pragma clang diagnostic pop

    return YES;
}

- (BOOL)adjSetIadWithDates:(ADJActivityHandler *)activityHandler
ADClientSharedClientInstance:(id)ADClientSharedClientInstance
{
    SEL iadDateSelector = NSSelectorFromString(@"lookupAdConversionDetails:");

    if (![ADClientSharedClientInstance respondsToSelector:iadDateSelector]) {
        return NO;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [ADClientSharedClientInstance performSelector:iadDateSelector
                                       withObject:^(NSDate *appPurchaseDate, NSDate *iAdImpressionDate) {
                                           [activityHandler setIadDate:iAdImpressionDate withPurchaseDate:appPurchaseDate];
                                       }];

#pragma clang diagnostic pop
    return YES;
}
@end
