/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public protocol ProfilePrefs {
    func setObject(value: AnyObject?, forKey defaultName: String)
    func stringArrayForKey(defaultName: String) -> [AnyObject]?
    func arrayForKey(defaultName: String) -> [AnyObject]?
    func dictionaryForKey(defaultName: String) -> [NSObject : AnyObject]?
    func removeObjectForKey(defaultName: String)
}

public class MockProfilePrefs : ProfilePrefs {
    var things: NSMutableDictionary = NSMutableDictionary()

    public func setObject(value: AnyObject?, forKey defaultName: String) {
        things[defaultName] = value
    }

    public func stringArrayForKey(defaultName: String) -> [AnyObject]? {
        return self.arrayForKey(defaultName)
    }

    public func arrayForKey(defaultName: String) -> [AnyObject]? {
        let r: AnyObject? = things.objectForKey(defaultName)
        if (r == nil) {
            return nil
        }
        if let arr = r as? [AnyObject] {
            return arr
        }
        return nil
    }

    public func dictionaryForKey(defaultName: String) -> [NSObject : AnyObject]? {
        return things.objectForKey(defaultName) as? [NSObject: AnyObject]
    }

    public func removeObjectForKey(defaultName: String) {
        self.things[defaultName] = nil
    }
}

public class NSUserDefaultsProfilePrefs : ProfilePrefs {
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

    public func setObject(value: AnyObject?, forKey defaultName: String) {
        userDefaults.setObject(value, forKey: qualifyKey(defaultName))
    }

    public func stringArrayForKey(defaultName: String) -> [AnyObject]? {
        return userDefaults.stringArrayForKey(qualifyKey(defaultName))
    }

    public func arrayForKey(defaultName: String) -> [AnyObject]? {
        return userDefaults.arrayForKey(qualifyKey(defaultName))
    }

    public func dictionaryForKey(defaultName: String) -> [NSObject : AnyObject]? {
        return userDefaults.dictionaryForKey(qualifyKey(defaultName))
    }

    public func removeObjectForKey(defaultName: String) {
        userDefaults.removeObjectForKey(qualifyKey(defaultName));
    }
}
