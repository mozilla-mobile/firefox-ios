//
//  ViewController.swift
//  tvOSDemo
//
//  Created by Dave Wood on 2015-09-09.
//  Copyright © 2015 Cerebral Gardens. All rights reserved.
//

import UIKit
import XCGLogger

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func verboseButtonTapped(_ sender: UIButton) {
        log.verbose("Verbose tapped on the TV")
    }

    @IBAction func debugButtonTapped(_ sender: UIButton) {
        log.debug("Debug tapped on the TV")
    }

    @IBAction func infoButtonTapped(_ sender: UIButton) {
        log.info("Info tapped on the TV")
    }

    @IBAction func warningButtonTapped(_ sender: UIButton) {
        log.warning("Warning tapped on the TV")
    }

    @IBAction func errorButtonTapped(_ sender: UIButton) {
        log.error("Error tapped on the TV")
    }

    @IBAction func severeButtonTapped(_ sender: UIButton) {
        log.severe("Severe tapped on the TV")
    }
}
