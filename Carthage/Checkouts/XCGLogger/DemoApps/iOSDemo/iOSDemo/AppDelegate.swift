//
//  AppDelegate.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import UIKit
import XCGLogger

let appDelegate = UIApplication.shared.delegate as! AppDelegate
let _xcode_workaround_log: XCGLogger = { // see bug report: rdar://49294916 or https://openradar.appspot.com/radar?id=4952305786945536

#if USE_NSLOG // Set via Build Settings, under Other Swift Flags
    // Setup XCGLogger
    let log = XCGLogger.default
    log.remove(destinationWithIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier)
    log.add(destination: AppleSystemLogDestination(identifier: XCGLogger.Constants.systemLogDestinationIdentifier))
    log.logAppDetails()

#elseif USE_OLD_SETUP_STYLE
    // This old style where we us a single setup method isn't recommended for production apps.
    // It's mostly useful for when you need a quick and dirty log, in a sample project, or unit test etc
    let log = XCGLogger.default
    let logPath: URL = appDelegate.cacheDirectory.appendingPathComponent("XCGLogger_Log.txt")
    log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logPath)

    // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
    // This is mostly useful when testing in the simulator, or if you have the app sending you log files remotely
    // This is also an example of how you can pull a log destination out of the logger later to alter it's setup
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

#else
    // Setup XCGLogger (Advanced/Recommended Usage)
    // Create a logger object with no destinations
    let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.appleSystemLogDestination")

    // Optionally set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true

    // Add the destination to the logger
    log.add(destination: systemDestination)

    // Create a file log destination
    let logPath: URL = appDelegate.cacheDirectory.appendingPathComponent("XCGLogger_Log.txt")
    let autoRotatingFileDestination = AutoRotatingFileDestination(writeToFile: logPath, identifier: "advancedLogger.fileDestination", shouldAppend: true,
                                                                  attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], // Set file attributes on the log file
                                                                  maxFileSize: 1024 * 5, // 5k, not a good size for production (default is 1 megabyte)
                                                                  maxTimeInterval: 60, // 1 minute, also not good for production (default is 10 minutes)
                                                                  targetMaxLogFiles: 20) // Default is 10, max is 255

    // Optionally set some configuration options
    autoRotatingFileDestination.outputLevel = .debug
    autoRotatingFileDestination.showLogIdentifier = false
    autoRotatingFileDestination.showFunctionName = true
    autoRotatingFileDestination.showThreadName = true
    autoRotatingFileDestination.showLevel = true
    autoRotatingFileDestination.showFileName = true
    autoRotatingFileDestination.showLineNumber = true
    autoRotatingFileDestination.showDate = true

    // Process this destination in the background
    autoRotatingFileDestination.logQueue = XCGLogger.logQueue

    // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
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
    autoRotatingFileDestination.formatters = [ansiColorLogFormatter]

    // Add the destination to the logger
    log.add(destination: autoRotatingFileDestination)

    // Add basic app info, version info etc, to the start of the logs
    log.logAppDetails()

#endif

    // You can also change the labels for each log level, most useful for alternate languages, French, German etc, but Emoji's are more fun
    //    log.levelDescriptions[.verbose] = "🗯"
    //    log.levelDescriptions[.debug] = "🔹"
    //    log.levelDescriptions[.info] = "ℹ️"
    //    log.levelDescriptions[.notice] = "✳️"
    //    log.levelDescriptions[.warning] = "⚠️"
    //    log.levelDescriptions[.error] = "‼️"
    //    log.levelDescriptions[.severe] = "💣"
    //    log.levelDescriptions[.alert] = "🛑"
    //    log.levelDescriptions[.emergency] = "🚨"

    // Alternatively, you can use emoji to highlight log levels (you probably just want to use one of these methods at a time).
    let emojiLogFormatter = PrePostFixLogFormatter()
    emojiLogFormatter.apply(prefix: "🗯🗯🗯 ", postfix: " 🗯🗯🗯", to: .verbose)
    emojiLogFormatter.apply(prefix: "🔹🔹🔹 ", postfix: " 🔹🔹🔹", to: .debug)
    emojiLogFormatter.apply(prefix: "ℹ️ℹ️ℹ️ ", postfix: " ℹ️ℹ️ℹ️", to: .info)
    emojiLogFormatter.apply(prefix: "✳️✳️✳️ ", postfix: " ✳️✳️✳️", to: .notice)
    emojiLogFormatter.apply(prefix: "⚠️⚠️⚠️ ", postfix: " ⚠️⚠️⚠️", to: .warning)
    emojiLogFormatter.apply(prefix: "‼️‼️‼️ ", postfix: " ‼️‼️‼️", to: .error)
    emojiLogFormatter.apply(prefix: "💣💣💣 ", postfix: " 💣💣💣", to: .severe)
    emojiLogFormatter.apply(prefix: "🛑🛑🛑 ", postfix: " 🛑🛑🛑", to: .alert)
    emojiLogFormatter.apply(prefix: "🚨🚨🚨 ", postfix: " 🚨🚨🚨", to: .emergency)
    log.formatters = [emojiLogFormatter]

    return log
}()
let log: XCGLogger = _xcode_workaround_log

// Create custom tags for your logs
extension Tag {
    static let sensitive = Tag("sensitive")
    static let ui = Tag("ui")
    static let data = Tag("data")
}

// Create custom developers for your logs
extension Dev {
    static let dave = Dev("dave")
    static let sabby = Dev("sabby")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties
    var window: UIWindow?

    let documentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1]
    }()

    let cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[urls.endIndex - 1] 
    }()

    // MARK: - Life cycle methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Override point for customization after application launch.
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
