//
//  Adjust.h
//  Adjust
//
//  V4.18.3
//  Created by Christian Wellenbrock (wellle) on 23rd July 2013.
//  Copyright © 2012-2017 Adjust GmbH. All rights reserved.
//

#import "ADJEvent.h"
#import "ADJConfig.h"
#import "ADJAttribution.h"

@interface AdjustTestOptions : NSObject

@property (nonatomic, copy, nullable) NSString *baseUrl;
@property (nonatomic, copy, nullable) NSString *gdprUrl;
@property (nonatomic, copy, nullable) NSString *basePath;
@property (nonatomic, copy, nullable) NSString *gdprPath;
@property (nonatomic, copy, nullable) NSNumber *timerIntervalInMilliseconds;
@property (nonatomic, copy, nullable) NSNumber *timerStartInMilliseconds;
@property (nonatomic, copy, nullable) NSNumber *sessionIntervalInMilliseconds;
@property (nonatomic, copy, nullable) NSNumber *subsessionIntervalInMilliseconds;
@property (nonatomic, assign) BOOL teardown;
@property (nonatomic, assign) BOOL deleteState;
@property (nonatomic, assign) BOOL noBackoffWait;
@property (nonatomic, assign) BOOL iAdFrameworkEnabled;

@end

/**
 * Constants for our supported tracking environments
 */
extern NSString * __nonnull const ADJEnvironmentSandbox;
extern NSString * __nonnull const ADJEnvironmentProduction;

/**
 * Constants for supported ad revenue sources.
 */
extern NSString * __nonnull const ADJAdRevenueSourceMopub;
extern NSString * __nonnull const ADJAdRevenueSourceAdmob;
extern NSString * __nonnull const ADJAdRevenueSourceFbNativeAd;
extern NSString * __nonnull const ADJAdRevenueSourceIronsource;
extern NSString * __nonnull const ADJAdRevenueSourceFyber;
extern NSString * __nonnull const ADJAdRevenueSourceAerserv;
extern NSString * __nonnull const ADJAdRevenueSourceAppodeal;
extern NSString * __nonnull const ADJAdRevenueSourceAdincube;
extern NSString * __nonnull const ADJAdRevenueSourceFusePowered;
extern NSString * __nonnull const ADJAdRevenueSourceAddaptr;
extern NSString * __nonnull const ADJAdRevenueSourceMillennialMeditation;
extern NSString * __nonnull const ADJAdRevenueSourceFlurry;
extern NSString * __nonnull const ADJAdRevenueSourceAdmost;
extern NSString * __nonnull const ADJAdRevenueSourceDeltadna;
extern NSString * __nonnull const ADJAdRevenueSourceUpsight;
extern NSString * __nonnull const ADJAdRevenueSourceUnityads;
extern NSString * __nonnull const ADJAdRevenueSourceAdtoapp;
extern NSString * __nonnull const ADJAdRevenueSourceTapdaq;

/**
 * @brief The main interface to Adjust.
 *
 * @note Use the methods of this class to tell Adjust about the usage of your app.
 *       See the README for details.
 */
@interface Adjust : NSObject

/**
 * @brief Tell Adjust that the application did launch.
 *        This is required to initialize Adjust. Call this in the didFinishLaunching
 *        method of your AppDelegate.
 *
 * @note See ADJConfig.h for more configuration options
 *
 * @param adjustConfig The configuration object that includes the environment
 *                     and the App Token of your app. This unique identifier can
 *                     be found it in your dashboard at http://adjust.com and should always
 *                     be 12 characters long.
 */
+ (void)appDidLaunch:(nullable ADJConfig *)adjustConfig;

/**
 * @brief Tell Adjust that a particular event has happened.
 *
 * @note See ADJEvent.h for more event options.
 *
 * @param event The Event object for this kind of event. It needs a event token
 *              that is created in the dashboard at http://adjust.com and should be six
 *              characters long.
 */
+ (void)trackEvent:(nullable ADJEvent *)event;

/**
 * @brief Tell adjust that the application resumed.
 *
 * @note Only necessary if the native notifications can't be used
 *       or if they will happen before call to appDidLaunch: is made.
 */
+ (void)trackSubsessionStart;

/**
 * @brief Tell adjust that the application paused.
 *
 * @note Only necessary if the native notifications can't be used.
 */
+ (void)trackSubsessionEnd;

/**
 * @brief Enable or disable the adjust SDK. This setting is saved for future sessions.
 *
 * @param enabled The flag to enable or disable the adjust SDK.
 */
+ (void)setEnabled:(BOOL)enabled;

/**
 * @brief Check if the SDK is enabled or disabled.
 *
 * return Boolean indicating whether SDK is enabled or not.
 */
+ (BOOL)isEnabled;

/**
 * @brief Read the URL that opened the application to search for an adjust deep link.
 *
 * @param url URL object which contains info about adjust deep link.
 */
+ (void)appWillOpenUrl:(nonnull NSURL *)url;

/**
 * @brief Set the device token used by push notifications.
 *
 * @param deviceToken Apple push notification token for iOS device as NSData.
 */
+ (void)setDeviceToken:(nonnull NSData *)deviceToken;

/**
 * @brief Set the device token used by push notifications.
 *        This method is only used by Adjust non native SDKs. Don't use it anywhere else.
 *
 * @param pushToken Apple push notification token for iOS device as NSString.
 */
