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
    let log = XCGLogger.default
    #if USE_NSLOG // Set via Build Settings, under Other Swift Flags
        log.remove(destinationWithIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier)
        log.add(destination: AppleSystemLogDestination(identifier: XCGLogger.Constants.systemLogDestinationIdentifier))
        log.logAppDetails()
    #else
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
    #endif
    
    return log
}()

class InterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        // Display initial app info
        _ = log

        super.awake(withContext: context)
        
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

    @IBAction func verboseButtonTapped(_ sender: WKInterfaceButton) {
        log.verbose("Verbose tapped on the Watch")
    }

    @IBAction func debugButtonTapped(_ sender: WKInterfaceButton) {
        log.debug("Debug tapped on the Watch")
    }

    @IBAction func infoButtonTapped(_ sender: WKInterfaceButton) {
        log.info("Info tapped on the Watch")
    }

    @IBAction func warningButtonTapped(_ sender: WKInterfaceButton) {
        log.warning("Warning tapped on the Watch")
    }

    @IBAction func errorButtonTapped(_ sender: WKInterfaceButton) {
        log.error("Error tapped on the Watch")
    }

    @IBAction func severeButtonTapped(_ sender: WKInterfaceButton) {
        log.severe("Severe tapped on the Watch")
    }
}
