/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class NSUserDefaultsProfilePrefs: Prefs {
    private let profile: Profile
    private let prefix: String
    private let userDefaults: NSUserDefaults

    init(profile: Profile) {
        self.profile = profile
        self.prefix = profile.localName() + "."
        self.userDefaults = NSUserDefaults(suiteName: ExtensionUtils.sharedContainerIdentifier())!
    }

    // Preferences are qualified by the profile's local name.
    // Connecting a profile to a Firefox Account, or changing to another, won't alter this.
    private func qualifyKey(key: String) -> String {
        return self.prefix + key
    }

    public func setInt(value: Int32, forKey defaultName: String) {
        // Why aren't you using userDefaults.setInteger?
        // Because userDefaults.getInteger returns a non-optional; it's impossible
        // to tell whether there's a value set, and you thus can't distinguish
        // between "not present" and zero.
        // Yeah, NSUserDefaults is meant to be used for storing "defaults", not data.
        setObject(NSNumber(int: value), forKey: defaultName)
    }

    public func setLong(value: UInt64, forKey defaultName: String) {
        setObject(NSNumber(unsignedLongLong: value), forKey: defaultName)
    }

    public func setLong(value: Int64, forKey defaultName: String) {
        setObject(NSNumber(longLong: value), forKey: defaultName)
    }

    public func setString(value: String, forKey defaultName: String) {
        setObject(value, forKey: defaultName)
    }

    public func setObject(value: AnyObject?, forKey defaultName: String) {
        userDefaults.setObject(value, forKey: qualifyKey(defaultName))
    }

    public func stringForKey(defaultName: String) -> String? {
        // stringForKey converts numbers to strings, which is almost always a bug.
        return userDefaults.objectForKey(qualifyKey(defaultName)) as? String
    }

    public func boolForKey(defaultName: String) -> Bool? {
        // boolForKey just returns false if the key doesn't exist. We need to
        // distinguish between false and non-existent keys, so use objectForKey
        // and cast the result instead.
        return userDefaults.objectForKey(qualifyKey(defaultName)) as? Bool
    }

    private func nsNumberForKey(defaultName: String) -> NSNumber? {
        return userDefaults.objectForKey(qualifyKey(defaultName)) as? NSNumber
    }

    public func unsignedLongForKey(defaultName: String) -> UInt64? {
        return nsNumberForKey(defaultName)?.unsignedLongLongValue
    }

    public func longForKey(defaultName: String) -> Int64? {
        return nsNumberForKey(defaultName)?.longLongValue
    }

    public func intForKey(defaultName: String) -> Int32? {
        return nsNumberForKey(defaultName)?.intValue
    }

    public func stringArrayForKey(defaultName: String) -> [String]? {
        return userDefaults.stringArrayForKey(qualifyKey(defaultName)) as [String]?
    }

    public func arrayForKey(defaultName: String) -> [AnyObject]? {
        return userDefaults.arrayForKey(qualifyKey(defaultName))
    }

    public func dictionaryForKey(defaultName: String) -> [String : AnyObject]? {
        return userDefaults.dictionaryForKey(qualifyKey(defaultName)) as? [String:AnyObject]
    }

    public func removeObjectForKey(defaultName: String) {
        userDefaults.removeObjectForKey(qualifyKey(defaultName))
    }

    public func clearAll() {
        // TODO: userDefaults.removePersistentDomainForName() has no effect for app group suites.
        // iOS Bug? Iterate and remove each manually for now.
        for key in userDefaults.dictionaryRepresentation().keys {
            userDefaults.removeObjectForKey(key as NSString)
        }
    }
}
