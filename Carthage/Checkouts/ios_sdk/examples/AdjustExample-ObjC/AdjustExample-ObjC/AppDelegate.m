//
//  AppDelegate.m
//  AdjustExample-ObjC
//
//  Created by Pedro Filipe (@nonelse) on 12th October 2015.
//  Copyright © 2015-2019 Adjust GmbH. All rights reserved.
//

#import "Constants.h"
#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Configure Adjust SDK.
    NSString *appToken = kAppToken;
    NSString *environment = ADJEnvironmentSandbox;
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken environment:environment];

    // Change the log level.
    [adjustConfig setLogLevel:ADJLogLevelVerbose];

    // Enable event buffering.
    // [adjustConfig setEventBufferingEnabled:YES];

    // Set default tracker.
    // [adjustConfig setDefaultTracker:@"{TrackerToken}"];

    // Send in the background.
    // [adjustConfig setSendInBackground:YES];
    
    // Set an attribution delegate.
    [adjustConfig setDelegate:self];
    
    // Delay the first session of the SDK.
    // [adjustConfig setDelayStart:7];
    
    // Add session callback parameters.
    [Adjust addSessionCallbackParameter:@"sp_foo" value:@"sp_bar"];
    [Adjust addSessionCallbackParameter:@"sp_key" value:@"sp_value"];
    
    // Add session partner parameters.
    [Adjust addSessionPartnerParameter:@"sp_foo" value:@"sp_bar"];
    [Adjust addSessionPartnerParameter:@"sp_key" value:@"sp_value"];
    
    // Remove session callback parameter.
    [Adjust removeSessionCallbackParameter:@"sp_key"];
    
    // Remove session partner parameter.
    [Adjust removeSessionPartnerParameter:@"sp_foo"];
    
    // Remove all session callback parameters.
    // [Adjust resetSessionCallbackParameters];
    
    // Remove all session partner parameters.
    // [Adjust resetSessionPartnerParameters];

    // Initialise the SDK.
    [Adjust appDidLaunch:adjustConfig];

    // Put the SDK in offline mode.
    // [Adjust setOfflineMode:YES];

    // Disable the SDK.
    // [Adjust setEnabled:NO];
    
    // Interrupt delayed start set with setDelayStart: method.
    // [Adjust sendFirstPackages];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"Scheme based deep link opened an app: %@", url);
    // Pass deep link to Adjust in order to potentially reattribute user.
    [Adjust appWillOpenUrl:url];
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSLog(@"Universal link opened an app: %@", [userActivity webpageURL]);
        // Pass deep link to Adjust in order to potentially reattribute user.
        [Adjust appWillOpenUrl:[userActivity webpageURL]];
    }
    return YES;
}

- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    NSLog(@"Attribution callback called!");
    NSLog(@"Attribution: %@", attribution);
}

- (void)adjustEventTrackingSucceeded:(ADJEventSuccess *)eventSuccessResponseData {
    NSLog(@"Event success callback called!");
    NSLog(@"Event success data: %@", eventSuccessResponseData);
}

- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData {
    NSLog(@"Event failure callback called!");
    NSLog(@"Event failure data: %@", eventFailureResponseData);
}

- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData {
    NSLog(@"Session success callback called!");
    NSLog(@"Session success data: %@", sessionSuccessResponseData);
}

- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData {
    NSLog(@"Session failure callback called!");
    NSLog(@"Session failure data: %@", sessionFailureResponseData);
}

- (BOOL)adjustDeeplinkResponse:(NSURL *)deeplink {
    NSLog(@"Deferred deep link callback called!");
    NSLog(@"Deferred deep link URL: %@", [deeplink absoluteString]);
    
    // Allow Adjust SDK to open received deferred deep link.
    // If you don't want it to open it, return NO; instead.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
