//
//  AppDelegate+WebXRViewer.swift
//  Client
//
//  Created by Blair MacIntyre on 6/25/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation

func registerWebXRDefaultsFromSettingsBundle() {
    guard let settingsBundle = Bundle.main.url(forResource: "Settings", withExtension: "bundle") else {
        print("Could not find Settings.bundle")
        return
    }

    guard let settings = NSDictionary(contentsOf: settingsBundle.appendingPathComponent("Root.plist")) else {
        print("Could not find settings dictionary")
        return
    }
    let preferences = settings["PreferenceSpecifiers"] as? [[AnyHashable : Any]]

    var defaultsToRegister = [AnyHashable : Any]()
    for prefSpecification: [AnyHashable : Any] in preferences ?? [] {
        let key = prefSpecification["Key"] as? String
        if key != nil {
            defaultsToRegister[key] = prefSpecification["DefaultValue"]
        }
    }

    if let aRegister = defaultsToRegister as? [String : Any] {
        UserDefaults.standard.register(defaults: aRegister)
    }

    if UserDefaults.standard.integer(forKey: Constant.secondsInBackgroundKey()) == 0 {
        UserDefaults.standard.set(Constant.sessionInBackgroundDefaultTimeInSeconds(), forKey: Constant.secondsInBackgroundKey())
    }

    if UserDefaults.standard.float(forKey: Constant.distantAnchorsDistanceKey()) == 0.0 {
        UserDefaults.standard.set(Constant.distantAnchorsDefaultDistanceInMeters(), forKey: Constant.distantAnchorsDistanceKey())
    }
}

