// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

extension DeviceInfo {
    public class func deviceModel() -> String {
        return UIDeviceDetails.model
    }

    public class func hasConnectivity() -> Bool {
        return connectionType() != .offline
    }

    /// Represents the current network connection type.
    public enum ConnectionType: String {
        case wifi
        case cellular
        case offline
    }

    /// Convenience method to determine the current network connection type.
    public class func connectionType() -> ConnectionType {
        switch Reach().connectionStatus() {
        case .online(.wiFi):
            return .wifi
        case .online(.wwan):
            return .cellular
        default:
            return .offline
        }
    }

    // Reports portrait screen size regardless of the current orientation.
    @MainActor
    public class func screenSizeOrientationIndependent() -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        return CGSize(width: min(screenSize.width, screenSize.height), height: max(screenSize.width, screenSize.height))
    }
}
