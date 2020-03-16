/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class TelemetryEvent {
    public static let MaxLengthString = 50
    public static let MaxNumberOfExtras = 10

    public let category: String
    public let method: String
    public let object: String
    public let value: String?
    public let timestamp: UInt64

    private var extras: [String : String]

    public convenience init(category: String, method: String, object: String, value: String? = nil, extras: [String : Any]? = nil) {
        let timestamp = UInt64.safeConvert(Date().timeIntervalSince(Telemetry.appLaunchTimestamp) * 1000)
        self.init(category: category, method: method, object: object, value: value, timestamp: timestamp)

        if let extras = extras {
            for (key, value) in extras {
                self.addExtra(key: key, value: value)
            }
        }
    }

    private init(category: String, method: String, object: String, value: String?, timestamp: UInt64) {
        self.category = TelemetryUtils.truncate(string: category, maxLength: TelemetryEvent.MaxLengthString)
        self.method = TelemetryUtils.truncate(string: method, maxLength: TelemetryEvent.MaxLengthString)
        self.object = TelemetryUtils.truncate(string: object, maxLength: TelemetryEvent.MaxLengthString)

        if let value = value {
            self.value = TelemetryUtils.truncate(string: value, maxLength: TelemetryEvent.MaxLengthString)
        } else {
            self.value = nil
        }

        self.timestamp = timestamp

        self.extras = [:]
    }

    private static func limitNumberOfItems(inDictionary dictionary: [String : String], to numberOfItems: Int) -> [String : String] {
        var result: [String : String] = [:]

        for (index, item) in dictionary.enumerated() {
            if index >= numberOfItems {
                break
            }

            result[item.key] = item.value
        }

        return result
    }

    public func addExtra(key: String, value: Any) {
        if extras.count >= TelemetryEvent.MaxNumberOfExtras {
            print("Exceeded maximum limit of \(TelemetryEvent.MaxNumberOfExtras) TelemetryEvent extras")
            return
        }

        let truncatedKey = TelemetryUtils.truncate(string: key, maxLength: TelemetryEvent.MaxLengthString)
        let truncatedValue = TelemetryUtils.truncate(string: TelemetryUtils.asString(value), maxLength: TelemetryEvent.MaxLengthString)
        extras[truncatedKey] = truncatedValue
    }

    public func toArray() -> [Any?] {
        var array: [Any?] = [timestamp, category, method, object]

        if value != nil {
            array.append(value)
        }

        if !extras.isEmpty {
            if value == nil {
                array.append(nil)
            }
            array.append(extras)
        }

        return array
    }

    public func toJSON() -> Data? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: toArray(), options: [])
            return jsonData
        } catch let error {
            print("Error serializing TelemetryEvent to JSON: \(error)")
            return nil
        }
    }
}
