//
//  InterfaceController.swift
//  watchOSDemo Extension
//
//  Created by Dave Wood on 2015-09-09.
//  Copyright © 2015 Cerebral Gardens. All rights reserved.
//

import WatchKit
import Foundation
import XCGLogger

let log: XCGLogger = {
    // Setup XCGLogger
    let log = XCGLogger.defaultInstance()
    log.xcodeColorsEnabled = true // Or set the XcodeColors environment variable in your scheme to YES
    log.xcodeColors = [
        .Verbose: .lightGrey,
        .Debug: .darkGrey,
        .Info: .darkGreen,
        .Warning: .orange,
        .Error: XCGLogger.XcodeColor(fg: UIColor.redColor(), bg: UIColor.whiteColor()), // Optionally use a UIColor
        .Severe: XCGLogger.XcodeColor(fg: (255, 255, 255), bg: (255, 0, 0)) // Optionally use RGB values directly
    ]

    #if USE_NSLOG // Set via Build Settings, under Other Swift Flags
        log.removeLogDestination(XCGLogger.Constants.baseConsoleLogDestinationIdentifier)
        log.addLogDestination(XCGNSLogDestination(owner: log, identifier: XCGLogger.Constants.nslogDestinationIdentifier))
        log.logAppDetails()
    #else
        log.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true)
    #endif
    
    return log
}()

class InterfaceController: WKInterfaceController {

    override func awakeWithContext(context: AnyObject?) {
        // Display initial app info
        log

        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func verboseButtonTapped(sender: WKInterfaceButton) {
        log.verbose("Verbose tapped on the Watch")
    }

    @IBAction func debugButtonTapped(sender: WKInterfaceButton) {
        log.debug("Debug tapped on the Watch")
    }

    @IBAction func infoButtonTapped(sender: WKInterfaceButton) {
        log.info("Info tapped on the Watch")
    }

    @IBAction func warningButtonTapped(sender: WKInterfaceButton) {
        log.warning("Warning tapped on the Watch")
    }

    @IBAction func errorButtonTapped(sender: WKInterfaceButton) {
        log.error("Error tapped on the Watch")
    }

    @IBAction func severeButtonTapped(sender: WKInterfaceButton) {
        log.severe("Severe tapped on the Watch")
    }
}
