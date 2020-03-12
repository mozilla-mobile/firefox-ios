//
//  ViewController.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import UIKit
import XCGLogger

class ViewController: UIViewController {

    @IBOutlet var logLevelLabel: UILabel!
    @IBOutlet var currentLogLevelLabel: UILabel!
    @IBOutlet var logLevelSlider: UISlider!
    @IBOutlet var generateLabel: UILabel!
    @IBOutlet var enableFilterSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        updateView()
    }

    @IBAction func verboseButtonTouchUpInside(_ sender: AnyObject) {
        log.verbose("Verbose button tapped")
        log.verbose {
            // add expensive code required only for logging, then return an optional String
            return "Executed verbose code block" // or nil
        }
    }

    @IBAction func debugButtonTouchUpInside(_ sender: AnyObject) {
        log.debug("Debug button tapped")
        log.debug {
            // add expensive code required only for logging, then return an optional String
            return "Executed debug code block" // or nil
        }
    }

    @IBAction func infoButtonTouchUpInside(_ sender: AnyObject) {
        log.info("Info button tapped")
        log.info {
            // add expensive code required only for logging, then return an optional String
            return "Executed info code block" // or nil
        }
    }

    @IBAction func warningButtonTouchUpInside(_ sender: AnyObject) {
        log.warning("Warning button tapped")
        log.warning {
            // add expensive code required only for logging, then return an optional String
            return "Executed warning code block" // or nil
        }
    }

    @IBAction func errorButtonTouchUpInside(_ sender: AnyObject) {
        log.error("Error button tapped")
        log.error {
            // add expensive code required only for logging, then return an optional String
            return "Executed error code block" // or nil
        }
    }

    @IBAction func severeButtonTouchUpInside(_ sender: AnyObject) {
        log.severe("Severe button tapped")
        log.severe {
            // add expensive code required only for logging, then return an optional String
            return "Executed severe code block" // or nil
        }
    }

    @IBAction func verboseSensitiveButtonTouchUpInside(_ sender: AnyObject) {
        // Can add multiple Dev/Tag objects together using the | operator
        log.verbose("Verbose (Sensitive) button tapped", userInfo: Dev.dave | Tag.sensitive)
    }

    @IBAction func debugSensitiveButtonTouchUpInside(_ sender: AnyObject) {
        log.debug("Debug (Sensitive) button tapped", userInfo: Dev.dave | Tag.sensitive)
    }

    @IBAction func infoSensitiveButtonTouchUpInside(_ sender: AnyObject) {
        // Can create a custom tag name on the fly by passing in the tag name as a string
        log.info("Info (Sensitive) button tapped", userInfo: Dev.dave | Tag.sensitive | Tag("informative"))
    }

    @IBAction func warningSensitiveButtonTouchUpInside(_ sender: AnyObject) {
        // Can add a bunch of Dev/Tag objects
        log.warning("Warning (Sensitive) button tapped", userInfo: Dev.sabby | Dev.dave | Tag.sensitive | Tag.ui)
    }

    @IBAction func errorSensitiveButtonTouchUpInside(_ sender: AnyObject) {
        // Can create multiple custom tags on the fly using the Tag.names() short cut
        log.error("Error (Sensitive) button tapped", userInfo: Dev.dave | Tag.sensitive | Tag.names("button", "bug"))
    }

    @IBAction func severeSensitiveButtonTouchUpInside(_ sender: AnyObject) {
        // Since we actually need a Dictionary<String: Any> for the userInfo parameter, we can't pass in a single Tag
        // object, we need to manually convert it to a dictionary by accessing the .dictionary property. As you see
        // above, this is done automatically for you when using more than one
        log.severe("Severe (Sensitive) button tapped", userInfo: Tag.sensitive.dictionary)
    }

    @IBAction func logLevelSliderValueChanged(_ sender: AnyObject) {
        var logLevel: XCGLogger.Level = .verbose

        if (0 <= logLevelSlider.value && logLevelSlider.value < 1) {
            logLevel = .verbose
        }
        else if (1 <= logLevelSlider.value && logLevelSlider.value < 2) {
            logLevel = .debug
        }
        else if (2 <= logLevelSlider.value && logLevelSlider.value < 3) {
            logLevel = .info
        }
        else if (3 <= logLevelSlider.value && logLevelSlider.value < 4) {
            logLevel = .warning
        }
        else if (4 <= logLevelSlider.value && logLevelSlider.value < 5) {
            logLevel = .error
        }
        else if (5 <= logLevelSlider.value && logLevelSlider.value < 6) {
            logLevel = .severe
        }
        else {
            logLevel = .none
        }

        log.outputLevel = logLevel
        updateView()
    }

    @IBAction func enableFilterSwitchValueChanged(_ sender: AnyObject) {
        if enableFilterSwitch.isOn {
            log.filters = [TagFilter(excludeFrom: [Tag.sensitive])]
        }
        else {
            log.filters = []
        }
    }

    func updateView() {
        logLevelSlider.value = Float(log.outputLevel.rawValue)
        currentLogLevelLabel.text = "\(log.outputLevel)"
    }
}
