// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

open class DeviceInfo {
    @MainActor
    public static var deviceCornerRadius: CGFloat? {
        return UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat
    }

    @MainActor
    @available(iOS 26.0, *)
    open class func deviceCornerConfiguration() -> UICornerConfiguration {
        let cornerRadius = deviceCornerRadius ?? 0
        return UICornerConfiguration.corners(radius: UICornerRadius.fixed(cornerRadius))
    }

    open class func isSimulator() -> Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] != nil
    }
}
