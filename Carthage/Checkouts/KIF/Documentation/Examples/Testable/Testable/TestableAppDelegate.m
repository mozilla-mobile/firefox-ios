//
//  TestableAppDelegate.m
//  Testable
//
//  Created by Eric Firestone on 6/2/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "TestableAppDelegate.h"

#if RUN_KIF_TESTS
#import "EXTestController.h"
#endif

@implementation TestableAppDelegate


@synthesize window=_window;

@synthesize navigationController=_navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // Add the navigation controller's view to the window and display.
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
#if RUN_KIF_TESTS
    [[EXTestController sharedInstance] startTestingWithCompletionBlock:^{
        // Exit after the tests complete. When running on CI, this lets you check the return value for pass/fail.
        exit([[EXTestController sharedInstance] failureCount]);
    }];
#endif
    
    return YES;
}


@end
