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

    /// Returns true for devices running iOS 26 Beta 1 to 3 (developer betas). These betas have an Apple bug with
    /// `UIGlassEffect`. See FXIOS-13528 for details. This workaround can probably be removed soon after iOS 26 official
    /// release and user adoption.
    public class var isRunningLiquidGlassEarlyBeta: Bool {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString

        // Note: Info collected from https://betawiki.net/wiki/IOS_26. Beta 4 was the first public build.
        let betaBlockLists: [String] = [
            "23A257a",  // Unconfirmed early release
            "23A5260n", // Developer Beta 1
            "23A5260u", // Developer Beta 1 Update for iPhone 15 and 16 series
            "23A5276f", // Developer Beta 2
            "23A5287g", // Developer Beta 3
        ]

        return betaBlockLists.contains { systemVersion.contains($0) }
    }

    // Reports portrait screen size regardless of the current orientation.
    @MainActor
    public class func screenSizeOrientationIndependent() -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        return CGSize(width: min(screenSize.width, screenSize.height), height: max(screenSize.width, screenSize.height))
    }
}
