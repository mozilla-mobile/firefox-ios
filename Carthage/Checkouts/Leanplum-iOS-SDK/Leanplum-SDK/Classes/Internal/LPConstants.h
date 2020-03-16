//
//  LPConstants.h
//  Leanplum
//
//  Created by Andrew First on 5/2/12.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
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

#define IOS_6_SUPPORTED defined(_ARM_ARCH_7) || defined(__i386__) || defined(__LP64__)

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define IS_SUPPORTED_IOS_VERSION (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"4.3"))
#define RETURN_IF_NOT_SUPPORTED_IOS_VERSION if (!(IS_SUPPORTED_IOS_VERSION)) return;
#define APP_NAME (([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]) ?: \
([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]))

#define RETURN_IF_TEST_MODE if ([LPConstantsState sharedState].isTestMode) return

#define IS_JAILBROKEN ([[[NSBundle mainBundle] infoDictionary] objectForKey: @"SignerIdentity"] != nil)

#define IS_NOOP ((!IS_SUPPORTED_IOS_VERSION) || IS_JAILBROKEN || [LPConstantsState sharedState].isTestMode || [LPConstantsState sharedState].isInPermanentFailureState)
#define RETURN_IF_NOOP if (IS_NOOP) return

#define LEANPLUM_SDK_VERSION @"2.6.3"
#define LEANPLUM_CLIENT @"ios"
#define LEANPLUM_SUPPORTED_ENCODING @"gzip"

// Can upload up to 100 files or 50 MB per request.
#define MAX_UPLOAD_BATCH_SIZES (50 * (1 << 20))
#define MAX_UPLOAD_BATCH_FILES 100
#define MAX_FILES_SUPPORTED 1000

#define HEARTBEAT_INTERVAL 15 * 60 // 15 minutes

#define MAX_STORED_OCCURRENCES_PER_MESSAGE 100
#define MAX_EVENTS_PER_API_CALL 10000

#define DEFAULT_PRIORITY 1000

#define IOS_GEOFENCE_LIMIT 20 // As of 07/07/2016.

#define LP_IV @"__l3anplum_iv__"
#define LP_IS_LOGGING @"leanplum_isLogging"

#define LP_EDITOR_REDRAW_DELAY 0.1

#define LP_REQUEST_DEVELOPMENT_MIN_DELAY 0.1
#define LP_REQUEST_DEVELOPMENT_MAX_DELAY 5.0
#define LP_REQUEST_PRODUCTION_DELAY 60.0
#define LP_REQUEST_RESUME_DELAY 1.0

#ifdef UI_USER_INTERFACE_IDIOM
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#else
#define IS_IPAD (false)
#endif

#define MACRO_NAME(x) #x
#define MACRO_VALUE(x) MACRO_NAME(x)

@interface LPConstantsState : NSObject {
    NSString *_apiHostName;
    NSString *_apiServlet;
    BOOL _apiSSL;
    NSString *_socketHost;
    int _socketPort;
    int _networkTimeoutSeconds;
    int _networkTimeoutSecondsForDownloads;
    int _syncNetworkTimeoutSeconds;
    BOOL _checkForUpdatesInDevelopmentMode;
    BOOL _isDevelopmentModeEnabled;
    BOOL _loggingEnabled;
    BOOL _canDownloadContentMidSessionInProduction;
    BOOL _isTestMode;
    BOOL _isInPermanentFailureState;
    BOOL _verboseLoggingInDevelopmentMode;
    BOOL _networkActivityIndicatorEnabled;
    NSString *_client;
    NSString *_sdkVersion;
    // Counts how many user code blocks we're inside, to silence exceptions.
    // This is used by LP_BEGIN_USER_CODE and LP_END_USER_CODE, which are threadsafe.
    int _userCodeBlocks;
}

@property(strong, nonatomic) NSString *apiHostName;
@property(strong, nonatomic) NSString *socketHost;
@property(assign, nonatomic) int socketPort;
@property(assign, nonatomic) BOOL apiSSL;
@property(assign, nonatomic) int networkTimeoutSeconds;
@property(assign, nonatomic) int networkTimeoutSecondsForDownloads;
@property(assign, nonatomic) int syncNetworkTimeoutSeconds;
@property(assign, nonatomic) BOOL checkForUpdatesInDevelopmentMode;
@property(assign, nonatomic) BOOL isDevelopmentModeEnabled;
@property(assign, nonatomic) BOOL loggingEnabled;
@property(assign, nonatomic) BOOL canDownloadContentMidSessionInProduction;
@property(strong, nonatomic) NSString *apiServlet;
@property(assign, nonatomic) BOOL isTestMode;
@property(assign, nonatomic) BOOL isInPermanentFailureState;
@property(assign, nonatomic) BOOL verboseLoggingInDevelopmentMode;
@property(strong, nonatomic) NSString *client;
@property(strong, nonatomic) NSString *sdkVersion;
@property(assign, nonatomic) BOOL networkActivityIndicatorEnabled;
@property(assign, nonatomic) BOOL isLocationCollectionEnabled;
@property(assign, nonatomic) BOOL isInboxImagePrefetchingEnabled;

