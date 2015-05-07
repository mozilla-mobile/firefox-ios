/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public class DeviceInfo {
    public class func appName() -> String {
        let localizedDict = NSBundle.mainBundle().localizedInfoDictionary
        let infoDict = NSBundle.mainBundle().infoDictionary
        let key = "CFBundleDisplayName"

        // E.g., "Fennec Nightly".
        return localizedDict?[key] as? String ??
               infoDict?[key] as? String ??
               "Firefox"
    }

    // I'd land a test for this, but it turns out it's hardly worthwhile -- both the
    // app name and the device name are variable, and the format string itself varies
    // by locale!
    public class func defaultClientName() -> String {
        // E.g., "Sarah's iPhone".
        let device = UIDevice.currentDevice().name

        let f = NSLocalizedString("%@ on %@", tableName: "Shared", comment: "A brief descriptive name for this app on this device, used for Send Tab and Synced Tabs. The first argument is the app name. The second argument is the device name.")

        return String(format: f, appName(), device)
    }

    public class func deviceModel() -> String {
        return UIDevice.currentDevice().model
    }

    public class func isSimulator() -> Bool {
        return UIDevice.currentDevice().model.contains("Simulator")
    }
}