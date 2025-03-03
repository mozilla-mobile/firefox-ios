// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

import class MozillaAppServices.MZKeychainWrapper
import enum MozillaAppServices.MZKeychainItemAccessibility

public extension MZKeychainWrapper {
    static var sharedClientAppContainerKeychain: MZKeychainWrapper {
        let baseBundleIdentifier = AppInfo.baseBundleIdentifier
        guard let accessGroupPrefix = Bundle.main.object(forInfoDictionaryKey: "MozDevelopmentTeam") as? String else {
            return MZKeychainWrapper(serviceName: baseBundleIdentifier)
        }
        let accessGroupIdentifier = AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix)
        return MZKeychainWrapper(serviceName: baseBundleIdentifier, accessGroup: accessGroupIdentifier)
    }
}
