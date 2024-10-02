// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

open class NSUserDefaultsPrefs: Prefs {
    fileprivate let prefixWithDot: String
    fileprivate let userDefaults: UserDefaults

    open func getBranchPrefix() -> String {
        return self.prefixWithDot
    }

    public init(prefix: String, userDefaults: UserDefaults) {
        self.prefixWithDot = prefix + (prefix.hasSuffix(".") ? "" : ".")
        self.userDefaults = userDefaults
    }

    public init(prefix: String) {
        self.prefixWithDot = prefix + (prefix.hasSuffix(".") ? "" : ".")
        self.userDefaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!
    }

    open func branch(_ branch: String) -> Prefs {
        let prefix = self.prefixWithDot + branch + "."
        return NSUserDefaultsPrefs(prefix: prefix, userDefaults: self.userDefaults)
    }

    // Preferences are qualified by the profile's local name.
    // Connecting a profile to a Firefox Account, or changing to another, won't alter this.
    fileprivate func qualifyKey(_ key: String) -> String {
        return self.prefixWithDot + key
    }

    open func setInt(_ value: Int32, forKey defaultName: String) {
        // Why aren't you using userDefaults.setInteger?
        // Because userDefaults.getInteger returns a non-optional; it's impossible
        // to tell whether there's a value set, and you thus can't distinguish
        // between "not present" and zero.
        // Yeah, NSUserDefaults is meant to be used for storing "defaults", not data.
        setObject(NSNumber(value: value), forKey: defaultName)
    }

    open func setTimestamp(_ value: Timestamp, forKey defaultName: String) {
        setLong(value, forKey: defaultName)
    }

    open func setLong(_ value: UInt64, forKey defaultName: String) {
        setObject(NSNumber(value: value), forKey: defaultName)
    }

    open func setLong(_ value: Int64, forKey defaultName: String) {
        setObject(NSNumber(value: value), forKey: defaultName)
    }

    open func setString(_ value: String, forKey defaultName: String) {
        setObject(value as AnyObject?, forKey: defaultName)
    }

    open func setObject(_ value: Any?, forKey defaultName: String) {
        userDefaults.set(value, forKey: qualifyKey(defaultName))
    }

    open func stringForKey(_ defaultName: String) -> String? {
        // stringForKey converts numbers to strings, which is almost always a bug.
        return userDefaults.object(forKey: qualifyKey(defaultName)) as? String
    }

    open func setBool(_ value: Bool, forKey defaultName: String) {
        setObject(NSNumber(value: value as Bool), forKey: defaultName)
    }

    open func boolForKey(_ defaultName: String) -> Bool? {
        // boolForKey just returns false if the key doesn't exist. We need to
        // distinguish between false and non-existent keys, so use objectForKey
        // and cast the result instead.
        let number = userDefaults.object(forKey: qualifyKey(defaultName)) as? NSNumber
        return number?.boolValue
    }

    fileprivate func nsNumberForKey(_ defaultName: String) -> NSNumber? {
        return userDefaults.object(forKey: qualifyKey(defaultName)) as? NSNumber
    }

    open func unsignedLongForKey(_ defaultName: String) -> UInt64? {
        return nsNumberForKey(defaultName)?.uint64Value
    }

    open func timestampForKey(_ defaultName: String) -> Timestamp? {
        return unsignedLongForKey(defaultName)
    }

    open func longForKey(_ defaultName: String) -> Int64? {
        return nsNumberForKey(defaultName)?.int64Value
    }

    open func objectForKey<T: Any>(_ defaultName: String) -> T? {
        return userDefaults.object(forKey: qualifyKey(defaultName)) as? T
    }

    open func intForKey(_ defaultName: String) -> Int32? {
        return nsNumberForKey(defaultName)?.int32Value
    }

    open func stringArrayForKey(_ defaultName: String) -> [String]? {
        let objects = userDefaults.stringArray(forKey: qualifyKey(defaultName))
        if let strings = objects {
            return strings
        }
        return nil
    }

    open func arrayForKey(_ defaultName: String) -> [Any]? {
        return userDefaults.array(forKey: qualifyKey(defaultName)) as [Any]?
    }

    open func dictionaryForKey(_ defaultName: String) -> [String: Any]? {
        return userDefaults.dictionary(forKey: qualifyKey(defaultName)) as [String: Any]?
    }

    open func removeObjectForKey(_ defaultName: String) {
        userDefaults.removeObject(forKey: qualifyKey(defaultName))
    }

    open func clearAll() {
        // TODO: userDefaults.removePersistentDomainForName() has no effect for app group suites.
        // iOS Bug? Iterate and remove each manually for now.
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(prefixWithDot) {
            userDefaults.removeObject(forKey: key)
        }
    }
}
