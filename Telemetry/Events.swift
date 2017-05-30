/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import SwiftyJSON

public typealias IdentifierString = String
public extension IdentifierString {
    func validate() -> Bool {
        // Regex located here: http://gecko.readthedocs.io/en/latest/toolkit/components/telemetry/telemetry/collection/events.html#limits
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z][a-zA-Z0-9_.]*[a-zA-Z0-9]$", options: [])
        return regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.characters.count)).count > 0
    }
}

// Telemetry Events
// Documentation: http://gecko.readthedocs.io/en/latest/toolkit/components/telemetry/telemetry/collection/events.html#events
public struct Event {
    let timestamp: Timestamp
    let category: IdentifierString
    let method: IdentifierString
    let object: IdentifierString
    let value: String?
    let extra: [String: String]?

    public init(category: IdentifierString,
                method: IdentifierString,
                object: IdentifierString,
                value: String? = nil,
                extra: [String: String]? = nil) {

        self.init(timestamp: .uptimeInMilliseconds(),
                  category: category,
                  method: method,
                  object: object,
                  value: value,
                  extra: extra)
    }

    init(timestamp: Timestamp,
         category: IdentifierString,
         method: IdentifierString,
         object: IdentifierString,
         value: String? = nil,
         extra: [String: String]? = nil) {
        self.timestamp = timestamp
        self.category = category
        self.method = method
        self.object = object
        self.value = value
        self.extra = extra
    }

    public func validate() -> Bool {
        let results = [category, method, object].map { $0.validate() }
        // Fold down the results into false if any of the results is false.
        return results.reduce(true) { $0 ? $1 :$0 }
    }

    public func pickle() -> Data {
        return try! JSONSerialization.data(withJSONObject: toArray(), options: [])
    }

    public static func unpickle(_ data: Data) -> Event {
        let array = try! JSONSerialization.jsonObject(with: data, options: []) as! [Any]

        return Event(
            timestamp: Timestamp(array[0] as! UInt64),
            category: array[1] as! String,
            method: array[2] as! String,
            object: array[3] as! String,
            value: array[4] as? String,
            extra: array[5] as? [String: String]
        )
    }

    public func toArray() -> [Any] {
        return [timestamp, category, method, object, value ?? NSNull(), extra ?? NSNull()]
    }
}

extension Event: CustomDebugStringConvertible {
    public var debugDescription: String {
        return toArray().description
    }
}
