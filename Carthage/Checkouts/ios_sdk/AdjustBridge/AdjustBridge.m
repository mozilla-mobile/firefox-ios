//
//  AdjustBridge.m
//  Adjust
//
//  Created by Pedro Filipe on 27/04/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

// #import "Adjust.h"
#import <AdjustSdk/Adjust.h>
// In case of erroneous import statement try with:
// #import <AdjustSdk/Adjust.h>
// (depends how you import the adjust SDK to your app)

#import "AdjustBridge.h"
#import "AdjustBridgeRegister.h"
#import "WebViewJavascriptBridge.h"
#import "WKWebViewJavascriptBridge.h"

#define KEY_APP_TOKEN                   @"appToken"
#define KEY_ENVIRONMENT                 @"environment"
#define KEY_LOG_LEVEL                   @"logLevel"
#define KEY_SDK_PREFIX                  @"sdkPrefix"
#define KEY_DEFAULT_TRACKER             @"defaultTracker"
#define KEY_SEND_IN_BACKGROUND          @"sendInBackground"
#define KEY_OPEN_DEFERRED_DEEPLINK      @"openDeferredDeeplink"
#define KEY_EVENT_BUFFERING_ENABLED     @"eventBufferingEnabled"
#define KEY_WEB_VIEW_LOGGING_ENABLED    @"webViewLoggingEnabled"
#define KEY_EVENT_TOKEN                 @"eventToken"
#define KEY_REVENUE                     @"revenue"
#define KEY_CURRENCY                    @"currency"
#define KEY_TRANSACTION_ID              @"transactionId"
#define KEY_CALLBACK_PARAMETERS         @"callbackParameters"
#define KEY_PARTNER_PARAMETERS          @"partnerParameters"

@interface AdjustBridge() <AdjustDelegate>

@property BOOL openDeferredDeeplink;

@property WVJBResponseCallback deeplinkCallback;
@property WVJBResponseCallback attributionCallback;
@property WVJBResponseCallback eventSuccessCallback;
@property WVJBResponseCallback eventFailureCallback;
@property WVJBResponseCallback sessionSuccessCallback;
@property WVJBResponseCallback sessionFailureCallback;
@property WVJBResponseCallback deferredDeeplinkCallback;

@property (nonatomic, strong) id<AdjustBridgeRegister> bridgeRegister;

@end

@implementation AdjustBridge

#pragma mark - Object lifecycle

- (id)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.bridgeRegister = nil;

    self.openDeferredDeeplink = YES;

    self.attributionCallback = nil;
    self.eventSuccessCallback = nil;
    self.eventFailureCallback = nil;
    self.sessionSuccessCallback = nil;
    self.sessionFailureCallback = nil;

    return self;
}

#pragma mark - AdjustDelegate methods

- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    if (self.attributionCallback == nil) {
        return;
    }

    self.attributionCallback([attribution dictionary]);
}

