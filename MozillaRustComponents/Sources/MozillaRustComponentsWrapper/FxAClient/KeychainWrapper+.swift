/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension MZKeychainWrapper {
    /// Return the base bundle identifier.
    ///
    /// This function is smart enough to find out if it is being called from an extension or the main application. In
    /// case of the former, it will chop off the extension identifier from the bundle since that is a suffix not part
    /// of the *base* bundle identifier.
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

    static var shared: MZKeychainWrapper?

    static func sharedAppContainerKeychain(keychainAccessGroup: String?) -> MZKeychainWrapper {
        if let s = shared {
            return s
        }
        let wrapper = MZKeychainWrapper(serviceName: baseBundleIdentifier, accessGroup: keychainAccessGroup)
        shared = wrapper
        return wrapper
    }
}
