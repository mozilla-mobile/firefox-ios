//
//  AppDelegate.m
//  AdjustExample-iOS
//
//  Created by Pedro Filipe on 12/10/15.
//  Copyright © 2015 adjust. All rights reserved.
//

#import "Constants.h"
#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    // Configure adjust SDK.
    NSString *yourAppToken = kAppToken;
    NSString *environment = ADJEnvironmentSandbox;
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:environment];

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

    // delay the first session of the SDK
    //[adjustConfig setDelayStart:7];

    // set an attribution delegate

    // Initialise the SDK.
    [Adjust appDidLaunch:adjustConfig];

    // Put the SDK in offline mode.
    // [Adjust setOfflineMode:YES];

    // Disable the SDK.
    // [Adjust setEnabled:NO];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"application openURL %@", url);

    [Adjust appWillOpenUrl:url];

    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSLog(@"application continueUserActivity %@", [userActivity webpageURL]);
        [Adjust appWillOpenUrl:[userActivity webpageURL]];
    }

    return YES;
}

- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    NSLog(@"adjust attribution %@", attribution);
}

- (void)adjustEventTrackingSucceeded:(ADJEventSuccess *)eventSuccessResponseData {
    NSLog(@"adjust event success %@", eventSuccessResponseData);
}

- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData {
    NSLog(@"adjust event failure %@", eventFailureResponseData);
}

- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData {
    NSLog(@"adjust session success %@", sessionSuccessResponseData);
}

- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData {
    NSLog(@"adjust session failure %@", sessionFailureResponseData);
}

// Evaluate deeplink to be launched.
- (BOOL)adjustDeeplinkResponse:(NSURL *)deeplink {
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
