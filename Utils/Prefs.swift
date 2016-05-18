/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct PrefsKeys {
    public static let KeyLastRemoteTabSyncTime = "lastRemoteTabSyncTime"
    public static let KeyLastSyncFinishTime = "lastSyncFinishTime"
    public static let KeyTopSitesCacheIsValid = "topSitesCacheIsValid"
    public static let KeyTopSitesCacheSize = "topSitesCacheSize"
    public static let KeyDefaultHomePageURL = "KeyDefaultHomePageURL"
    public static let KeyHomePageButtonIsInMenu = "HomePageButtonIsInMenuPrefKey"
}

public struct PrefsDefaults {
    public static let ChineseHomePageURL = "http://mobile.firefoxchina.cn/"
}

public protocol Prefs {
    func getBranchPrefix() -> String
    func branch(branch: String) -> Prefs
    func setTimestamp(value: Timestamp, forKey defaultName: String)
    func setLong(value: UInt64, forKey defaultName: String)
    func setLong(value: Int64, forKey defaultName: String)
    func setInt(value: Int32, forKey defaultName: String)
    func setString(value: String, forKey defaultName: String)
    func setBool(value: Bool, forKey defaultName: String)
    func setObject(value: AnyObject?, forKey defaultName: String)
    func stringForKey(defaultName: String) -> String?
    func boolForKey(defaultName: String) -> Bool?
    func intForKey(defaultName: String) -> Int32?
    func timestampForKey(defaultName: String) -> Timestamp?
    func longForKey(defaultName: String) -> Int64?
    func unsignedLongForKey(defaultName: String) -> UInt64?
    func stringArrayForKey(defaultName: String) -> [String]?
    func arrayForKey(defaultName: String) -> [AnyObject]?
    func dictionaryForKey(defaultName: String) -> [String : AnyObject]?
    func removeObjectForKey(defaultName: String)
    func clearAll()
}

public class MockProfilePrefs : Prefs {
    let prefix: String

    public func getBranchPrefix() -> String {
        return self.prefix
    }

    // Public for testing.
    public var things: NSMutableDictionary = NSMutableDictionary()

    public init(things: NSMutableDictionary, prefix: String) {
        self.things = things
        self.prefix = prefix
    }

    public init() {
        self.prefix = ""
    }

    public func branch(branch: String) -> Prefs {
        return MockProfilePrefs(things: self.things, prefix: self.prefix + branch + ".")
    }

    private func name(name: String) -> String {
        return self.prefix + name
    }

    public func setTimestamp(value: Timestamp, forKey defaultName: String) {
        self.setLong(value, forKey: defaultName)
    }

    public func setLong(value: UInt64, forKey defaultName: String) {
        setObject(NSNumber(unsignedLongLong: value), forKey: defaultName)
    }

    public func setLong(value: Int64, forKey defaultName: String) {
        setObject(NSNumber(longLong: value), forKey: defaultName)
    }

    public func setInt(value: Int32, forKey defaultName: String) {
        things[name(defaultName)] = NSNumber(int: value)
    }

    public func setString(value: String, forKey defaultName: String) {
        things[name(defaultName)] = value
    }

    public func setBool(value: Bool, forKey defaultName: String) {
        things[name(defaultName)] = value
    }

    public func setObject(value: AnyObject?, forKey defaultName: String) {
        things[name(defaultName)] = value
    }

    public func stringForKey(defaultName: String) -> String? {
        return things[name(defaultName)] as? String
    }

    public func boolForKey(defaultName: String) -> Bool? {
        return things[name(defaultName)] as? Bool
    }

    public func timestampForKey(defaultName: String) -> Timestamp? {
        return unsignedLongForKey(defaultName)
    }

    public func unsignedLongForKey(defaultName: String) -> UInt64? {
        let num = things[name(defaultName)] as? NSNumber
        if let num = num {
            return num.unsignedLongLongValue
        }
        return nil
    }

    public func longForKey(defaultName: String) -> Int64? {
        let num = things[name(defaultName)] as? NSNumber
        if let num = num {
            return num.longLongValue
        }
        return nil
    }

    public func intForKey(defaultName: String) -> Int32? {
        let num = things[name(defaultName)] as? NSNumber
        if let num = num {
            return num.intValue
        }
        return nil
    }

    public func stringArrayForKey(defaultName: String) -> [String]? {
        if let arr = self.arrayForKey(defaultName) {
            if let arr = arr as? [String] {
                return arr
            }
        }
        return nil
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

    public func dictionaryForKey(defaultName: String) -> [String : AnyObject]? {
        return things.objectForKey(name(defaultName)) as? [String: AnyObject]
    }

    public func removeObjectForKey(defaultName: String) {
        self.things.removeObjectForKey(name(defaultName))
    }

    public func clearAll() {
        self.things.removeAllObjects()
    }
}
