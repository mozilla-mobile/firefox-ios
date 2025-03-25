// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class DependencyHelper {
    func bootstrapDependencies() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            // Fatal error here so we can gather info as this would cause a crash down the line anyway
            fatalError("Failed to register any dependencies")
        }

        let themeManager: ThemeManager = appDelegate.themeManager
        AppContainer.shared.register(service: themeManager)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()
    }

    func reset() {
        AppContainer.shared.reset()
    }

    static var baseBundleIdentifier: String {
        let bundle = Bundle.main
        let packageType = bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as? String
        let baseBundleIdentifier = bundle.bundleIdentifier!
        if packageType == "XPC!" {
            let components = baseBundleIdentifier.components(separatedBy: ".")
            return components[0 ..< components.count - 1].joined(separator: ".")
        }
        return baseBundleIdentifier
    }
}
