// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SwiftyJSON
import MozillaAppServices

public protocol JSONLiteralConvertible {
    func asJSON() -> [String: Any]
}

open class KeychainCache<T: JSONLiteralConvertible> {
    public let branch: String
    public let label: String

    open var value: T? {
        didSet {
            checkpoint()
        }
    }

    public init(branch: String, label: String, value: T?) {
        self.branch = branch
        self.label = label
        self.value = value
    }

    open class func fromBranch(_ branch: String,
                               withLabel label: String?,
                               withDefault defaultValue: T? = nil,
                               factory: ([String: Any]) -> T?,
                               logger: Logger = DefaultLogger.shared) -> KeychainCache<T> {
        if let l = label {
            let key = "\(branch).\(l)"
            MZKeychainWrapper.sharedClientAppContainerKeychain.ensureStringItemAccessibility(.afterFirstUnlock, forKey: key)
            if let s = MZKeychainWrapper.sharedClientAppContainerKeychain.string(forKey: key) {
                if let dictionaryObject = JSON(parseJSON: s).dictionaryObject, let t = factory(dictionaryObject) {
                    logger.log("Read \(branch) from Keychain with label \(branch).\(l).",
                               level: .debug,
                               category: .storage)
                    return KeychainCache(branch: branch, label: l, value: t)
                } else {
                    logger.log("Found \(branch) in Keychain with label \(branch).\(l), but could not parse it.",
                               level: .warning,
                               category: .storage)
                }
            } else {
                logger.log("Did not find \(branch) in Keychain with label \(branch).\(l).",
                           level: .warning,
                           category: .storage)
            }
        } else {
            logger.log("Did not find \(branch) label in Keychain.",
                       level: .warning,
                       category: .storage)
        }
        // Fall through to missing.
        logger.log("Failed to read \(branch) from Keychain.",
                   level: .warning,
                   category: .storage)
        let label = label ?? Bytes.generateGUID()
        return KeychainCache(branch: branch, label: label, value: defaultValue)
    }

    open func checkpoint() {
        if let value = value,
           let jsonString = value.asJSON().asString {
            MZKeychainWrapper.sharedClientAppContainerKeychain.set(jsonString, forKey: "\(branch).\(label)", withAccessibility: .afterFirstUnlock)
        } else {
            MZKeychainWrapper.sharedClientAppContainerKeychain.removeObject(forKey: "\(branch).\(label)")
        }
    }
}
