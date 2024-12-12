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

public extension MZKeychainWrapper {
    func ensureClientStringItemAccessibility(_ accessibility: MZKeychainItemAccessibility,
                                             forKey key: String,
                                             logger: Logger = DefaultLogger.shared) {
        if self.hasValue(forKey: key) {
            if self.accessibilityOfKey(key) != .afterFirstUnlock {
                logger.log("updating item \(key) with \(accessibility)",
                           level: .debug,
                           category: .storage)

                guard let value = self.string(forKey: key) else {
                    logger.log("failed to get item \(key)",
                               level: .warning,
                               category: .storage)
                    return
                }

                if !self.removeObject(forKey: key) {
                    logger.log("failed to remove item \(key)",
                               level: .warning,
                               category: .storage)
                }

                if !self.set(value, forKey: key, withAccessibility: accessibility) {
                    logger.log("failed to update item \(key)",
                               level: .warning,
                               category: .storage)
                }
            }
        }
    }

    func ensureDictonaryItemAccessibility(_ accessibility: MZKeychainItemAccessibility,
                                          forKey key: String,
                                          logger: Logger = DefaultLogger.shared) {
        if self.hasValue(forKey: key) {
            if self.accessibilityOfKey(key) != .afterFirstUnlock {
                logger.log("updating item \(key) with \(accessibility)",
                           level: .debug,
                           category: .storage)

                guard let value = self.object(forKey: key, ofClass: NSDictionary.self) else {
                    logger.log("failed to get item \(key)",
                               level: .warning,
                               category: .storage)
                    return
                }

                if !self.removeObject(forKey: key) {
                    logger.log("failed to remove item \(key)",
                               level: .warning,
                               category: .storage)
                }

                if !self.set(value, forKey: key, withAccessibility: accessibility) {
                    logger.log("failed to update item \(key)",
                               level: .warning,
                               category: .storage)
                }
            }
        }
    }
}
