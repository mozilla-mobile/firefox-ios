/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

typealias BeforeSerializePingHandler = ([String : Any?]) -> [String : Any?]

class Telemetry {

    static let `default`: Telemetry = Telemetry()
    static let notificationReportError: Notification.Name = Notification.Name(rawValue: "notificationReportError")
    let configuration: TelemetryConfiguration = TelemetryConfiguration()
    func beforeSerializePing(pingType: String, handler: @escaping BeforeSerializePingHandler) {}
    func add<T>(pingBuilderType: T.Type) where T : TelemetryPingBuilder {}

    func recordEvent(_ event: TelemetryEvent, pingType: String? = nil) {}
    func recordEvent(category: String, method: String, object: String, pingType: String? = nil) {}
    func recordEvent(category: String, method: String, object: String, value: String?, pingType: String? = nil) {}
    func recordEvent(category: String, method: String, object: String, value: String?, extras: [String : Any]?, pingType: String? = nil) {}
    func recordSearch(location: SearchesMeasurement.SearchLocation, searchEngine: String) {}
}

class TelemetryConfiguration {
    var appName: String?
    var appVersion: String?
    var updateChannel: String?
    var dataDirectory: FileManager.SearchPathDirectory?
    var isCollectionEnabled: Bool?
    var isUploadEnabled: Bool?
    var userDefaultsSuiteName: String?

    func measureUserDefaultsSetting(forKey key: String, withDefaultValue defaultValue: Any?) {}
}

class TelemetryPingBuilder {}

class CorePingBuilder: TelemetryPingBuilder  {
    class var PingType: String { return "" }
}

class MobileEventPingBuilder: TelemetryPingBuilder  {
    class var PingType: String { return "" }
}

class TelemetryEvent {
    init(category: String, method: String, object: String, value: String? = nil, extras: [String : Any]? = nil) {}
    func toArray() -> [Any?] { return [] }
}

class SearchesMeasurement {

    public enum SearchLocation : String {

        case actionBar

        case listItem

        case suggestion

        case quickSearch
    }

    func search(location: SearchesMeasurement.SearchLocation, searchEngine: String) {}
}
