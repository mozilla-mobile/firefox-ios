// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

import class MozillaAppServices.MZKeychainWrapper

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
        guard let label = label else {
            logger.log("Did not find \(branch) label in Keychain.",
                       level: .warning,
                       category: .storage)
            return failToReadFromBranch(branch, withLogger: logger, withLabel: label, withDefaultValue: defaultValue)
        }

        let key = "\(branch).\(label)"
        MZKeychainWrapper.sharedClientAppContainerKeychain.ensureStringItemAccessibility(.afterFirstUnlock, forKey: key)

        guard let keychainString = MZKeychainWrapper.sharedClientAppContainerKeychain.string(forKey: key) else {
            logger.log("Did not find \(branch) in Keychain with label \(branch).\(label).",
                       level: .warning,
                       category: .storage)
            return failToReadFromBranch(branch, withLogger: logger, withLabel: label, withDefaultValue: defaultValue)
        }

        guard let data = keychainString.data(using: .utf8),
              let dictionaryObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else {
            logger.log("Found \(branch) in Keychain with label \(branch).\(label), but could not parse it.",
                       level: .warning,
                       category: .storage)
            return failToReadFromBranch(branch, withLogger: logger, withLabel: label, withDefaultValue: defaultValue)
        }

        guard let value = factory(dictionaryObject) else {
            logger.log(
                "Found \(branch) in Keychain with label \(branch).\(label), data parsed, but could not convert it.",
                level: .warning,
                category: .storage
            )
            return failToReadFromBranch(branch, withLogger: logger, withLabel: label, withDefaultValue: defaultValue)
        }

        logger.log("Read \(branch) from Keychain with label \(branch).\(label).",
                   level: .debug,
                   category: .storage)
        return KeychainCache(branch: branch, label: label, value: value)
    }

    private class func failToReadFromBranch(
        _ branch: String,
        withLogger logger: Logger,
        withLabel label: String?,
        withDefaultValue defaultValue: T? = nil
    ) -> KeychainCache {
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
            MZKeychainWrapper.sharedClientAppContainerKeychain.set(
                jsonString,
                forKey: "\(branch).\(label)",
                withAccessibility: .afterFirstUnlock
            )
        } else {
            MZKeychainWrapper.sharedClientAppContainerKeychain.removeObject(forKey: "\(branch).\(label)")
        }
    }
}
