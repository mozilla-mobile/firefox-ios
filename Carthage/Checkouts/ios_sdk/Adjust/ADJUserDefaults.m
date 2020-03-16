//
//  ADJUserDefaults.m
//  Adjust
//
//  Created by Uglješa Erceg on 16.08.17.
//  Copyright © 2017 adjust GmbH. All rights reserved.
//

#import "ADJUserDefaults.h"

static NSString * const PREFS_KEY_PUSH_TOKEN_DATA = @"adj_push_token";
static NSString * const PREFS_KEY_PUSH_TOKEN_STRING = @"adj_push_token_string";
static NSString * const PREFS_KEY_GDPR_FORGET_ME = @"adj_gdpr_forget_me";
static NSString * const PREFS_KEY_INSTALL_TRACKED = @"adj_install_tracked";
static NSString * const PREFS_KEY_DEEPLINK_URL = @"adj_deeplink_url";
static NSString * const PREFS_KEY_DEEPLINK_CLICK_TIME = @"adj_deeplink_click_time";

@implementation ADJUserDefaults

#pragma mark - Public methods

+ (void)savePushTokenData:(NSData *)pushToken {
    [[NSUserDefaults standardUserDefaults] setObject:pushToken forKey:PREFS_KEY_PUSH_TOKEN_DATA];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)savePushTokenString:(NSString *)pushToken {
    [[NSUserDefaults standardUserDefaults] setObject:pushToken forKey:PREFS_KEY_PUSH_TOKEN_STRING];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSData *)getPushTokenData {
    return [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_KEY_PUSH_TOKEN_DATA];
}

+ (NSString *)getPushTokenString {
    return [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_KEY_PUSH_TOKEN_STRING];
}

+ (void)removePushToken {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_PUSH_TOKEN_DATA];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_PUSH_TOKEN_STRING];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setInstallTracked {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PREFS_KEY_INSTALL_TRACKED];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getInstallTracked {
    return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_KEY_INSTALL_TRACKED];
}

+ (void)setGdprForgetMe {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PREFS_KEY_GDPR_FORGET_ME];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getGdprForgetMe {
    return [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_KEY_GDPR_FORGET_ME];
}

+ (void)removeGdprForgetMe {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_GDPR_FORGET_ME];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)saveDeeplinkUrl:(NSURL *)deeplink andClickTime:(NSDate *)clickTime {
    [[NSUserDefaults standardUserDefaults] setURL:deeplink forKey:PREFS_KEY_DEEPLINK_URL];
    [[NSUserDefaults standardUserDefaults] setObject:clickTime forKey:PREFS_KEY_DEEPLINK_CLICK_TIME];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSURL *)getDeeplinkUrl {
    return [[NSUserDefaults standardUserDefaults] URLForKey:PREFS_KEY_DEEPLINK_URL];
}

+ (NSDate *)getDeeplinkClickTime {
    return [[NSUserDefaults standardUserDefaults] objectForKey:PREFS_KEY_DEEPLINK_CLICK_TIME];
}

+ (void)removeDeeplink {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_DEEPLINK_URL];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_DEEPLINK_CLICK_TIME];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)clearAdjustStuff {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_PUSH_TOKEN_DATA];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_PUSH_TOKEN_STRING];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_INSTALL_TRACKED];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_GDPR_FORGET_ME];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_DEEPLINK_URL];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREFS_KEY_DEEPLINK_CLICK_TIME];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
