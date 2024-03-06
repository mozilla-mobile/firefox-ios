/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    // Checks if device is an iPhone 5s, iPhone SE, or iPod Touch 6th gen
    func isSmallDevice() -> Bool {
        return UIDevice.current.modelName == "iPhone6,1" || UIDevice.current.modelName == "iPhone6,2" || UIDevice.current.modelName == "iPod7,1" || UIDevice.current.modelName == "iPhone8,4"
    }
}
