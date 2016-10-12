//
//  ViewController.swift
//  AdjustExample-Swift
//
//  Created by Uglješa Erceg on 06/04/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

import UIKit

class ViewControllerSwift: UIViewController {
    @IBOutlet weak var btnTrackEventSimple: UIButton?
    @IBOutlet weak var btnTrackEventRevenue: UIButton?
    @IBOutlet weak var btnTrackEventCallback: UIButton?
    @IBOutlet weak var btnTrackEventPartner: UIButton?
    @IBOutlet weak var btnEnableOfflineMode: UIButton?
    @IBOutlet weak var btnDisableOfflineMode: UIButton?
    @IBOutlet weak var btnEnableSDK: UIButton?
    @IBOutlet weak var btnDisableSDK: UIButton?
    @IBOutlet weak var btnIsSDKEnabled: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func btnTrackEventSimpleTapped(_sender: UIButton) {
        let event = ADJEvent(eventToken: "{YourEventToken}");

        Adjust.trackEvent(event);
    }

    @IBAction func btnTrackEventRevenueTapped(_sender: UIButton) {
        let event = ADJEvent(eventToken: "{YourEventToken}");
        event?.setRevenue(0.99, currency: "EUR");

        Adjust.trackEvent(event);
    }

    @IBAction func btnTrackEventCallbackTapped(_sender: UIButton) {
        let event = ADJEvent(eventToken: "{YourEventToken}");
        event?.addCallbackParameter("foo", value: "bar");
        event?.addCallbackParameter("key", value: "value");

        Adjust.trackEvent(event);
    }

    @IBAction func btnTrackEventPartnerTapped(_sender: UIButton) {
        let event = ADJEvent(eventToken: "{YourEventToken}");
        event?.addPartnerParameter("foo", value: "bar");
        event?.addPartnerParameter("key", value: "value");

        Adjust.trackEvent(event);
    }

    @IBAction func btnEnableOfflineModeTapped(_sender: UIButton) {
        Adjust.setOfflineMode(true);
    }

    @IBAction func btnDisableOfflineModeTapped(_sender: UIButton) {
        Adjust.setOfflineMode(false);
    }

    @IBAction func btnEnableSDKTapped(_sender: UIButton) {
        Adjust.setEnabled(true);
    }

    @IBAction func btnDisableSDKTapped(_sender: UIButton) {
        Adjust.setEnabled(false);
    }

    @IBAction func btnIsSDKEnabledTapped(_sender: UIButton) {
        let isSDKEnabled = Adjust.isEnabled();

        if (isSDKEnabled) {
            // let alert = UIAlertController(title: "Is SDK Enabled?",
            //                               message: "SDK is ENABLED!",
            //                               preferredStyle: UIAlertControllerStyle.Alert)
            //
            // alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            // self.present(alert, animated: true, completion: nil)

            NSLog("SDK is enabled!");
        } else {
            // let alert = UIAlertController(title: "Is SDK Enabled?",
            //                               message: "SDK is DISABLED!",
            //                               preferredStyle: UIAlertControllerStyle.Alert)
            //
            // alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            // self.present(alert, animated: true, completion: nil)

            NSLog("SDK is disabled");
        }
    }
}