- (void)adjustEventTrackingSucceeded:(ADJEventSuccess *)eventSuccessResponseData {
    if (self.eventSuccessCallback == nil) {
        return;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    [dictionary setValue:eventSuccessResponseData.eventToken forKey:@"eventToken"];
    [dictionary setValue:eventSuccessResponseData.timeStamp forKey:@"timestamp"];
    [dictionary setValue:eventSuccessResponseData.adid forKey:@"adid"];
    [dictionary setValue:eventSuccessResponseData.message forKey:@"message"];
    [dictionary setValue:eventSuccessResponseData.jsonResponse forKey:@"jsonResponse"];

    self.eventSuccessCallback(dictionary);
}

- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData {
    if (self.eventFailureCallback == nil) {
        return;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    [dictionary setValue:eventFailureResponseData.eventToken forKey:@"eventToken"];
    [dictionary setValue:eventFailureResponseData.timeStamp forKey:@"timestamp"];
    [dictionary setValue:eventFailureResponseData.adid forKey:@"adid"];
    [dictionary setValue:eventFailureResponseData.message forKey:@"message"];
    [dictionary setValue:eventFailureResponseData.jsonResponse forKey:@"jsonResponse"];
    [dictionary setValue:[NSNumber numberWithBool:eventFailureResponseData.willRetry] forKey:@"willRetry"];

    self.eventFailureCallback(dictionary);
}

- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData {
    if (self.sessionSuccessCallback == nil) {
        return;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    [dictionary setValue:sessionSuccessResponseData.timeStamp forKey:@"timestamp"];
    [dictionary setValue:sessionSuccessResponseData.adid forKey:@"adid"];
    [dictionary setValue:sessionSuccessResponseData.message forKey:@"message"];
    [dictionary setValue:sessionSuccessResponseData.jsonResponse forKey:@"jsonResponse"];

    self.sessionSuccessCallback(dictionary);
}

- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData {
    if (self.sessionFailureCallback == nil) {
        return;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    [dictionary setValue:sessionFailureResponseData.timeStamp forKey:@"timestamp"];
    [dictionary setValue:sessionFailureResponseData.adid forKey:@"adid"];
    [dictionary setValue:sessionFailureResponseData.message forKey:@"message"];
    [dictionary setValue:sessionFailureResponseData.jsonResponse forKey:@"jsonResponse"];
    [dictionary setValue:[NSNumber numberWithBool:sessionFailureResponseData.willRetry] forKey:@"willRetry"];

    self.sessionFailureCallback(dictionary);
}

- (BOOL)adjustDeeplinkResponse:(NSURL *)deeplink {
    if (self.deferredDeeplinkCallback) {
        self.deferredDeeplinkCallback([deeplink absoluteString]);
    }

    return self.openDeferredDeeplink;
}

#pragma mark - Public methods

- (void)loadUIWebViewBridge:(UIWebView *)uiWebView {
    if (self.bridgeRegister != nil) {
        // WebViewBridge already loaded.
        return;
    }

    self.bridgeRegister = [AdjustUIBridgeRegister bridgeRegisterWithUIWebView:uiWebView];
    [self loadWebViewBridge];
}

- (void)loadWKWebViewBridge:(WKWebView *)wkWebView {
    if (self.bridgeRegister != nil) {
        // WebViewBridge already loaded.
        return;
    }

    self.bridgeRegister = [AdjustWKBridgeRegister bridgeRegisterWithWKWebView:wkWebView];
    [self loadWebViewBridge];
}

- (void)loadWebViewBridge {
    // Register for setting attribution callback method.
    [self.bridgeRegister registerHandler:@"adjust_setAttributionCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (responseCallback == nil) {
            return;
        }

        self.attributionCallback = responseCallback;
    }];

    // Register for setting event tracking success callback method.
    [self.bridgeRegister registerHandler:@"adjust_setEventSuccessCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (responseCallback == nil) {
            return;
        }

        self.eventSuccessCallback = responseCallback;
    }];

    // Register for setting event tracking failure method.
    [self.bridgeRegister registerHandler:@"adjust_setEventFailureCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (responseCallback == nil) {
            return;
        }

        self.eventFailureCallback = responseCallback;
    }];

    // Register for setting session tracking success method.
    [self.bridgeRegister registerHandler:@"adjust_setSessionSuccessCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (responseCallback == nil) {
            return;
        }

        self.sessionSuccessCallback = responseCallback;
    }];

    // Register for setting session tracking failure method.
    [self.bridgeRegister registerHandler:@"adjust_setSessionFailureCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (responseCallback == nil) {
            return;
        }

        self.sessionFailureCallback = responseCallback;
    }];

    // Register for setting direct deeplink handler method.
    [self.bridgeRegister registerHandler:@"adjust_setDeferredDeeplinkCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (responseCallback == nil) {
            return;
        }

        self.deferredDeeplinkCallback = responseCallback;
    }];

    // Register for appDidLaunch method.
    [self.bridgeRegister registerHandler:@"adjust_appDidLaunch" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *appToken = [data objectForKey:KEY_APP_TOKEN];
        NSString *environment = [data objectForKey:KEY_ENVIRONMENT];
        NSString *logLevel = [data objectForKey:KEY_LOG_LEVEL];
        NSString *sdkPrefix = [data objectForKey:KEY_SDK_PREFIX];
        NSString *defaultTracker = [data objectForKey:KEY_DEFAULT_TRACKER];
        NSNumber *sendInBackground = [data objectForKey:KEY_SEND_IN_BACKGROUND];
        NSNumber *eventBufferingEnabled = [data objectForKey:KEY_EVENT_BUFFERING_ENABLED];
        NSNumber *webViewLoggingEnabled = [data objectForKey:KEY_WEB_VIEW_LOGGING_ENABLED];
        NSNumber *shouldOpenDeferredDeeplink = [data objectForKey:KEY_OPEN_DEFERRED_DEEPLINK];

        ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken environment:environment];

        if ([adjustConfig isValid]) {
            // Log level
            if ([self isFieldValid:logLevel]) {
                [adjustConfig setLogLevel:[ADJLogger LogLevelFromString:[logLevel lowercaseString]]];
            }

            // Sending in background
            if ([self isFieldValid:sendInBackground]) {
                [adjustConfig setSendInBackground:[sendInBackground boolValue]];
            }

            // Event buffering
            if ([self isFieldValid:eventBufferingEnabled]) {
                [adjustConfig setEventBufferingEnabled:[eventBufferingEnabled boolValue]];
            }

            // Web bridge logging
            if ([self isFieldValid:webViewLoggingEnabled]) {
                if ([eventBufferingEnabled boolValue]) {
                    [WebViewJavascriptBridge enableLogging];
                }
            }

            // Deferred deeplink opening
            if ([self isFieldValid:shouldOpenDeferredDeeplink]) {
                self.openDeferredDeeplink = [shouldOpenDeferredDeeplink boolValue];
            }

            // SDK prefix
            if ([self isFieldValid:sdkPrefix]) {
                [adjustConfig setSdkPrefix:sdkPrefix];
            }

            // Default tracker
            if ([self isFieldValid:defaultTracker]) {
                [adjustConfig setDefaultTracker:defaultTracker];
            }

            // Attribution delegate
            if (self.attributionCallback != nil || self.eventSuccessCallback != nil ||
                self.eventFailureCallback != nil || self.sessionSuccessCallback != nil ||
                self.sessionFailureCallback != nil || self.deferredDeeplinkCallback != nil) {
                [adjustConfig setDelegate:self];
            }

            [Adjust appDidLaunch:adjustConfig];
            [Adjust trackSubsessionStart];
        }
    }];

    // Register for trackEvent method.
    [self.bridgeRegister registerHandler:@"adjust_trackEvent" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *eventToken = [data objectForKey:KEY_EVENT_TOKEN];
        NSString *revenue = [data objectForKey:KEY_REVENUE];
        NSString *currency = [data objectForKey:KEY_CURRENCY];
        NSString *transactionId = [data objectForKey:KEY_TRANSACTION_ID];

        ADJEvent *adjustEvent = [ADJEvent eventWithEventToken:eventToken];

        if ([adjustEvent isValid]) {
            // Revenue and currency
            if ([self isFieldValid:revenue] || [self isFieldValid:currency]) {
                double revenueValue = [revenue doubleValue];

                [adjustEvent setRevenue:revenueValue currency:currency];
            }

            // Callback parameters
            for (int i = 0; i < [[data objectForKey:KEY_CALLBACK_PARAMETERS] count]; i += 2) {
                [adjustEvent addCallbackParameter:[[data objectForKey:KEY_CALLBACK_PARAMETERS] objectAtIndex:i]
                                            value:[[data objectForKey:KEY_CALLBACK_PARAMETERS] objectAtIndex:(i+1)]];
            }

            // Partner parameters
            for (int i = 0; i < [[data objectForKey:KEY_PARTNER_PARAMETERS] count]; i += 2) {
                [adjustEvent addPartnerParameter:[[data objectForKey:KEY_PARTNER_PARAMETERS] objectAtIndex:i]
                                           value:[[data objectForKey:KEY_PARTNER_PARAMETERS] objectAtIndex:(i+1)]];
            }

            // Transaction ID
            if ([self isFieldValid:transactionId]) {
                [adjustEvent setTransactionId:transactionId];
            }

            [Adjust trackEvent:adjustEvent];
        }
    }];

    // Register for setOfflineMode method.
    [self.bridgeRegister registerHandler:@"adjust_setOfflineMode" handler:^(NSNumber *data, WVJBResponseCallback responseCallback) {
        [Adjust setOfflineMode:[data boolValue]];
    }];

    // Register for setEnabled method.
    [self.bridgeRegister registerHandler:@"adjust_setEnabled" handler:^(NSNumber *data, WVJBResponseCallback responseCallback) {
        [Adjust setEnabled:[data boolValue]];
    }];

    // Register for isEnabled method.
    [self.bridgeRegister registerHandler:@"adjust_isEnabled" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (responseCallback == nil) {
            return;
        }

        responseCallback([NSNumber numberWithBool:[Adjust isEnabled]]);
    }];

    // Register for IDFA method.
    [self.bridgeRegister registerHandler:@"adjust_idfa" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (responseCallback == nil) {
            return;
        }

        responseCallback([Adjust idfa]);
    }];

    // Register for appWillOpenUrl method.
    [self.bridgeRegister registerHandler:@"adjust_appWillOpenUrl" handler:^(id data, WVJBResponseCallback responseCallback) {
        [Adjust appWillOpenUrl:[NSURL URLWithString:data]];
    }];

    // Register for setDeviceToken method.
    [self.bridgeRegister registerHandler:@"adjust_setDeviceToken" handler:^(id data, WVJBResponseCallback responseCallback) {
        [Adjust setDeviceToken:[data dataUsingEncoding:NSUTF8StringEncoding]];
    }];
}

- (void)sendDeeplinkToWebView:(NSURL *)deeplink {
    [self.bridgeRegister callHandler:@"adjust_deeplink" data:[deeplink absoluteString]];
}

#pragma mark - Private & helper methods

- (BOOL)isFieldValid:(NSObject *)field {
    if (field == nil) {
        return NO;
    }
    
    if ([field isKindOfClass:[NSNull class]]) {
        return NO;
    }
    
    return YES;
}

@end
