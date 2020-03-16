//
//  AppDelegate.swift
//  tvOSDemo
//
//  Created by Dave Wood on 2015-09-09.
//  Copyright © 2015 Cerebral Gardens. All rights reserved.
//

import UIKit
import XCGLogger

let appDelegate = UIApplication.shared.delegate as! AppDelegate
let log: XCGLogger = {
    // Setup XCGLogger
    let log = XCGLogger.default

    #if USE_NSLOG // Set via Build Settings, under Other Swift Flags
        log.remove(logDestinationWithIdentifier: XCGLogger.Constants.baseConsoleLogDestinationIdentifier)
        log.add(logDestination: XCGNSLogDestination(identifier: XCGLogger.Constants.nslogDestinationIdentifier))
        log.logAppDetails()
    #else
        let logPath: URL = appDelegate.cacheDirectory.appendingPathComponent("XCGLogger_Log.txt")
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logPath)

        // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
        // This is mostly useful when testing in the simulator, or if you have the app sending you log files remotely
        if let fileDestination: FileDestination = log.destination(withIdentifier: XCGLogger.Constants.fileDestinationIdentifier) as? FileDestination {
            let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
            ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
            ansiColorLogFormatter.colorize(level: .debug, with: .black)
            ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
            ansiColorLogFormatter.colorize(level: .notice, with: .green, options: [.italic])
            ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
            ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
            ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
            ansiColorLogFormatter.colorize(level: .alert, with: .white, on: .red, options: [.bold])
            ansiColorLogFormatter.colorize(level: .emergency, with: .white, on: .red, options: [.bold, .blink])
            fileDestination.formatters = [ansiColorLogFormatter]
        }
    #endif

    return log
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let documentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()

    let cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Display initial app info
        _ = log
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
