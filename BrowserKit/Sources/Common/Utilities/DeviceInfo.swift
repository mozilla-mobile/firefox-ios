// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

open class DeviceInfo {
    // Should not be used on iOS 26+
    @MainActor
    public static var deviceCornerRadius: CGFloat? {
        return UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat
    }

    @MainActor
    @available(iOS 26.0, *)
    open class func deviceCornerConfiguration(minimumRadius: CGFloat) -> UICornerConfiguration {
        return UICornerConfiguration.corners(radius: .containerConcentric(minimum: minimumRadius))
    }

    @MainActor
    @available(iOS 26.0, *)
    open class func deviceCornerConfigurtion(minimumRadius: CGFloat, view: UIView) {
        view.cornerConfiguration = UICornerConfiguration.corners(radius: .containerConcentric(minimum: minimumRadius))
    }

    open class func isSimulator() -> Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] != nil
    }
}