+ (void)setPushToken:(nonnull NSString *)pushToken;

/**
 * @brief Enable or disable offline mode. Activities won't be sent but they are saved when
 *        offline mode is disabled. This feature is not saved for future sessions.
 *
 * @param enabled The flag to enable or disable offline mode.
 */
+ (void)setOfflineMode:(BOOL)enabled;

/**
 * @brief Retrieve iOS device IDFA value.
 *
 * @return Device IDFA value.
 */
+ (nullable NSString *)idfa;

/**
 * @brief Get current adjust identifier for the user.
 *
 * @note Adjust identifier is available only after installation has been successfully tracked.
 *
 * @return Current adjust identifier value for the user.
 */
+ (nullable NSString *)adid;

/**
 * @brief Get current attribution for the user.
 *
 * @note Attribution information is available only after installation has been successfully tracked
 *       and attribution information arrived after that from the backend.
 *
 * @return Current attribution value for the user.
 */
+ (nullable ADJAttribution *)attribution;

/**
 * @brief Get current Adjust SDK version string.
 *
 * @return Adjust SDK version string (iosX.Y.Z).
 */
+ (nullable NSString *)sdkVersion;

/**
 * @brief Convert a universal link style URL to a deeplink style URL with the corresponding scheme.
 *
 * @param url URL object which contains info about adjust deep link.
 * @param scheme Desired scheme to which you want your resulting URL object to be prefixed with.
 *
 * @return URL object in custom URL scheme style prefixed with given scheme name.
 */
+ (nullable NSURL *)convertUniversalLink:(nonnull NSURL *)url scheme:(nonnull NSString *)scheme;

/**
 * @brief Tell the adjust SDK to stop waiting for delayed initialisation timer to complete but rather to start
 *        upon this call. This should be called if you have obtained needed callback/partner parameters which you
 *        wanted to put as default ones before the delayedStart value you have set on ADJConfig has expired.
 */
+ (void)sendFirstPackages;

/**
 * @brief Tell adjust to send the request to Google and check if the installation
 *        belongs to Google AdWords campaign.
 *
 * @note Deprecated method, should not be used.
 */
+ (void)sendAdWordsRequest;

/**
 * @brief Add default callback parameter key-value pair which is going to be sent with each tracked session and event.
 *
 * @param key Default callback parameter key.
 * @param value Default callback parameter value.
 */
+ (void)addSessionCallbackParameter:(nonnull NSString *)key value:(nonnull NSString *)value;

/**
 * @brief Add default partner parameter key-value pair which is going to be sent with each tracked session.
 *
 * @param key Default partner parameter key.
 * @param value Default partner parameter value.
 */
+ (void)addSessionPartnerParameter:(nonnull NSString *)key value:(nonnull NSString *)value;

/**
 * @brief Remove default callback parameter from the session packages.
 *
 * @param key Default callback parameter key.
 */
+ (void)removeSessionCallbackParameter:(nonnull NSString *)key;

/**
 * @brief Remove default partner parameter from the session packages.
 *
 * @param key Default partner parameter key.
 */
+ (void)removeSessionPartnerParameter:(nonnull NSString *)key;

/**
 * @brief Remove all default callback parameters from the session packages.
 */
+ (void)resetSessionCallbackParameters;

/**
 * @brief Remove all default partner parameters from the session packages.
 */
+ (void)resetSessionPartnerParameters;

/**
 * @brief Give right user to be forgotten in accordance with GDPR law.
 */
+ (void)gdprForgetMe;

/**
 * @brief Track ad revenue for given source.
 *
 * @param source Ad revenue source.
 * @param payload Ad revenue payload.
 */
+ (void)trackAdRevenue:(nonnull NSString *)source payload:(nonnull NSData *)payload;

/**
 * Obtain singleton Adjust object.
 */
+ (nullable id)getInstance;

+ (void)setTestOptions:(nullable AdjustTestOptions *)testOptions;

- (void)appDidLaunch:(nullable ADJConfig *)adjustConfig;

- (void)trackEvent:(nullable ADJEvent *)event;

- (void)setEnabled:(BOOL)enabled;

- (void)teardown;

- (void)appWillOpenUrl:(nonnull NSURL *)url;

- (void)setOfflineMode:(BOOL)enabled;

- (void)setDeviceToken:(nonnull NSData *)deviceToken;

- (void)setPushToken:(nonnull NSString *)pushToken;

- (void)sendFirstPackages;

- (void)trackSubsessionEnd;

- (void)trackSubsessionStart;

- (void)resetSessionPartnerParameters;

- (void)resetSessionCallbackParameters;

- (void)removeSessionPartnerParameter:(nonnull NSString *)key;

- (void)removeSessionCallbackParameter:(nonnull NSString *)key;

- (void)addSessionPartnerParameter:(nonnull NSString *)key value:(nonnull NSString *)value;

- (void)addSessionCallbackParameter:(nonnull NSString *)key value:(nonnull NSString *)value;

- (void)gdprForgetMe;

- (void)trackAdRevenue:(nonnull NSString *)source payload:(nonnull NSData *)payload;

- (BOOL)isEnabled;

- (nullable NSString *)adid;

- (nullable NSString *)idfa;

- (nullable NSString *)sdkVersion;

- (nullable ADJAttribution *)attribution;

- (nullable NSURL *)convertUniversalLink:(nonnull NSURL *)url scheme:(nonnull NSString *)scheme;

@end