+ (LPConstantsState *)sharedState;

@end

#pragma mark - The rest of the Leanplum constants

OBJC_EXPORT NSString *LEANPLUM_PACKAGE_IDENTIFIER;

OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_COUNT_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_ITEM_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_VARIABLES_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_MESSAGES_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_UPDATE_RULES_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_EVENT_RULES_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_TOKEN_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_MESSAGE_TRIGGER_OCCURRENCES_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_MESSAGE_IMPRESSION_OCCURRENCES_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_MESSAGE_MUTED_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_PUSH_TOKEN_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_USER_NOTIFICATION_SETTINGS_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_REGION_STATE_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_ATTRIBUTES_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_PRE_LEANPLUM_INSTALL_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_SDK_VERSION;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_INBOX_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_APP_VERSION_KEY;
OBJC_EXPORT NSString *LEANPLUM_DEFAULTS_UUID_KEY;

OBJC_EXPORT NSString *LEANPLUM_SQLITE_NAME;

OBJC_EXPORT NSString *LP_METHOD_GET_VARS;
OBJC_EXPORT NSString *LP_METHOD_MULTI;
OBJC_EXPORT NSString *LP_METHOD_UPLOAD_FILE;
OBJC_EXPORT NSString *LP_METHOD_LOG;

OBJC_EXPORT NSString *LP_PARAM_ACTION;
OBJC_EXPORT NSString *LP_PARAM_ACTION_DEFINITIONS;
OBJC_EXPORT NSString *LP_PARAM_TIME;
OBJC_EXPORT NSString *LP_PARAM_TYPE;
OBJC_EXPORT NSString *LP_PARAM_APP_ID;
OBJC_EXPORT NSString *LP_PARAM_USER_ID;
OBJC_EXPORT NSString *LP_PARAM_NEW_USER_ID;
OBJC_EXPORT NSString *LP_PARAM_USER_ATTRIBUTES;
OBJC_EXPORT NSString *LP_PARAM_TRAFFIC_SOURCE;
OBJC_EXPORT NSString *LP_PARAM_DEVICE_ID;
OBJC_EXPORT NSString *LP_PARAM_VERSION_NAME;
OBJC_EXPORT NSString *LP_PARAM_VERSION_CODE;
OBJC_EXPORT NSString *LP_PARAM_EVENT;
OBJC_EXPORT NSString *LP_PARAM_STATE;
OBJC_EXPORT NSString *LP_PARAM_VALUE;
OBJC_EXPORT NSString *LP_PARAM_INFO;
OBJC_EXPORT NSString *LP_PARAM_COUNT;
OBJC_EXPORT NSString *LP_PARAM_DATA;
OBJC_EXPORT NSString *LP_PARAM_DEVICE_NAME;
OBJC_EXPORT NSString *LP_PARAM_DEVICE_MODEL;
OBJC_EXPORT NSString *LP_PARAM_DEVICE_SYSTEM_NAME;
OBJC_EXPORT NSString *LP_PARAM_DEVICE_SYSTEM_VERSION;
OBJC_EXPORT NSString *LP_PARAM_DEV_MODE;
OBJC_EXPORT NSString *LP_PARAM_REQUEST_ID;
OBJC_EXPORT NSString *LP_PARAM_VARS;
OBJC_EXPORT NSString *LP_PARAM_KINDS;
OBJC_EXPORT NSString *LP_PARAM_EMAIL;
OBJC_EXPORT NSString *LP_PARAM_SDK_VERSION;
OBJC_EXPORT NSString *LP_PARAM_FILE;
OBJC_EXPORT NSString *LP_PARAM_FILE_ATTRIBUTES;
OBJC_EXPORT NSString *LP_PARAM_FILES_PATTERN;
OBJC_EXPORT NSString *LP_PARAM_CLIENT;
OBJC_EXPORT NSString *LP_PARAM_CLIENT_KEY;
OBJC_EXPORT NSString *LP_PARAM_TOKEN;
OBJC_EXPORT NSString *LP_PARAM_DEVICE_PUSH_TOKEN;
OBJC_EXPORT NSString *LP_PARAM_DEVICE_USER_NOTIFICATION_TYPES;
OBJC_EXPORT NSString *LP_PARAM_DEVICE_USER_NOTIFICATION_CATEGORIES;
OBJC_EXPORT NSString *LP_PARAM_INCLUDE_DEFAULTS;
OBJC_EXPORT NSString *LP_PARAM_INCLUDE_MESSAGE_ID;
OBJC_EXPORT NSString *LP_PARAM_INCLUDE_VARIANT_DEBUG_INFO;
OBJC_EXPORT NSString *LP_PARAM_PARAMS;
OBJC_EXPORT NSString *LP_PARAM_LIMIT_TRACKING;
OBJC_EXPORT NSString *LP_PARAM_MESSAGE;
OBJC_EXPORT NSString *LP_PARAM_NAME;
OBJC_EXPORT NSString *LP_PARAM_MESSAGE_ID;
OBJC_EXPORT NSString *LP_PARAM_BACKGROUND;
OBJC_EXPORT NSString *LP_PARAM_INSTALL_DATE;
OBJC_EXPORT NSString *LP_PARAM_UPDATE_DATE;
OBJC_EXPORT NSString *LP_PARAM_INBOX_MESSAGES;
OBJC_EXPORT NSString *LP_PARAM_INBOX_MESSAGE_ID;
OBJC_EXPORT NSString *LP_PARAM_RICH_PUSH_ENABLED;
OBJC_EXPORT NSString *LP_PARAM_UUID;
OBJC_EXPORT NSString *LP_PARAM_CURRENCY_CODE;

