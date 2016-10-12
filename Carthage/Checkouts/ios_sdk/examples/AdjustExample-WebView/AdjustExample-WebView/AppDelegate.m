//
//  AppDelegate.m
//  AdjustExample-WebView
//
//  Created by Uglješa Erceg on 31/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "UIWebViewController.h"
#import "WKWebViewController.h"

@interface AppDelegate ()

@property UIWebViewController *uiWebViewExampleController;
@property WKWebViewController *wkWebViewExampleController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 1. Create the UIWebView example
    self.uiWebViewExampleController = [[UIWebViewController alloc] init];
    self.uiWebViewExampleController.tabBarItem.title = @"UIWebView";

    // 2. Create the tab footer and add the UIWebView example
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController addChildViewController:self.uiWebViewExampleController];

    // 3. Create the WKWebView example for devices >= iOS 8
    if ([WKWebView class]) {
        self.wkWebViewExampleController = [[WKWebViewController alloc] init];
        self.wkWebViewExampleController.tabBarItem.title = @"WKWebView";
        [tabBarController addChildViewController:self.wkWebViewExampleController];
    }

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"application openURL %@", url);

    [self.uiWebViewExampleController.adjustBridge sendDeeplinkToWebView:url];
    [self.wkWebViewExampleController.adjustBridge sendDeeplinkToWebView:url];

    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSLog(@"application continueUserActivity %@", [userActivity webpageURL]);

        [self.uiWebViewExampleController.adjustBridge sendDeeplinkToWebView:[userActivity webpageURL]];
        [self.wkWebViewExampleController.adjustBridge sendDeeplinkToWebView:[userActivity webpageURL]];
    }

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
