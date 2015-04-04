/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public protocol Prefs {
    func setLong(value: UInt64, forKey defaultName: String)
    func setLong(value: Int64, forKey defaultName: String)
    func setInt(value: Int32, forKey defaultName: String)
    func setString(value: String, forKey defaultName: String)
    func setObject(value: AnyObject?, forKey defaultName: String)
    func stringForKey(defaultName: String) -> String?
    func boolForKey(defaultName: String) -> Bool?
    func intForKey(defaultName: String) -> Int32?
    func longForKey(defaultName: String) -> Int64?
    func unsignedLongForKey(defaultName: String) -> UInt64?
    func stringArrayForKey(defaultName: String) -> [String]?
    func arrayForKey(defaultName: String) -> [AnyObject]?
    func dictionaryForKey(defaultName: String) -> [String : AnyObject]?
    func removeObjectForKey(defaultName: String)
    func clearAll()
}

public class MockProfilePrefs : Prefs {
    var things: NSMutableDictionary = NSMutableDictionary()

    public init() {
    }

    public func setLong(value: UInt64, forKey defaultName: String) {
        setObject(NSNumber(unsignedLongLong: value), forKey: defaultName)
    }

    public func setLong(value: Int64, forKey defaultName: String) {
        setObject(NSNumber(longLong: value), forKey: defaultName)
    }

    public func setInt(value: Int32, forKey defaultName: String) {
        things[defaultName] = NSNumber(int: value)
    }

    public func setString(value: String, forKey defaultName: String) {
        things[defaultName] = value
    }

    public func setObject(value: AnyObject?, forKey defaultName: String) {
        things[defaultName] = value
    }

    public func stringForKey(defaultName: String) -> String? {
        return things[defaultName] as? String
    }

    public func boolForKey(defaultName: String) -> Bool? {
        return things[defaultName] as? Bool
    }

    public func unsignedLongForKey(defaultName: String) -> UInt64? {
        let num = things[defaultName] as? NSNumber
        if let num = num {
            return num.unsignedLongLongValue
        }
        return nil
    }

    public func longForKey(defaultName: String) -> Int64? {
        let num = things[defaultName] as? NSNumber
        if let num = num {
            return num.longLongValue
        }
        return nil
    }

    public func intForKey(defaultName: String) -> Int32? {
        let num = things[defaultName] as? NSNumber
        if let num = num {
            return num.intValue
        }
        return nil
    }

    public func stringArrayForKey(defaultName: String) -> [String]? {
        return self.arrayForKey(defaultName) as [String]?
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
        return things.objectForKey(defaultName) as? [String: AnyObject]
    }

    public func removeObjectForKey(defaultName: String) {
        self.things[defaultName] = nil
    }

    public func clearAll() {
        self.things.removeAllObjects()
    }
}
