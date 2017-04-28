/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred

public struct ClientAndTabs: Equatable, CustomStringConvertible {
    public let client: RemoteClient
    public let tabs: [RemoteTab]

    public var description: String {
        return "<Client guid: \(client.guid ?? "nil"), \(tabs.count) tabs.>"
    }

    // See notes in RemoteTabsPanel.swift.
    public func approximateLastSyncTime() -> Timestamp {
        if tabs.isEmpty {
            return client.modified
        }

        return tabs.reduce(Timestamp(0), { m, tab in
            return max(m, tab.lastUsed)
        })
    }
}

public func ==(lhs: ClientAndTabs, rhs: ClientAndTabs) -> Bool {
    return (lhs.client == rhs.client) &&
           (lhs.tabs == rhs.tabs)
}

public protocol RemoteClientsAndTabs: SyncCommands {
    func wipeClients() -> Deferred<Maybe<()>>
    func wipeRemoteTabs() -> Deferred<Maybe<()>>
    func wipeTabs() -> Deferred<Maybe<()>>
    func getClientGUIDs() -> Deferred<Maybe<Set<GUID>>>
    func getClients() -> Deferred<Maybe<[RemoteClient]>>
    func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>>
    func getTabsForClientWithGUID(_ guid: GUID?) -> Deferred<Maybe<[RemoteTab]>>
    func insertOrUpdateClient(_ client: RemoteClient) -> Deferred<Maybe<Int>>
    func insertOrUpdateClients(_ clients: [RemoteClient]) -> Deferred<Maybe<Int>>

    // Returns number of tabs inserted.
    func insertOrUpdateTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> // Insert into the local client.
    func insertOrUpdateTabsForClientGUID(_ clientGUID: String?, tabs: [RemoteTab]) -> Deferred<Maybe<Int>>
}

public struct RemoteTab: Equatable {
    public let clientGUID: String?
    public let URL: Foundation.URL
    public let title: String
    public let history: [Foundation.URL]
    public let lastUsed: Timestamp
    public let icon: Foundation.URL?

    public static func shouldIncludeURL(_ url: Foundation.URL) -> Bool {
        let scheme = url.scheme
        if scheme == "about" {
            return false
        }
        if scheme == "javascript" {
            return false
        }

        if let hostname = url.host?.lowercased() {
            if hostname == "localhost" {
                return false
            }
            return true
        }
        return false
    }

    public init(clientGUID: String?, URL: Foundation.URL, title: String, history: [Foundation.URL], lastUsed: Timestamp, icon: Foundation.URL?) {
        self.clientGUID = clientGUID
        self.URL = URL
        self.title = title
        self.history = history
        self.lastUsed = lastUsed
        self.icon = icon
    }

    public func withClientGUID(_ clientGUID: String?) -> RemoteTab {
        return RemoteTab(clientGUID: clientGUID, URL: URL, title: title, history: history, lastUsed: lastUsed, icon: icon)
    }
}

public func ==(lhs: RemoteTab, rhs: RemoteTab) -> Bool {
    return lhs.clientGUID == rhs.clientGUID &&
        lhs.URL == rhs.URL &&
        lhs.title == rhs.title &&
        lhs.history == rhs.history &&
        lhs.lastUsed == rhs.lastUsed &&
        lhs.icon == rhs.icon
}

extension RemoteTab: CustomStringConvertible {
    public var description: String {
        return "<RemoteTab clientGUID: \(clientGUID ?? "nil"), URL: \(URL), title: \(title), lastUsed: \(lastUsed)>"
    }
}
