/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Onyx Ping type
public protocol OnyxPing {

    /// Converts ping object into a JSON representation that we can send to the Onyx server.
    ///
    /// - returns: JSON representation of the ping.
    func asPayload() throws -> NSData
}

/// A structure defining a session ping for an Onyx server.
public struct SessionPing {
    public let url: String?
    public let loadReason: String?
    public let unloadReason: String?
    public let loadLatency: Int?
    public let locale: String
    public let page: String?
    public let action: String?

    var sessionDuration: Int = 0

    // TODO: Unused desktop fields. Figure out what we want to do for mobile
    let tabID = ""
    let clientID = ""
    let addonVersion = ""
    let metadataSource = ""
    let totalHistorySize = 0
    let totalBookmarks = 0

    public init(url: NSURL?, loadReason: String?, unloadReason: String?, loadLatency: Int?, locale: NSLocale,
                page: String?, action: String?) {
        self.url = url?.absoluteString
        self.loadReason = loadReason
        self.unloadReason = unloadReason
        self.loadLatency = loadLatency
        self.locale = locale.localeIdentifier
        self.page = page
        self.action = action
    }
}

// MARK: - SessionPing:OnyxPing
extension SessionPing: OnyxPing {
    public func asPayload() throws -> NSData {
        var toDict = [String: AnyObject]()
        toDict.optAdd(self.url, key: "url")
        toDict.optAdd(self.loadReason, key: "load_reason")
        toDict.optAdd(self.unloadReason, key: "unload_reason")
        toDict.optAdd(self.loadLatency, key: "load_latency")
        toDict.optAdd(self.locale, key: "locale")
        toDict.optAdd(self.page, key: "page")
        toDict.optAdd(self.action, key: "action")
        toDict.optAdd(self.sessionDuration, key: "session_duration")
        return try NSJSONSerialization.dataWithJSONObject(toDict, options: .PrettyPrinted)
    }
}

/// A structure defining an event ping for an Onyx server.
public struct EventPing {
    public let event: String
    public let page: String
    public let source: String
    public let actionPosition: Int
    public let locale: String
    public let action: String
    public let provider: String?

    // TODO: Unused desktop fields. Figure out what we want to do for mobile
    let tabID = ""
    let clientID = ""
    let addonVersion = ""
    let metadataSource = ""

    public init(event: String, page: String, source: String, actionPosition: Int, locale: NSLocale,
                action: String, provider: String? = nil) {
        self.event = event
        self.page = page
        self.source = source
        self.actionPosition = actionPosition
        self.locale = locale.localeIdentifier
        self.action = action
        self.provider = provider
    }
}

// MARK: - EventPing:OnyxPing
extension EventPing: OnyxPing {
    public func asPayload() throws -> NSData {
        var toDict: [String: AnyObject] = [
            "event": self.event,
            "page": self.page,
            "source": self.source,
            "action_position": self.actionPosition,
            "locale": self.locale,
            "action": self.action,
            "tab_id": self.tabID,
            "client_id": self.clientID,
            "addon_version": self.addonVersion,
            "metadata_source": self.metadataSource
        ]
        toDict.optAdd(self.provider, key: "provider")
        return try NSJSONSerialization.dataWithJSONObject(toDict, options: .PrettyPrinted)
    }
}

// MARK: - Helper Extension on Dictionaries
private extension Dictionary {
    mutating func optAdd(value: Value?, key: Key) {
        if let value = value {
            self[key] = value
        }
    }
}