OBJC_EXPORT NSString *LP_KEY_VARS;
OBJC_EXPORT NSString *LP_KEY_MESSAGES;
OBJC_EXPORT NSString *LP_KEY_UPDATE_RULES;
OBJC_EXPORT NSString *LP_KEY_EVENT_RULES;
OBJC_EXPORT NSString *LP_KEY_VARS_FROM_CODE;
OBJC_EXPORT NSString *LP_KEY_USER_INFO;
OBJC_EXPORT NSString *LP_KEY_STACK_TRACE;
OBJC_EXPORT NSString *LP_KEY_REASON;
OBJC_EXPORT NSString *LP_KEY_IS_REGISTERED;
OBJC_EXPORT NSString *LP_KEY_IS_REGISTERED_FROM_OTHER_APP;
OBJC_EXPORT NSString *LP_KEY_LATEST_VERSION;
OBJC_EXPORT NSString *LP_KEY_SIZE;
OBJC_EXPORT NSString *LP_KEY_HASH;
OBJC_EXPORT NSString *LP_KEY_FILENAME;
OBJC_EXPORT NSString *LP_KEY_LOCALE;
OBJC_EXPORT NSString *LP_KEY_COUNTRY;
OBJC_EXPORT NSString *LP_KEY_TIMEZONE;
OBJC_EXPORT NSString *LP_KEY_TIMEZONE_OFFSET_SECONDS;
OBJC_EXPORT NSString *LP_KEY_REGION;
OBJC_EXPORT NSString *LP_KEY_CITY;
OBJC_EXPORT NSString *LP_KEY_LOCATION;
OBJC_EXPORT NSString *LP_KEY_LOCATION_ACCURACY_TYPE;
OBJC_EXPORT NSString *LP_KEY_TOKEN;
OBJC_EXPORT NSString *LP_KEY_PUSH_MESSAGE_ID;
OBJC_EXPORT NSString *LP_KEY_PUSH_MUTE_IN_APP;
OBJC_EXPORT NSString *LP_KEY_PUSH_NO_ACTION;
OBJC_EXPORT NSString *LP_KEY_PUSH_NO_ACTION_MUTE;
OBJC_EXPORT NSString *LP_KEY_PUSH_ACTION;
OBJC_EXPORT NSString *LP_KEY_PUSH_CUSTOM_ACTIONS;
OBJC_EXPORT NSString *LP_KEY_UPLOAD_URL;
OBJC_EXPORT NSString *LP_KEY_VARIANTS;
OBJC_EXPORT NSString *LP_KEY_REGIONS;
OBJC_EXPORT NSString *LP_KEY_INBOX_MESSAGES;
OBJC_EXPORT NSString *LP_KEY_UNREAD_COUNT;
OBJC_EXPORT NSString *LP_KEY_VARIANT_DEBUG_INFO;
OBJC_EXPORT NSString *LP_KEY_ENABLED_COUNTERS;
OBJC_EXPORT NSString *LP_KEY_ENABLED_FEATURE_FLAGS;
OBJC_EXPORT NSString *LP_KEY_FILES;
OBJC_EXPORT NSString *LP_KEY_SYNC_INBOX;
OBJC_EXPORT NSString *LP_KEY_LOGGING_ENABLED;
OBJC_EXPORT NSString *LP_KEY_MESSAGE_DATA;
OBJC_EXPORT NSString *LP_KEY_IS_READ;
OBJC_EXPORT NSString *LP_KEY_DELIVERY_TIMESTAMP;
OBJC_EXPORT NSString *LP_KEY_EXPIRATION_TIMESTAMP;
OBJC_EXPORT NSString *LP_KEY_TITLE;
OBJC_EXPORT NSString *LP_KEY_SUBTITLE;
OBJC_EXPORT NSString *LP_KEY_IMAGE;
OBJC_EXPORT NSString *LP_KEY_DATA;

