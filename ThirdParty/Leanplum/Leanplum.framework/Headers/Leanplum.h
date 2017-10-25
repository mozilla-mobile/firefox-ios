//
//  Leanplum.h
//  Leanplum iOS SDK Version 2.0.3
//
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LPInbox.h"

#ifndef LP_NOT_TV
#define LP_NOT_TV (!defined(TARGET_OS_TV) || !TARGET_OS_TV)
#endif

#define _LP_DEFINE_HELPER(name,val,type) LPVar* name; \
static void __attribute__((constructor)) initialize_##name() { \
@autoreleasepool { \
name = [LPVar define:[@#name stringByReplacingOccurrencesOfString:@"_" withString:@"."] with##type:val]; \
} \
}

/**
 * @defgroup Macros Variable Macros
 * Use these macros to define variables inside your app.
 * Underscores within variable names will nest variables within groups.
 * To define variables in a more custom way, copy and modify
 * the template above in your own code.
 * @see LPVar
 * @{
 */
#define DEFINE_VAR_INT(name,val) _LP_DEFINE_HELPER(name, val, Int)
#define DEFINE_VAR_BOOL(name,val) _LP_DEFINE_HELPER(name, val, Bool)
#define DEFINE_VAR_STRING(name,val) _LP_DEFINE_HELPER(name, val, String)
#define DEFINE_VAR_NUMBER(name,val) _LP_DEFINE_HELPER(name, val, Number)
#define DEFINE_VAR_FLOAT(name,val) _LP_DEFINE_HELPER(name, val, Float)
#define DEFINE_VAR_CGFLOAT(name,val) _LP_DEFINE_HELPER(name, val, CGFloat)
#define DEFINE_VAR_DOUBLE(name,val) _LP_DEFINE_HELPER(name, val, Double)
#define DEFINE_VAR_SHORT(name,val) _LP_DEFINE_HELPER(name, val, Short)
#define DEFINE_VAR_LONG(name,val) _LP_DEFINE_HELPER(name, val, Long)
#define DEFINE_VAR_CHAR(name,val) _LP_DEFINE_HELPER(name, val, Char)
#define DEFINE_VAR_LONG_LONG(name,val) _LP_DEFINE_HELPER(name, val, LongLong)
#define DEFINE_VAR_INTEGER(name,val) _LP_DEFINE_HELPER(name, val, Integer)
#define DEFINE_VAR_UINT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInt)
#define DEFINE_VAR_UCHAR(name,val) _LP_DEFINE_HELPER(name, val, UnsignedChar)
#define DEFINE_VAR_ULONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLong)
#define DEFINE_VAR_UINTEGER(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInteger)
#define DEFINE_VAR_USHORT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedShort)
#define DEFINE_VAR_ULONGLONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLongLong)
#define DEFINE_VAR_UNSIGNED_INT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInt)
#define DEFINE_VAR_UNSIGNED_INTEGER(name,val) _LP_DEFINE_HELPER(name, val, UnsignedInteger)
#define DEFINE_VAR_UNSIGNED_CHAR(name,val) _LP_DEFINE_HELPER(name, val, UnsignedChar)
#define DEFINE_VAR_UNSIGNED_LONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLong)
#define DEFINE_VAR_UNSIGNED_LONG_LONG(name,val) _LP_DEFINE_HELPER(name, val, UnsignedLongLong)
#define DEFINE_VAR_UNSIGNED_SHORT(name,val) _LP_DEFINE_HELPER(name, val, UnsignedShort)
#define DEFINE_VAR_FILE(name,filename) _LP_DEFINE_HELPER(name, filename, File)
#define DEFINE_VAR_DICTIONARY(name,dict) _LP_DEFINE_HELPER(name, dict, Dictionary)
#define DEFINE_VAR_ARRAY(name,array) _LP_DEFINE_HELPER(name, array, Array)
#define DEFINE_VAR_COLOR(name,val) _LP_DEFINE_HELPER(name, val, Color)

#define DEFINE_VAR_DICTIONARY_WITH_OBJECTS_AND_KEYS(name,...) LPVar* name; \
static void __attribute__((constructor)) initialize_##name() { \
@autoreleasepool { \
name = [LPVar define:[@#name stringByReplacingOccurrencesOfString:@"_" withString:@"."] withDictionary:[NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__]]; \
} \
}

#define DEFINE_VAR_ARRAY_WITH_OBJECTS(name,...) LPVar* name; \
static void __attribute__((constructor)) initialize_##name() { \
@autoreleasepool { \
name = [LPVar define:[@#name stringByReplacingOccurrencesOfString:@"_" withString:@"."] withArray:[NSArray arrayWithObjects:__VA_ARGS__]]; \
} \
}
/**@}*/

/**
 * Use this code in development mode (or in production), to use the advertising ID.
 * It's useful in development mode so that we remember your device even if you reinstall your app.
 * Since it's a MACRO, this won't get compiled into your app in production, and will be safe
 * to submit to Apple.
 */
#define LEANPLUM_USE_ADVERTISING_ID \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
    id LeanplumIdentifierManager = [NSClassFromString(@"ASIdentifierManager") \
                            performSelector:NSSelectorFromString(@"sharedManager")]; \
    if (floor(NSFoundationVersionNumber) <= 1299 /* NSFoundationVersionNumber_iOS_9_x_Max */ || \
        [LeanplumIdentifierManager performSelector: \
          NSSelectorFromString(@"isAdvertisingTrackingEnabled")]) { \
        /* < iOS10 || isAdvertisingTrackingEnabled */ \
        [Leanplum setDeviceId:[[LeanplumIdentifierManager performSelector: \
                                NSSelectorFromString(@"advertisingIdentifier")] \
                               performSelector:NSSelectorFromString(@"UUIDString")]]; \
    } \
    _Pragma("clang diagnostic pop")

@class LPActionContext;
@class SKPaymentTransaction;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@class NSExtensionContext;
#endif

/**
 * @defgroup _ Callback Blocks
 * Those blocks are used when you define callbacks.
 * @{
 */
typedef void (^LeanplumStartBlock)(BOOL success);
typedef void (^LeanplumVariablesChangedBlock)(void);
typedef void (^LeanplumInterfaceChangedBlock)(void);
typedef void (^LeanplumSetLocationBlock)(BOOL success);
// Returns whether the action was handled.
typedef BOOL (^LeanplumActionBlock)(LPActionContext* context);
typedef void (^LeanplumHandleNotificationBlock)(void);
typedef void (^LeanplumShouldHandleNotificationBlock)(NSDictionary *userInfo, LeanplumHandleNotificationBlock response);
typedef NSUInteger LeanplumUIBackgroundFetchResult; // UIBackgroundFetchResult
typedef void (^LeanplumFetchCompletionBlock)(LeanplumUIBackgroundFetchResult result);
typedef void (^LeanplumPushSetupBlock)(void);
/**@}*/

/**
 * Leanplum Action Kind Message types
 * This is a bit-field. To choose both kinds, use
 * kLeanplumActionKindMessage | kLeanplumActionKindAction
 */
typedef enum {
    kLeanplumActionKindMessage = 0b1,
    kLeanplumActionKindAction = 0b10,
} LeanplumActionKind;

#define LP_PURCHASE_EVENT @"Purchase"

@interface Leanplum : NSObject

/**
 * Optional. Sets the API server. The API path is of the form http[s]://hostname/servletName
 * @param hostName The name of the API host, such as api.leanplum.com
 * @param servletName The name of the API servlet, such as api
 * @param ssl Whether to use SSL
 */
+ (void)setApiHostName:(NSString *)hostName withServletName:(NSString *)servletName usingSsl:(BOOL)ssl;

/**
 * Optional. Adjusts the network timeouts.
 * The default timeout is 10 seconds for requests, and 15 seconds for file downloads.
 * @{
 */
+ (void)setNetworkTimeoutSeconds:(int)seconds;
+ (void)setNetworkTimeoutSeconds:(int)seconds forDownloads:(int)downloadSeconds;
/**@}*/

/**
 * Sets whether to show the network activity indicator in the status bar when making requests.
 * Default: YES.
 */
+ (void)setNetworkActivityIndicatorEnabled:(BOOL)enabled;

/**
 * Advanced: Whether new variables can be downloaded mid-session. By default, this is disabled.
 * Currently, if this is enabled, new variables can only be downloaded if a push notification is sent
 * while the app is running, and the notification's metadata hasn't be downloaded yet.
 */
+ (void)setCanDownloadContentMidSessionInProductionMode:(BOOL)value;

/**
 * Modifies the file hashing setting in development mode.
 * By default, Leanplum will hash file variables to determine if they're modified and need
 * to be uploaded to the server if we're running in the simulator.
 * Setting this to NO will reduce startup latency in development mode, but it's possible
 * that Leanplum will not always have the most up-to-date versions of your resources.
 */
+ (void)setFileHashingEnabledInDevelopmentMode:(BOOL)enabled;

/**
 * Sets whether to enable verbose logging in development mode. Default: NO.
 */
+ (void)setVerboseLoggingInDevelopmentMode:(BOOL)enabled;

/**
 * Sets a custom event name for in-app purchase tracking. Default: Purchase.
 */
+ (void)setInAppPurchaseEventName:(NSString *)event;

/**
 * @{
 * Must call either this or {@link setAppId:withProductionKey:}
 * before issuing any calls to the API, including start.
 * @param appId Your app ID.
 * @param accessKey Your development key.
 */
+ (void)setAppId:(NSString *)appId withDevelopmentKey:(NSString *)accessKey;

/**
 * Must call either this or {@link Leanplum::setAppId:withDevelopmentKey:}
 * before issuing any calls to the API, including start.
 * @param appId Your app ID.
 * @param accessKey Your production key.
 */
+ (void)setAppId:(NSString *)appId withProductionKey:(NSString *)accessKey;
/**@}*/

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
/**
 * Apps running as extensions need to call this before start.
 * @param context The current extensionContext. You can get this from UIViewController.
 */
+ (void)setExtensionContext:(NSExtensionContext *)context;
#endif

/**
 * @{
 * Call this before start to allow your interfaces to change on the fly.
 * Needed in development mode to enable the interface editor, as well as in production to allow
 * changes to be applied.
 */
+ (void)allowInterfaceEditing __attribute__((deprecated("Use LeanplumUIEditor pod instead.")));

/**
 * Check if interface editing is enabled.
 */
+ (BOOL)interfaceEditingEnabled __attribute__((deprecated("Use LeanplumUIEditor pod instead.")));

/**@}*/

/**
 * Sets a custom device ID. For example, you may want to pass the advertising ID to do attribution.
 * By default, the device ID is the identifier for vendor.
 */
+ (void)setDeviceId:(NSString *)deviceId;

/**
 * By default, Leanplum reports the version of your app using CFBundleVersion, which
 * can be used for reporting and targeting on the Leanplum dashboard.
 * If you wish to use CFBundleShortVersionString or any other string as the version,
 * you can call this before your call to [Leanplum start]
 */
+ (void)setAppVersion:(NSString *)appVersion;

/**
 * @{
 * Syncs resources between Leanplum and the current app.
 * You should only call this once, and before {@link start}.
 * Deprecated. Use {@link syncResourcesAsync:} instead.
 */
+ (void)syncResources __attribute__((deprecated));

/**
 * Syncs resources between Leanplum and the current app.
 * You should only call this once, and before {@link start}.
 * @param async Whether the call should be asynchronous. Resource syncing can take 1-2 seconds to
 *     index the app's resources. If async is set, resources may not be available immediately
 *     when the app starts.
 */
+ (void)syncResourcesAsync:(BOOL)async;

/**
 * Syncs resources between Leanplum and the current app.
 * You should only call this once, and before {@link start}.
 * Deprecated. Use {@link syncResourcePaths:excluding:async} instead.
 * @param async Whether the call should be asynchronous. Resource syncing can take 1-2 seconds to
 *     index the app's resources. If async is set, resources may not be available immediately
 *     when the app starts.
 * @param patternsToIncludeOrNil Limit paths to only those matching at least one pattern in this
 *     list. Supply nil to indicate no inclusion patterns. Paths are relative to the app's bundle.
 * @param patternsToExcludeOrNil Exclude paths matching at least one of these patterns.
 *     Supply nil to indicate no exclusion patterns.
 */
+ (void)syncResourcePaths:(NSArray *)patternsToIncludeOrNil
                excluding:(NSArray *)patternsToExcludeOrNil __attribute__((deprecated));

/**
 * Syncs resources between Leanplum and the current app.
 * You should only call this once, and before {@link start}.
 * @param async Whether the call should be asynchronous. Resource syncing can take 1-2 seconds to
 *     index the app's resources. If async is set, resources may not be available immediately
 *     when the app starts.
 * @param patternsToIncludeOrNil Limit paths to only those matching at least one pattern in this
 *     list. Supply nil to indicate no inclusion patterns. Paths are relative to the app's bundle.
 * @param patternsToExcludeOrNil Exclude paths matching at least one of these patterns.
 *     Supply nil to indicate no exclusion patterns.
 * @param async Whether the call should be asynchronous. Resource syncing can take 1-2 seconds to
 *     index the app's resources. If async is set, resources may not be available immediately
 *     when the app starts.
 */
+ (void)syncResourcePaths:(NSArray *)patternsToIncludeOrNil
                excluding:(NSArray *)patternsToExcludeOrNil
                    async:(BOOL)async;
/**@}*/

/**
 * @{
 * Call this when your application starts.
 * This will initiate a call to Leanplum's servers to get the values
 * of the variables used in your app.
 */
+ (void)start;
+ (void)startWithResponseHandler:(LeanplumStartBlock)response;
+ (void)startWithUserAttributes:(NSDictionary *)attributes;
+ (void)startWithUserId:(NSString *)userId;
+ (void)startWithUserId:(NSString *)userId responseHandler:(LeanplumStartBlock)response;
+ (void)startWithUserId:(NSString *)userId userAttributes:(NSDictionary *)attributes;
+ (void)startWithUserId:(NSString *)userId userAttributes:(NSDictionary *)attributes
        responseHandler:(LeanplumStartBlock)startResponse;
/**@}*/

/**
 * @{
 * Returns whether or not Leanplum has finished starting.
 */
+ (BOOL)hasStarted;

/**
 * Returns whether or not Leanplum has finished starting and the device is registered
 * as a developer.
 */
+ (BOOL)hasStartedAndRegisteredAsDeveloper;
/**@}*/

/**
 * Block to call when the start call finishes, and variables are returned
 * back from the server. Calling this multiple times will call each block
 * in succession.
 */
+ (void)onStartResponse:(LeanplumStartBlock)block;

/**
 * Block to call when the variables receive new values from the server.
 * This will be called on start, and also later on if the user is in an experiment
 * that can update in realtime.
 */
+ (void)onVariablesChanged:(LeanplumVariablesChangedBlock)block;

/**
 * Block to call when the interface receive new values from the server.
 * This will be called on start, and also later on if the user is in an experiment
 * that can update in realtime.
 */
+ (void)onInterfaceChanged:(LeanplumInterfaceChangedBlock)block;

/**
 * Block to call when no more file downloads are pending (either when
 * no files needed to be downloaded or all downloads have been completed).
 */
+ (void)onVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block;

/**
 * Block to call ONCE when no more file downloads are pending (either when
 * no files needed to be downloaded or all downloads have been completed).
 */
+ (void)onceVariablesChangedAndNoDownloadsPending:(LeanplumVariablesChangedBlock)block;

/**
 * @{
 * Defines new action and message types to be performed at points set up on the Leanplum dashboard.
 */
+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args;
+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
         withOptions:(NSDictionary *)options;
+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
       withResponder:(LeanplumActionBlock)responder;
+ (void)defineAction:(NSString *)name ofKind:(LeanplumActionKind)kind withArguments:(NSArray *)args
         withOptions:(NSDictionary *)options
       withResponder:(LeanplumActionBlock)responder;
/**@}*/

/**
 * Block to call when an action is received, such as to show a message to the user.
 */
+ (void)onAction:(NSString *)actionName invoke:(LeanplumActionBlock)block;

/**
 * Handles a push notification for apps that use Background Notifications.
 * Without background notifications, Leanplum handles them automatically.
 * Deprecated. Leanplum calls handleNotification automatically now. If you
 * implement application:didReceiveRemoteNotification:fetchCompletionHandler:
 * in your app delegate, you should remove any calls to [Leanplum handleNotification]
 * and call the completion handler yourself.
 */
+ (void)handleNotification:(NSDictionary *)userInfo
    fetchCompletionHandler:(LeanplumFetchCompletionBlock)completionHandler
    __attribute__((deprecated("Leanplum calls handleNotification automatically now. If you "
        "implement application:didReceiveRemoteNotification:fetchCompletionHandler: in your app "
        "delegate, you should remove any calls to [Leanplum handleNotification] and call the "
        "completion handler yourself.")));

#if LP_NOT_TV
/**
 * Call this to handle custom actions for local notifications.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
+ (void)handleActionWithIdentifier:(NSString *)identifier
              forLocalNotification:(UILocalNotification *)notification
                 completionHandler:(void (^)())completionHandler;
#pragma clang diagnostic pop
#endif

/**
 * Call this to handle custom actions for remote notifications.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
+ (void)handleActionWithIdentifier:(NSString *)identifier
             forRemoteNotification:(NSDictionary *)notification
                 completionHandler:(void (^)())completionHandler;
#pragma clang diagnostic pop

/*
 * Block to call that decides whether a notification should be displayed when it is
 * received while the app is running, and the notification is not muted.
 * Overrides the default behavior of showing an alert view with the notification message.
 */
+ (void)setShouldOpenNotificationHandler:(LeanplumShouldHandleNotificationBlock)block;

/**
 * @{
 * Adds a responder to be executed when an event happens.
 * Similar to the methods above but uses NSInvocations instead of blocks.
 * @see onStartResponse:
 */
+ (void)addStartResponseResponder:(id)responder withSelector:(SEL)selector;
+ (void)addVariablesChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)addInterfaceChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)addVariablesChangedAndNoDownloadsPendingResponder:(id)responder withSelector:(SEL)selector;
+ (void)addResponder:(id)responder withSelector:(SEL)selector forActionNamed:(NSString *)actionName;
+ (void)removeStartResponseResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeVariablesChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeInterfaceChangedResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeVariablesChangedAndNoDownloadsPendingResponder:(id)responder withSelector:(SEL)selector;
+ (void)removeResponder:(id)responder withSelector:(SEL)selector forActionNamed:(NSString *)actionName;
/**@}*/

/**
 * Sets additional user attributes after the session has started.
 * Variables retrieved by start won't be targeted based on these attributes, but
 * they will count for the current session for reporting purposes.
 * Only those attributes given in the dictionary will be updated. All other
 * attributes will be preserved.
 */
+ (void)setUserAttributes:(NSDictionary *)attributes;

/**
 * Updates a user ID after session start.
 */
+ (void)setUserId:(NSString *)userId;

/**
 * Updates a user ID after session start with a dictionary of user attributes.
 */
+ (void)setUserId:(NSString *)userId withUserAttributes:(NSDictionary *)attributes;

/**
 * Sets the traffic source info for the current user.
 * Keys in info must be one of: publisherId, publisherName, publisherSubPublisher,
 * publisherSubSite, publisherSubCampaign, publisherSubAdGroup, publisherSubAd.
 */
+ (void)setTrafficSourceInfo:(NSDictionary *)info;

/**
 * @{
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * @param state The name of the state.
 */
+ (void)advanceTo:(NSString *)state;

/**
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * @param state The name of the state.
 * @param info Anything else you want to log with the state. For example, if the state
 * is watchVideo, info could be the video ID.
 */
+ (void)advanceTo:(NSString *)state withInfo:(NSString *)info;

/**
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * You can specify up to 200 types of parameters per app across all events and state.
 * The parameter keys must be strings, and values either strings or numbers.
 * @param state The name of the state.
 * @param params A dictionary with custom parameters.
 */
+ (void)advanceTo:(NSString *)state withParameters:(NSDictionary *)params;

/**
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * You can specify up to 200 types of parameters per app across all events and state.
 * The parameter keys must be strings, and values either strings or numbers.
 * @param state The name of the state. (nullable)
 * @param info Anything else you want to log with the state. For example, if the state
 * is watchVideo, info could be the video ID.
 * @param params A dictionary with custom parameters.
 */
+ (void)advanceTo:(NSString *)state withInfo:(NSString *)info andParameters:(NSDictionary *)params;

/**
 * Pauses the current state.
 * You can use this if your game has a "pause" mode. You shouldn't call it
 * when someone switches out of your app because that's done automatically.
 */
+ (void)pauseState;

/**
 * Resumes the current state.
 */
+ (void)resumeState;

/**
 * Automatically tracks all of the screens in the app as states.
 * You should not use this in conjunction with advanceTo as the user can only be in
 * 1 state at a time. This method requires LeanplumUIEditor module.
 */
+ (void)trackAllAppScreens;

/**
 * LPTrackScreenMode enum.
 * LPTrackScreenModeDefault mans that states are the full view controller type name.
 * LPTrackScreenModeStripViewController will cause the string "ViewController" to be stripped from
 * the end of the state.
 */
typedef NS_ENUM(NSUInteger, LPTrackScreenMode) {
    LPTrackScreenModeDefault = 0,
    LPTrackScreenModeStripViewController
};

/**
 * Automatically tracks all of the screens in the app as states.
 * You should not use this in conjunction with advanceTo as the user can only be in
 * 1 state at a time. This method requires LeanplumUIEditor module.
 * @param trackScreenMode Choose mode for display. Default is the view controller type name.
 */
+ (void)trackAllAppScreensWithMode:(LPTrackScreenMode)trackScreenMode;

/**
 * Manually track purchase event with currency code in your application. It is advised to use
 * trackInAppPurchases to automatically track IAPs.
 */
+ (void)trackPurchase:(NSString *)event withValue:(double)value
      andCurrencyCode:(NSString *)currencyCode andParameters:(NSDictionary *)params;

/**
 * Automatically tracks InApp purchase and does server side receipt validation.
 */
+ (void)trackInAppPurchases;

/**
 * Manually tracks InApp purchase and does server side receipt validation.
 */
+ (void)trackInAppPurchase:(SKPaymentTransaction *)transaction;
/**@}*/

/**
 * @{
 * Logs a particular event in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * To track a purchase, use LP_PURCHASE_EVENT.
 */
+ (void)track:(NSString *)event;
+ (void)track:(NSString *)event withValue:(double)value;
+ (void)track:(NSString *)event withInfo:(NSString *)info;
+ (void)track:(NSString *)event withValue:(double)value andInfo:(NSString *)info;

// See above for the explanation of params.
+ (void)track:(NSString *)event withParameters:(NSDictionary *)params;
+ (void)track:(NSString *)event withValue:(double)value andParameters:(NSDictionary *)params;
+ (void)track:(NSString *)event withValue:(double)value andInfo:(NSString *)info andParameters:(NSDictionary *)params;
/**@}*/

/**
 * @{
 * Gets the path for a particular resource. The resource can be overridden by the server.
 */
+ (NSString *)pathForResource:(NSString *)name ofType:(NSString *)extension;
+ (id)objectForKeyPath:(id)firstComponent, ... NS_REQUIRES_NIL_TERMINATION;
+ (id)objectForKeyPathComponents:(NSArray *)pathComponents;
/**@}*/

/**
 * Gets a list of variants that are currently active for this user.
 * Each variant is a dictionary containing an id.
 */
+ (NSArray *)variants;

/**
 * Returns metadata for all active in-app messages.
 * Recommended only for debugging purposes and advanced use cases.
 */
+ (NSDictionary *)messageMetadata;

/**
 * Forces content to update from the server. If variables have changed, the
 * appropriate callbacks will fire. Use sparingly as if the app is updated,
 * you'll have to deal with potentially inconsistent state or user experience.
 */
+ (void)forceContentUpdate;

/**
 * Forces content to update from the server. If variables have changed, the
 * appropriate callbacks will fire. Use sparingly as if the app is updated,
 * you'll have to deal with potentially inconsistent state or user experience.
 * The provided callback will always fire regardless
 * of whether the variables have changed.
 */
+ (void)forceContentUpdate:(LeanplumVariablesChangedBlock)block;

/**
 * This should be your first statement in a unit test. This prevents
 * Leanplum from communicating with the server.
 */
+ (void)enableTestMode;

/**
 * Used to enable or disable test mode. Test mode prevents Leanplum from
 * communicating with the server. This is useful for unit tests.
 */
+ (void)setTestModeEnabled:(BOOL)isTestModeEnabled;

/**
 * Customize push setup. If this API should be called before [Leanplum start]. If this API is not
 * used the default push setup from the docs will be used for "Push Ask to Ask" and 
 * "Register For Push".
 */
+ (void)setPushSetup:(LeanplumPushSetupBlock)block;

/**
 * Get the push setup block.
 */
+ (LeanplumPushSetupBlock)pushSetupBlock;

/**
 * Returns YES if the app existed on the device more than a day previous to a version built with
 * Leanplum was installed.
 */
+ (BOOL)isPreLeanplumInstall;

/**
 * Returns the deviceId in the current Leanplum session. This should only be called after
 * [Leanplum start].
 */
+ (NSString *)deviceId;

/**
 * Returns the userId in the current Leanplum session. This should only be called after
 * [Leanplum start].
 */
+ (NSString *)userId;

/**
 * Returns an instance to the singleton LPInbox object.
 */
+ (LPInbox *)inbox;

/**
 * Returns an instance to the singleton LPNewsfeed object.
 * Deprecated. Use {@link inbox} instead.
 */
+ (LPNewsfeed *)newsfeed __attribute__((deprecated("Use inbox instead.")));

/**
 * Types of location accuracy. Higher value implies better accuracy.
 */
typedef enum {
    LPLocationAccuracyIP = 0,
    LPLocationAccuracyCELL = 1,
    LPLocationAccuracyGPS = 2
} LPLocationAccuracyType;

/**
 * Set location manually. Calls setDeviceLocationWithLatitude:longitude:type: with cell type.
 * Best if used in after calling setDeviceLocationWithLatitude:.
 */
+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude;

/**
 * Set location manually. Best if used in after calling setDeviceLocationWithLatitude:.
 * Useful if you want to apply additional logic before sending in the location.
 */
+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
                                 type:(LPLocationAccuracyType)type;

/**
 * Set location manually. Best if used in after calling setDeviceLocationWithLatitude:.
 * If you have the CLPlacemark info: city is locality, region is administrativeArea,
 * and country is ISOcountryCode.
 */
+ (void)setDeviceLocationWithLatitude:(double)latitude
                            longitude:(double)longitude
                                 city:(NSString *)city
                               region:(NSString *)region
                              country:(NSString *)country
                                 type:(LPLocationAccuracyType)type;

/**
 * Disables collecting location automatically. Will do nothing if Leanplum-Location is not used.
 */
+ (void)disableLocationCollection;

@end

@interface LeanplumCompatibility : NSObject

/**
 * Used only for compatibility with Google Analytics.
 */
+ (void)gaTrack:(NSObject *)trackingObject;

@end

@class LPVar;

/**
 * Receives callbacks for {@link LPVar}
 */
@protocol LPVarDelegate <NSObject>
@optional
/**
 * For file variables, called when the file is ready.
 */
- (void)fileIsReady:(LPVar *)var;
/**
 * Called when the value of the variable changes.
 */
- (void)valueDidChange:(LPVar *)var;
@end

/**
 * A variable is any part of your application that can change from an experiment.
 * Check out {@link Macros the macros} for defining variables more easily.
 */
@interface LPVar : NSObject
/**
 * @{
 * Defines a {@link LPVar}
 */

+ (LPVar *)define:(NSString *)name;
+ (LPVar *)define:(NSString *)name withInt:(int)defaultValue;
+ (LPVar *)define:(NSString *)name withFloat:(float)defaultValue;
+ (LPVar *)define:(NSString *)name withDouble:(double)defaultValue;
+ (LPVar *)define:(NSString *)name withCGFloat:(CGFloat)cgFloatValue;
+ (LPVar *)define:(NSString *)name withShort:(short)defaultValue;
+ (LPVar *)define:(NSString *)name withChar:(char)defaultValue;
+ (LPVar *)define:(NSString *)name withBool:(BOOL)defaultValue;
+ (LPVar *)define:(NSString *)name withString:(NSString *)defaultValue;
+ (LPVar *)define:(NSString *)name withNumber:(NSNumber *)defaultValue;
+ (LPVar *)define:(NSString *)name withInteger:(NSInteger)defaultValue;
+ (LPVar *)define:(NSString *)name withLong:(long)defaultValue;
+ (LPVar *)define:(NSString *)name withLongLong:(long long)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedChar:(unsigned char)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedInt:(unsigned int)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedInteger:(NSUInteger)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedLong:(unsigned long)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedLongLong:(unsigned long long)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedShort:(unsigned short)defaultValue;
+ (LPVar *)define:(NSString *)name withFile:(NSString *)defaultFilename;
+ (LPVar *)define:(NSString *)name withDictionary:(NSDictionary *)defaultValue;
+ (LPVar *)define:(NSString *)name withArray:(NSArray *)defaultValue;
+ (LPVar *)define:(NSString *)name withColor:(UIColor *)defaultValue;
/**@}*/

/**
 * Returns the name of the variable.
 */
- (NSString *)name;

/**
 * Returns the components of the variable's name.
 */
- (NSArray *)nameComponents;

/**
 * Returns the default value of a variable.
 */
- (id)defaultValue;

/**
 * Returns the kind of the variable.
 */
- (NSString *)kind;

/**
 * Returns whether the variable has changed since the last time the app was run.
 */
- (BOOL)hasChanged;

/**
 * For file variables, called when the file is ready.
 */
- (void)onFileReady:(LeanplumVariablesChangedBlock)block;

/**
 * Called when the value of the variable changes.
 */
- (void)onValueChanged:(LeanplumVariablesChangedBlock)block;

/**
 * Sets the delegate of the variable in order to use
 * {@link LPVarDelegate::fileIsReady:} and {@link LPVarDelegate::valueDidChange:}
 */
- (void)setDelegate:(id <LPVarDelegate>)delegate;

/**
 * @{
 * Accessess the value(s) of the variable
 */
- (id)objectForKey:(NSString *)key;
- (id)objectAtIndex:(NSUInteger )index;
- (id)objectForKeyPath:(id)firstComponent, ... NS_REQUIRES_NIL_TERMINATION;
- (id)objectForKeyPathComponents:(NSArray *)pathComponents;
- (NSUInteger)count;

- (NSNumber *)numberValue;
- (NSString *)stringValue;
- (NSString *)fileValue;
- (UIImage *)imageValue;
- (int)intValue;
- (double)doubleValue;
- (CGFloat)cgFloatValue;
- (float)floatValue;
- (short)shortValue;
- (BOOL)boolValue;
- (char)charValue;
- (long)longValue;
- (long long)longLongValue;
- (NSInteger)integerValue;
- (unsigned char)unsignedCharValue;
- (unsigned short)unsignedShortValue;
- (unsigned int)unsignedIntValue;
- (NSUInteger)unsignedIntegerValue;
- (unsigned long)unsignedLongValue;
- (unsigned long long)unsignedLongLongValue;
- (UIColor *)colorValue;
/**@}*/
@end

@interface LPActionArg : NSObject
/**
 * @{
 * Defines a Leanplum Action Argument
 */
+ (LPActionArg *)argNamed:(NSString *)name withNumber:(NSNumber *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withString:(NSString *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withBool:(BOOL)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withFile:(NSString *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withDict:(NSDictionary *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withArray:(NSArray *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withAction:(NSString *)defaultValue;
+ (LPActionArg *)argNamed:(NSString *)name withColor:(UIColor *)defaultValue;
/**@}*/
- (NSString *)name;
- (NSString *)kind;
- (id)defaultValue;

@end

@interface LPActionContext : NSObject

- (NSString *)actionName;

- (NSString *)stringNamed:(NSString *)name;
- (NSString *)fileNamed:(NSString *)name;
- (NSNumber *)numberNamed:(NSString *)name;
- (BOOL)boolNamed:(NSString *)name;
- (NSDictionary *)dictionaryNamed:(NSString *)name;
- (NSArray *)arrayNamed:(NSString *)name;
- (UIColor *)colorNamed:(NSString *)name;
- (NSString *)htmlWithTemplateNamed:(NSString *)templateName;

/**
 * Runs the action given by the "name" key.
 */
- (void)runActionNamed:(NSString *)name;

/**
 * Runs and tracks an event for the action given by the "name" key.
 * This will track an event if no action is set.
 */
- (void)runTrackedActionNamed:(NSString *)name;

/**
 * Tracks an event in the context of the current message.
 */
- (void)track:(NSString *)event withValue:(double)value andParameters:(NSDictionary *)params;

/**
 * Tracks an event in the conext of the current message, with any parent actions prepended to the
 * message event name.
 */
- (void)trackMessageEvent:(NSString *)event
                withValue:(double)value
                  andInfo:(NSString *)info
            andParameters:(NSDictionary *)params;

/**
 * Prevents the currently active message from appearing again in the future.
 */
- (void)muteFutureMessagesOfSameKind;

/**
 * Checks if the action context has any missing files that still need to be downloaded.
 */
- (BOOL)hasMissingFiles;

@end
