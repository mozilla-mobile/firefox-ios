//
//  AppDelegate.m
//  Calculator
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "AppDelegate.h"
#import "HomeViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    UIViewController *homeController = [[HomeViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:homeController];
    navController.navigationBar.translucent = NO;
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    
#if DEBUG
#import <dlfcn.h>
    // TODO: Document the following or remove.  The purpose is to enable testing from the command line pre-Xcode5.
    NSLog(@"Did finish launching, environment is %@", [[NSProcessInfo processInfo] environment]);
    NSString *bundlePath = [[NSProcessInfo processInfo] environment][@"XCInjectBundle"];
    if (bundlePath) {
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:&isDirectory] && isDirectory) {
            NSString *basename = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
            bundlePath = [bundlePath stringByAppendingPathComponent:basename];
        }
        NSLog(@"Loading %@", bundlePath);
        void *loadedBundle = dlopen([bundlePath fileSystemRepresentation], RTLD_NOW);
        assert(loadedBundle);
    }
#endif
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
