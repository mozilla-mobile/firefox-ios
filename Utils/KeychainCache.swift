/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger

private let log = Logger.keychainLogger

public protocol JSONLiteralConvertible {
    func asJSON() -> JSON
}

public class KeychainCache<T: JSONLiteralConvertible> {
    public let branch: String
    public let label: String

    public var value: T? {
        didSet {
            checkpoint()
        }
    }

    public init(branch: String, label: String, value: T?) {
        self.branch = branch
        self.label = label
        self.value = value
    }

    public class func fromBranch(branch: String, withLabel label: String?, withDefault defaultValue: T? = nil, factory: JSON -> T?) -> KeychainCache<T> {
        if let l = label {
            if let s = KeychainWrapper.stringForKey("\(branch).\(l)") {
                if let t = factory(JSON.parse(s)) {
                    log.info("Read \(branch) from Keychain with label \(branch).\(l).")
                    return KeychainCache(branch: branch, label: l, value: t)
                } else {
                    log.warning("Found \(branch) in Keychain with label \(branch).\(l), but could not parse it.")
                }
            } else {
                log.warning("Did not find \(branch) in Keychain with label \(branch).\(l).")
            }
        } else {
            log.warning("Did not find \(branch) label in Keychain.")
        }
        // Fall through to missing.
        log.warning("Failed to read \(branch) from Keychain.")
        let label = label ?? Bytes.generateGUID()
        return KeychainCache(branch: branch, label: label, value: defaultValue)
    }

    public func checkpoint() {
        log.info("Storing \(self.branch) in Keychain with label \(self.branch).\(self.label).")
        // TODO: PII logging.
        if let value = value {
            let jsonString = value.asJSON().toString(false)
            KeychainWrapper.setString(jsonString, forKey: "\(branch).\(label)")
        } else {
            KeychainWrapper.removeObjectForKey("\(branch).\(label)")
        }
    }
}