OBJC_EXPORT NSString *LP_EVENT_EXCEPTION;

OBJC_EXPORT NSString *LP_HELD_BACK_EVENT_NAME;
OBJC_EXPORT NSString *LP_HELD_BACK_MESSAGE_PREFIX;

OBJC_EXPORT NSString *LP_KIND_INT;
OBJC_EXPORT NSString *LP_KIND_FLOAT;
OBJC_EXPORT NSString *LP_KIND_STRING;
OBJC_EXPORT NSString *LP_KIND_BOOLEAN;
OBJC_EXPORT NSString *LP_KIND_FILE;
OBJC_EXPORT NSString *LP_KIND_DICTIONARY;
OBJC_EXPORT NSString *LP_KIND_ARRAY;
OBJC_EXPORT NSString *LP_KIND_ACTION;
OBJC_EXPORT NSString *LP_KIND_COLOR;

OBJC_EXPORT NSString *LP_VALUE_DETECT;
OBJC_EXPORT NSString *LP_VALUE_ACTION_PREFIX;
OBJC_EXPORT NSString *LP_VALUE_RESOURCES_VARIABLE;
OBJC_EXPORT NSString *LP_VALUE_ACTION_ARG;
OBJC_EXPORT NSString *LP_VALUE_CHAIN_MESSAGE_ARG;
OBJC_EXPORT NSString *LP_VALUE_CHAIN_MESSAGE_ACTION_NAME;
OBJC_EXPORT NSString *LP_VALUE_DEFAULT_PUSH_ACTION;
OBJC_EXPORT NSString *LP_VALUE_DEFAULT_PUSH_MESSAGE;
OBJC_EXPORT NSString *LP_VALUE_SDK_LOG;
OBJC_EXPORT NSString *LP_VALUE_SDK_COUNT;
OBJC_EXPORT NSString *LP_VALUE_SDK_ERROR;
OBJC_EXPORT NSString *LP_VALUE_SDK_START_LATENCY;

OBJC_EXPORT NSString *LP_KEYCHAIN_SERVICE_NAME;
OBJC_EXPORT NSString *LP_KEYCHAIN_USERNAME;

OBJC_EXPORT NSString *LP_PATH_DOCUMENTS;
OBJC_EXPORT NSString *LP_PATH_BUNDLE;
OBJC_EXPORT NSString *LP_SWIZZLING_ENABLED;

OBJC_EXPORT NSString *LP_APP_ICON_NAME;
OBJC_EXPORT NSString *LP_APP_ICON_FILE_PREFIX;
OBJC_EXPORT NSString *LP_APP_ICON_PRIMARY_NAME;

OBJC_EXPORT NSString *LP_INVALID_IDFA;

#define LP_USER_CODE_BLOCKS @"leanplum_userCodeBlocks"


long long leanplum_colorToInt(UIColor *value);
UIColor *leanplum_intToColor(long long value);

// Exception handling.

#define LP_TRY @try {
#define LP_END_TRY }\
@catch (NSException *e) {\
leanplumInternalError(e); }

#define LP_BEGIN_USER_CODE leanplumIncrementUserCodeBlock(1);
#define LP_END_USER_CODE leanplumIncrementUserCodeBlock(-1);

void leanplumIncrementUserCodeBlock(int delta);
void leanplumInternalError(NSException *e);
