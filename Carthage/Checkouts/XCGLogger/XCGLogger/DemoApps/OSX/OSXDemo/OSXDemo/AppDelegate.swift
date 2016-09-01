//
//  AppDelegate.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Cocoa
import XCGLogger

let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
let log: XCGLogger = {
    // Setup XCGLogger
    let log = XCGLogger.defaultInstance()
    let logPath: NSString = ("~/Desktop/XCGLogger_Log.txt" as NSString).stringByExpandingTildeInPath
    log.xcodeColors = [
        .Verbose: .lightGrey,
        .Debug: .darkGrey,
        .Info: .darkGreen,
        .Warning: .orange,
        .Error: XCGLogger.XcodeColor(fg: NSColor.redColor(), bg: NSColor.whiteColor()), // Optionally use an NSColor
        .Severe: XCGLogger.XcodeColor(fg: (255, 255, 255), bg: (255, 0, 0)) // Optionally use RGB values directly
    ]
    log.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logPath)

    return log
}()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties
    @IBOutlet var window: NSWindow!

    @IBOutlet var logLevelTextField: NSTextField!
    @IBOutlet var currentLogLevelTextField: NSTextField!
    @IBOutlet var generateTestLogTextField: NSTextField!
    @IBOutlet var logLevelSlider: NSSlider!

    // MARK: - Life cycle methods
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        updateView()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    // MARK: - Main View
    @IBAction func verboseButtonTouchUpInside(sender: AnyObject) {
        log.verbose("Verbose button tapped")
        log.verbose {
            // add expensive code required only for logging, then return an optional String
            return "Executed verbose code block" // or nil
        }
    }

    @IBAction func debugButtonTouchUpInside(sender: AnyObject) {
        log.debug("Debug button tapped")
        log.debug {
            // add expensive code required only for logging, then return an optional String
            return "Executed debug code block" // or nil
        }
    }

    @IBAction func infoButtonTouchUpInside(sender: AnyObject) {
        log.info("Info button tapped")
        log.info {
            // add expensive code required only for logging, then return an optional String
            return "Executed info code block" // or nil
        }
    }

    @IBAction func warningButtonTouchUpInside(sender: AnyObject) {
        log.warning("Warning button tapped")
        log.warning {
            // add expensive code required only for logging, then return an optional String
            return "Executed warning code block" // or nil
        }
    }

    @IBAction func errorButtonTouchUpInside(sender: AnyObject) {
        log.error("Error button tapped")
        log.error {
            // add expensive code required only for logging, then return an optional String
            return "Executed error code block" // or nil
        }
    }

    @IBAction func severeButtonTouchUpInside(sender: AnyObject) {
        log.severe("Severe button tapped")
        log.severe {
            // add expensive code required only for logging, then return an optional String
            return "Executed severe code block" // or nil
        }
    }

    @IBAction func logLevelSliderValueChanged(sender: AnyObject) {
        var logLevel: XCGLogger.LogLevel = .Verbose

        if (0 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 1) {
            logLevel = .Verbose
        }
        else if (1 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 2) {
            logLevel = .Debug
        }
        else if (2 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 3) {
            logLevel = .Info
        }
        else if (3 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 4) {
            logLevel = .Warning
        }
        else if (4 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 5) {
            logLevel = .Error
        }
        else if (5 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 6) {
            logLevel = .Severe
        }
        else {
            logLevel = .None
        }

        log.outputLogLevel = logLevel
        updateView()
    }

    func updateView() {
        logLevelSlider.floatValue = Float(log.outputLogLevel.rawValue)
        currentLogLevelTextField.stringValue = "\(log.outputLogLevel)"
    }
}

func noop() {
    // Global no operation function, useful for doing nothing in a switch option, and examples
}
