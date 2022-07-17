// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import XCGLogger

private let log = Logger.browserLogger

public let PrefKeySyncEvents = "sync.telemetry.events"

public typealias IdentifierString = String
public extension IdentifierString {
    func validate() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z][a-zA-Z0-9_.]*[a-zA-Z0-9]$", options: [])
        return regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count)).count > 0
    }
}

public struct Event: Decodable {
    let timestamp: Timestamp
    let category: IdentifierString
    let method: IdentifierString
    let object: IdentifierString

    let value: String?
    let extra: [String: String]?

    public init(
        category: IdentifierString,
        method: IdentifierString,
        object: IdentifierString,
        value: String? = nil,
        extra: [String: String]? = nil
    ) {
        self.init(
            timestamp: .uptimeInMilliseconds(),
            category: category,
            method: method,
            object: object,
            value: value,
            extra: extra
        )
    }

    enum CodingKeys: String, CodingKey {
        case timestamp, category, method, object,
             flowId = "flow_id",
             streamId = "stream_id",
             reason = "reason"
    }

    public init(from decoder: Decoder) throws {
        timestamp = .uptimeInMilliseconds()
        method = "open-uri"
        category = "sync"

        let values = try decoder.container(keyedBy: CodingKeys.self)
        let flowId = try values.decode(String.self, forKey: .flowId)
        let streamId = try values.decode(String.self, forKey: .streamId)
        var extraDictionary = [
            flowId: flowId,
            streamId: streamId
        ]
        if let reason = try? values.decode(String.self, forKey: .reason) {
            extraDictionary[reason] = reason
            object = "command-received"
        } else {
            object = "command-sent"
        }
        extra = extraDictionary
        value = nil
    }

    init(
        timestamp: Timestamp,
        category: IdentifierString,
        method: IdentifierString,
        object: IdentifierString,
        value: String? = nil,
        extra: [String: String]? = nil
    ) {
        self.timestamp = timestamp
        self.category = category
        self.method = method
        self.object = object
        self.value = value
        self.extra = extra
    }

    public static func hasQueuedEvents(inPrefs prefs: Prefs) -> Bool {
        let pickledEvents = prefs.arrayForKey(PrefKeySyncEvents) as? [Data] ?? []
        return !pickledEvents.isEmpty
    }

    public static func takeAll(fromPrefs prefs: Prefs) -> [Event] {
        let pickledEvents = prefs.arrayForKey(PrefKeySyncEvents) as? [Data] ?? []
        let events = pickledEvents.compactMap(Event.unpickle)
        prefs.setObject(nil, forKey: PrefKeySyncEvents)
        return events
    }

    public func validate() -> Bool {
        let results = [category, method, object].map { $0.validate() }
        // Fold down the results into false if any of the results is false.
        return results.reduce(true) { $0 ? $1 :$0 }
    }

    public func pickle() -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: toArray(), options: [])
        } catch let error {
            log.error("Error pickling telemetry event. Error: \(error), Event: \(self)")
            return nil
        }
    }

    public static func unpickle(_ data: Data) -> Event? {
        do {
            let array = try JSONSerialization.jsonObject(with: data, options: []) as! [Any]
            return Event(
                timestamp: Timestamp(array[0] as! UInt64),
                category: array[1] as! String,
                method: array[2] as! String,
                object: array[3] as! String,
                value: array[4] as? String,
                extra: array[5] as? [String: String]
            )
        } catch let error {
            log.error("Error unpickling telemetry event: \(error)")
            return nil
        }
    }

    public func toArray() -> [Any] {
        return [timestamp, category, method, object, value ?? NSNull(), extra ?? NSNull()]
    }

    public func record(intoPrefs prefs: Prefs) {
        var events = prefs.arrayForKey(PrefKeySyncEvents) as? [Data] ?? []

        if let data = self.pickle(), self.validate() {
            events.append(data)
            prefs.setObject(events, forKey: PrefKeySyncEvents)
        } else {
            log.info("Event not recorded due to validation failure or pickling error!")
        }
    }
}

extension Event: CustomDebugStringConvertible {
    public var debugDescription: String {
        return toArray().description
    }
}
