//
//  AppDelegate.swift
//  AdjustExample-Swift
//
//  Created by Uglješa Erceg on 06/04/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AdjustDelegate {
    var window: UIWindow?

    func application(_application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let appToken = "{YourAppToken}"
        let environment = ADJEnvironmentSandbox

        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)

        // change the log level
        adjustConfig?.logLevel = ADJLogLevelVerbose

        // Enable event buffering.
        // adjustConfig.eventBufferingEnabled = true

        // Set default tracker.
        // adjustConfig.defaultTracker = "{TrackerToken}"

        // Send in the background.
        // adjustConfig.sendInBackground = true

        // set an attribution delegate
        adjustConfig?.delegate = self

        // Initialise the SDK.
        Adjust.appDidLaunch(adjustConfig)

        // Put the SDK in offline mode.
        // Adjust.setOfflineMode(true);
        
        // Disable the SDK
        // Adjust.setEnabled(false);

        return true
    }

    func adjustAttributionChanged(_attribution: ADJAttribution) {
        NSLog("adjust attribution %@", _attribution)
    }

    func adjustEventTrackingSucceeded(_eventSuccessResponseData: ADJEventSuccess) {
        NSLog("adjust event success %@", _eventSuccessResponseData)
    }

    func adjustEventTrackingFailed(_eventFailureResponseData: ADJEventFailure) {
        NSLog("adjust event failure %@", _eventFailureResponseData)
    }

    func adjustSessionTrackingSucceeded(_sessionSuccessResponseData: ADJSessionSuccess) {
        NSLog("adjust session success %@", _sessionSuccessResponseData)
    }

    func adjustSessionTrackingFailed(_sessionFailureResponseData: ADJSessionFailure) {
        NSLog("adjust session failure %@", _sessionFailureResponseData)
    }

    @objc func adjustDeeplinkResponse(_deeplink: NSURL!) -> Bool {
        return true
    }

    func applicationWillResignActive(_application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
