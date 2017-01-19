/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum ASEventField: String {
    case click = "CLICK"
    case share = "SHARE"
    case delete = "DELETE"
    case block = "BLOCK"
}

enum ASLoadReasonField: String {
    case newTab = "new_tab"
    case refocus = "refocus"
    case retore = "restore"
    case navigation = "navigation"
}

enum ASPageField: String {
    case newTab = "NEW_TAB"
    case timelineAll = "TIMELINE_ALL"
}

enum ASSourceField: String {
    case topSites = "TOP_SITES"
    case highlights = "HIGHLIGHTS"
    case activityFeed = "ACTIVITY_FEED"
}

struct ASInfo {
    let actionPosition: Int
    let source: ASSourceField
}

/// A simple struct that exposes some builder functions strong typing some of the ping fields.
struct ASOnyxPing {
    /// Builds an Onyx ping with strong types for Activity Stream values for events.
    ///
    /// - parameter event:          [CLICK | DELETE | BLOCK | SHARE]
    /// - parameter page:           [NEW_TAB | TIMELINE_ALL]
    /// - parameter source:         [TOP_SITES | HIGHLIGHTS | ACTIVITY_FEED]
    /// - parameter actionPosition: The zero-based index of the component tapped. For example, if the second 
    ///                             item in the highlights row was tapped, this value would be 1.
    /// - parameter provider:       (optional) Indicates share provider if applicable
    ///
    /// - returns: Onyx event ping for Activity Stream events
    static func buildEventPing(event: ASEventField, page: ASPageField, source: ASSourceField, actionPosition: Int, provider: String? = nil) -> EventPing {
        return EventPing(event: event.rawValue, page: page.rawValue, source: source.rawValue,
                         actionPosition: actionPosition, locale: NSLocale.currentLocale(),
                         action: "activity_stream_mobile", provider: provider)
    }

    /// Builds an Onyx ping with strong types for Activity Stream values for session pings.
    ///
    /// - parameter url:             Resource URL for the AS panel
    /// - parameter loadReason:      [newtab | focus]
    /// - parameter unloadReason:    [navigation | unfocus | refresh]
    /// - parameter loadLatency:
    /// - parameter page:            [NEW_TAB | TIMELINE_ALL]
    ///
    /// - returns: Onyx session ping for Activity Stream
    static func buildSessionPing(url: NSURL?, loadReason: ASLoadReasonField?,
                                         unloadReason: ASLoadReasonField?, loadLatency: Int?,
                                         page: ASPageField?) -> SessionPing {
        return SessionPing(url: url, loadReason: loadReason?.rawValue, unloadReason: unloadReason?.rawValue,
                           loadLatency: loadLatency, locale: NSLocale.currentLocale(), page: page?.rawValue,
                           action: "activity_stream_mobile")
    }
}

// MARK: Ping Helpers
extension ASOnyxPing {
    static func reportTapEvent(asEvent: ASInfo) {
        let eventPing = ASOnyxPing.buildEventPing(.click, page: .newTab, source: asEvent.source, actionPosition: asEvent.actionPosition)
        OnyxTelemetry.sharedClient.sendEventPing(eventPing, toEndpoint: .activityStream)
    }

    static func reportShareEvent(asEvent: ASInfo, shareProvider: String?) {
        let eventPing = ASOnyxPing.buildEventPing(.share, page: .newTab, source: asEvent.source, actionPosition: asEvent.actionPosition, provider: shareProvider)
        OnyxTelemetry.sharedClient.sendEventPing(eventPing, toEndpoint: .activityStream)
    }

    static func reportDeleteItemEvent(asEvent: ASInfo) {
        let eventPing = ASOnyxPing.buildEventPing(.delete, page: .newTab, source: asEvent.source, actionPosition: asEvent.actionPosition)
        OnyxTelemetry.sharedClient.sendEventPing(eventPing, toEndpoint: .activityStream)
    }
}
