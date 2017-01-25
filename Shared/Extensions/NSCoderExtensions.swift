/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * There are some oddnesses around the different ways that NSKeyedArchiver decodes objects based on whether or not they were
 * originally encoded using Swift 2.x or Swift 3.
 * If the object was encoded on Swift 2.x, then you need to use decodeObject to unwrap it. But that will return a nil if the object was encoded on Swift 3
 * For swift 3 encoded objects to you need to use decode<Type>
 * These helper functions provide a unified way of achieving that
 **/
extension NSCoder {
    /**
    * Decode as Int regardless of which Swift version was used to encode it
    **/
    open func decodeAsInt(forKey key: String) -> Int {
        return self.decodeObject(forKey: key) as? Int ?? self.decodeInteger(forKey: key)
    }
    /**
     * Decode as UInt64 regardless of which Swift version was used to encode it
     **/
    open func decodeAsUInt64(forKey key: String) -> UInt64 {
        return (self.decodeObject(forKey: key)  as? NSNumber)?.uint64Value ?? UInt64(self.decodeInt64(forKey: key))
    }

    /**
     * Decode as Bool regardless of which Swift version was used to encode it
     **/
    open func decodeAsBool(forKey key: String) -> Bool {
        return self.decodeObject(forKey: key) as? Bool ?? self.decodeBool(forKey: key)
    }

    /**
     * Decode as Double regardless of which Swift version was used to encode it
     **/
    open func decodeAsDouble(forKey key: String) -> Double {
        return (self.decodeObject(forKey: key) as? NSNumber)?.doubleValue ?? self.decodeDouble(forKey: key)
    }
}
