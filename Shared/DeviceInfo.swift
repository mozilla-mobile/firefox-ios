/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

open class DeviceInfo {
    // List of device names that don't support advanced visual settings
    static let lowGraphicsQualityModels = ["iPad", "iPad1,1", "iPhone1,1", "iPhone1,2", "iPhone2,1", "iPhone3,1", "iPhone3,2", "iPhone3,3", "iPod1,1", "iPod2,1", "iPod2,2", "iPod3,1", "iPod4,1", "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4", "iPad3,1", "iPad3,2", "iPad3,3"]

    open static var specificModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machine = systemInfo.machine
        let mirror = Mirror(reflecting: machine)
        var identifier = ""

        // Parses the string for the model name via NSUTF8StringEncoding, refer to 
        // http://stackoverflow.com/questions/26028918/ios-how-to-determine-iphone-model-in-swift
        for child in mirror.children.enumerated() {
            if let value = child.1.value as? Int8, value != 0 {
                identifier.append(String(UnicodeScalar(UInt8(value))))
            }
        }
        return identifier
    }

    open class func appName() -> String {
        let localizedDict = Bundle.main.localizedInfoDictionary
        let infoDict = Bundle.main.infoDictionary
        let key = "CFBundleDisplayName"

        // E.g., "Fennec Nightly".
        return localizedDict?[key] as? String ??
               infoDict?[key] as? String ??
               "Firefox"
    }

    // I'd land a test for this, but it turns out it's hardly worthwhile -- both the
    // app name and the device name are variable, and the format string itself varies
    // by locale!
    open class func defaultClientName() -> String {
        // E.g., "Sarah's iPhone".
        let device = UIDevice.current.name

        let f = NSLocalizedString("%@ on %@", tableName: "Shared", comment: "A brief descriptive name for this app on this device, used for Send Tab and Synced Tabs. The first argument is the app name. The second argument is the device name.")

        return String(format: f, appName(), device)
    }

    open class func clientIdentifier(_ prefs: Prefs) -> String {
        if let id = prefs.stringForKey("clientIdentifier") {
            return id
        }
        let id = UUID().uuidString
        prefs.setString(id, forKey: "clientIdentifier")
        return id
    }

    open class func deviceModel() -> String {
        return UIDevice.current.model
    }

    open class func isSimulator() -> Bool {
        return UIDevice.current.model.contains("Simulator")
    }

    open class func isBlurSupported() -> Bool {
        // We've tried multiple ways to make this change visible on simulators, but we
        // haven't found a solution that worked:
        // 1. http://stackoverflow.com/questions/21603475/how-can-i-detect-if-the-iphone-my-app-is-on-is-going-to-use-a-simple-transparen
        // 2. https://gist.github.com/conradev/8655650
        // Thus, testing has to take place on actual devices.
        return !lowGraphicsQualityModels.contains(specificModelName)
    }

    open class func hasConnectivity() -> Bool {
        let status = Reach().connectionStatus()
        switch status {
        case .online(.wwan):
            return true
        case .online(.wiFi):
            return true
        default:
            return false
        }
    }
}
