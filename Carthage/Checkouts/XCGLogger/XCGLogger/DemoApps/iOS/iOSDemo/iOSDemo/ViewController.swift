//
//  ViewController.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import UIKit
import XCGLogger

class ViewController: UIViewController {

    @IBOutlet var logLevelLabel: UILabel!
    @IBOutlet var currentLogLevelLabel: UILabel!
    @IBOutlet var logLevelSlider: UISlider!
    @IBOutlet var generateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        updateView()
    }

    @IBAction func verboseButtonTouchUpInside(sender: AnyObject) {
        log.verbose("Verbose button tapped")
        log.verbose {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed verbose code block" // or nil
        }
    }

    @IBAction func debugButtonTouchUpInside(sender: AnyObject) {
        log.debug("Debug button tapped")
        log.debug {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed debug code block" // or nil
        }
    }

    @IBAction func infoButtonTouchUpInside(sender: AnyObject) {
        log.info("Info button tapped")
        log.info {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed info code block" // or nil
        }
    }

    @IBAction func warningButtonTouchUpInside(sender: AnyObject) {
        log.warning("Warning button tapped")
        log.warning {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed warning code block" // or nil
        }
    }

    @IBAction func errorButtonTouchUpInside(sender: AnyObject) {
        log.error("Error button tapped")
        log.error {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed error code block" // or nil
        }
    }

    @IBAction func severeButtonTouchUpInside(sender: AnyObject) {
        log.severe("Severe button tapped")
        log.severe {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed severe code block" // or nil
        }
    }

    @IBAction func logLevelSliderValueChanged(sender: AnyObject) {
        var logLevel: XCGLogger.LogLevel = .Verbose

        if (0 <= logLevelSlider.value && logLevelSlider.value < 1) {
            logLevel = .Verbose
        }
        else if (1 <= logLevelSlider.value && logLevelSlider.value < 2) {
            logLevel = .Debug
        }
        else if (2 <= logLevelSlider.value && logLevelSlider.value < 3) {
            logLevel = .Info
        }
        else if (3 <= logLevelSlider.value && logLevelSlider.value < 4) {
            logLevel = .Warning
        }
        else if (4 <= logLevelSlider.value && logLevelSlider.value < 5) {
            logLevel = .Error
        }
        else if (5 <= logLevelSlider.value && logLevelSlider.value < 6) {
            logLevel = .Severe
        }
        else {
            logLevel = .None
        }

        log.outputLogLevel = logLevel
        updateView()
    }

    func updateView() {
        logLevelSlider.value = Float(log.outputLogLevel.rawValue)
        currentLogLevelLabel.text = "\(log.outputLogLevel)"
    }
}
