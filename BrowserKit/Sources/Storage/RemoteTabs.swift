// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

import struct MozillaAppServices.RemoteTabRecord

public struct ClientAndTabs: Equatable, CustomStringConvertible {
    public let client: RemoteClient
    public let tabs: [RemoteTab]

    public var description: String {
        return "<Client guid: \(client.guid ?? "nil"), \(tabs.count) tabs.>"
    }

    public init(client: RemoteClient, tabs: [RemoteTab]) {
        self.client = client
        self.tabs = tabs
    }
}

public func == (lhs: ClientAndTabs, rhs: ClientAndTabs) -> Bool {
    return (lhs.client == rhs.client) &&
           (lhs.tabs == rhs.tabs)
}

public struct RemoteTab: Equatable {
    public let clientGUID: String?
    public let URL: Foundation.URL
    public let title: String
    public let history: [Foundation.URL]
    public let lastUsed: Timestamp
    public let icon: Foundation.URL?
    public let inactive: Bool

    public static func shouldIncludeURL(_ url: Foundation.URL) -> Bool {
        if InternalURL(url) != nil {
            return false
        }

        if url.scheme == "javascript" {
            return false
        }

        return url.host != nil
    }

    public init(
        clientGUID: String?,
        URL: Foundation.URL,
        title: String,
        history: [Foundation.URL],
        lastUsed: Timestamp,
        icon: Foundation.URL?,
        inactive: Bool
    ) {
        self.clientGUID = clientGUID
        self.URL = URL
        self.title = title
        self.history = history
        self.lastUsed = lastUsed
        self.icon = icon
        self.inactive = inactive
    }

    public func withClientGUID(_ clientGUID: String?) -> RemoteTab {
        return RemoteTab(
            clientGUID: clientGUID,
            URL: URL,
            title: title,
            history: history,
            lastUsed: lastUsed,
            icon: icon,
            inactive: inactive
        )
    }

    public func toRemoteTabRecord() -> RemoteTabRecord {
        var history: [String] = []
        history.append(contentsOf: self.history.map { $0.absoluteString })

        let icon = self.icon != nil ? self.icon?.absoluteString : nil

        return RemoteTabRecord(
            title: self.title,
            urlHistory: history,
            icon: icon,
            lastUsed: Int64(self.lastUsed),
            inactive: self.inactive
        )
    }
}

public func == (lhs: RemoteTab, rhs: RemoteTab) -> Bool {
    return lhs.clientGUID == rhs.clientGUID &&
        lhs.URL == rhs.URL &&
        lhs.title == rhs.title &&
        lhs.history == rhs.history &&
        lhs.lastUsed == rhs.lastUsed &&
        lhs.icon == rhs.icon &&
        lhs.inactive == rhs.inactive
}
