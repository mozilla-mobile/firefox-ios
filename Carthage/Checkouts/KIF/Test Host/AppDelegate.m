//
//  AppDelegate.m
//  Test Suite
//
//  Created by Brian Nickel on 6/25/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Uncomment the following line to run the tests with animations 100x faster
    //UIApplication.sharedApplication.keyWindow.layer.speed = 100;
}

@end
