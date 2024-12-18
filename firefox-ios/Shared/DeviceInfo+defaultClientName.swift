// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared
import Common

public extension DeviceInfo {
    /// Return the client name, which can be either "Fennec on Stefan's iPod" or simply "Stefan's iPod"
    /// if the application display name cannot be obtained.
    static func defaultClientName() -> String {
        if ProcessInfo.processInfo.arguments.contains(LaunchArguments.DeviceName) {
            return String(format: .DeviceInfoClientNameDescription, AppInfo.displayName, "iOS")
        }

        return String(format: .DeviceInfoClientNameDescription, AppInfo.displayName, UIDevice.current.name)
    }
}
