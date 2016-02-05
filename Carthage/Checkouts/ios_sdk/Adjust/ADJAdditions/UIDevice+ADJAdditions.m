//
//  UIDevice+ADJAdditions.m
//  Adjust
//
//  Created by Christian Wellenbrock on 23.07.12.
//  Copyright (c) 2012-2014 adjust GmbH. All rights reserved.
//

#import "UIDevice+ADJAdditions.h"
#import "NSString+ADJAdditions.h"

#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

#if !ADJUST_NO_IDFA
#import <AdSupport/ASIdentifierManager.h>
#endif

#if !ADJUST_NO_IAD
#import <iAd/iAd.h>
#endif

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
    NSString *result = [UIPasteboard pasteboardWithName:@"fb_app_attribution" create:NO].string;
    if (result == nil) return @"";
    return result;
}

- (NSString *)adjMacAddress {
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;

    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;

    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }

    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }

    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }

    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }

    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);

    NSString *macAddress = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                            *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];

    free(buf);

    return macAddress;
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

- (void) adjSetIad:(ADJActivityHandler *) activityHandler{
#if ADJUST_NO_IAD
    return;
#else

    // [[ADClient sharedClient] lookupAdConversionDetails:...]
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

    SEL iadDateSelector = NSSelectorFromString(@"lookupAdConversionDetails:");
    if (![ADClientSharedClientInstance respondsToSelector:iadDateSelector]) {
        return;
    }

    [ADClientSharedClientInstance performSelector:iadDateSelector
                                       withObject:^(NSDate *appPurchaseDate, NSDate *iAdImpressionDate) {
                                           [activityHandler setIadDate:iAdImpressionDate withPurchaseDate:appPurchaseDate];
                                       }];

#pragma clang diagnostic pop
#endif
}
@end
