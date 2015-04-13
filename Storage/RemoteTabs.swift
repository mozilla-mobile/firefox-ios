/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public struct ClientAndTabs: Equatable, Printable {
    public let client: RemoteClient
    public let tabs: [RemoteTab]

    public var description: String {
        return "<Client \(client.guid), \(tabs.count) tabs.>"
    }
}

public func ==(lhs: ClientAndTabs, rhs: ClientAndTabs) -> Bool {
    return (lhs.client == rhs.client) &&
           (lhs.tabs == rhs.tabs)
}

public protocol RemoteClientsAndTabs {
    func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>>
}


public struct RemoteTab: Equatable {
    public let clientGUID: String
    public let URL: NSURL
    public let title: String
    public let history: [NSURL]
    public let lastUsed: Timestamp
    public let icon: NSURL?

    public init(clientGUID: String, URL: NSURL, title: String, history: [NSURL], lastUsed: Timestamp, icon: NSURL?) {
        self.clientGUID = clientGUID
        self.URL = URL
        self.title = title
        self.history = history
        self.lastUsed = lastUsed
        self.icon = icon
    }

    public func withClientGUID(clientGUID: String) -> RemoteTab {
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

extension RemoteTab: Printable {
    public var description: String {
        return "<RemoteTab clientGUID: \(clientGUID), URL: \(URL), title: \(title), lastUsed: \(lastUsed)>"
    }
}

public class MockRemoteClientsAndTabs: RemoteClientsAndTabs {
    public let clientsAndTabs: [ClientAndTabs]

    public init() {
        let now = NSDate.now()
        let client1GUID = Bytes.generateGUID()
        let client2GUID = Bytes.generateGUID()
        let u11 = NSURL(string: "http://test.com/test1")!
        let tab11 = RemoteTab(clientGUID: client1GUID, URL: u11, title: "Test 1", history: [], lastUsed: (now - OneMinuteInMilliseconds), icon: nil)

        let u12 = NSURL(string: "http://test.com/test2")!
        let tab12 = RemoteTab(clientGUID: client1GUID, URL: u12, title: "Test 2", history: [], lastUsed: (now - OneHourInMilliseconds), icon: nil)

        let tab21 = RemoteTab(clientGUID: client2GUID, URL: u11, title: "Test 1", history: [], lastUsed: (now - OneDayInMilliseconds), icon: nil)

        let u22 = NSURL(string: "http://different.com/test2")!
        let tab22 = RemoteTab(clientGUID: client2GUID, URL: u22, title: "Different Test 2", history: [], lastUsed: now + OneHourInMilliseconds, icon: nil)

        let client1 = RemoteClient(guid: client1GUID, name: "Test client 1", modified: (now - OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS")
        let client2 = RemoteClient(guid: client2GUID, name: "Test client 2", modified: (now - OneHourInMilliseconds), type: "desktop", formfactor: "laptop", os: "Darwin")

        // Tabs are ordered most-recent-first.
        self.clientsAndTabs = [ClientAndTabs(client: client1, tabs: [tab11, tab12]), ClientAndTabs(client: client2, tabs: [tab22, tab21])]
    }


    public func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>> {
        return Deferred(value: Result(success: self.clientsAndTabs))
    }
}
