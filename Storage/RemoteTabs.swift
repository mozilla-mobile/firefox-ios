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
        return "<Client \(client.guid), \(tabs.count) tabs.>"
    }

    // See notes in RemoteTabsPanel.swift.
    public func approximateLastSyncTime() -> Timestamp {
        if tabs.isEmpty {
            return client.modified
        }

        return tabs.reduce(Timestamp(0), combine: { m, tab in
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
    func getTabsForClientWithGUID(guid: GUID?) -> Deferred<Maybe<[RemoteTab]>>
    func insertOrUpdateClient(client: RemoteClient) -> Deferred<Maybe<()>>
    func insertOrUpdateClients(clients: [RemoteClient]) -> Deferred<Maybe<()>>

    // Returns number of tabs inserted.
    func insertOrUpdateTabs(tabs: [RemoteTab]) -> Deferred<Maybe<Int>> // Insert into the local client.
    func insertOrUpdateTabsForClientGUID(clientGUID: String?, tabs: [RemoteTab]) -> Deferred<Maybe<Int>>
}

public struct RemoteTab: Equatable {
    public let clientGUID: String?
    public let URL: NSURL
    public let title: String
    public let history: [NSURL]
    public let lastUsed: Timestamp
    public let icon: NSURL?

    public static func shouldIncludeURL(url: NSURL) -> Bool {
        let scheme = url.scheme
        if scheme == "about" {
            return false
        }
        if scheme == "javascript" {
            return false
        }

        if let hostname = url.host?.lowercaseString {
            if hostname == "localhost" {
                return false
            }
            return true
        }
        return false
    }

    public init(clientGUID: String?, URL: NSURL, title: String, history: [NSURL], lastUsed: Timestamp, icon: NSURL?) {
        self.clientGUID = clientGUID
        self.URL = URL
        self.title = title
        self.history = history
        self.lastUsed = lastUsed
        self.icon = icon
    }

    public func withClientGUID(clientGUID: String?) -> RemoteTab {
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
        return "<RemoteTab clientGUID: \(clientGUID), URL: \(URL), title: \(title), lastUsed: \(lastUsed)>"
    }
}
