/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public protocol RemoteClientsAndTabs {
    func getClientsAndTabs(complete: (clients: [RemoteClient]?) -> Void)
}

public struct RemoteClient: Equatable {
    public let GUID: String
    public let name: String
    public let lastModified: Int64
    public let type: String?
    public let formFactor: String?
    public let operatingSystem: String?
    public let tabs: [RemoteTab]

    public init(GUID: String, name: String, lastModified: Int64, type: String?, formFactor: String?, operatingSystem: String?, tabs: [RemoteTab]) {
        self.GUID = GUID
        self.name = name
        self.lastModified = lastModified
        self.type = type
        self.formFactor = formFactor
        self.operatingSystem = operatingSystem
        self.tabs = tabs
    }

    public func withTabs(tabs: [RemoteTab]) -> RemoteClient {
        return RemoteClient(GUID: GUID, name: name, lastModified: lastModified, type: type, formFactor: formFactor, operatingSystem: operatingSystem, tabs: tabs)
    }
}

public func ==(lhs: RemoteClient, rhs: RemoteClient) -> Bool {
    return lhs.GUID == rhs.GUID &&
        lhs.name == rhs.name &&
        lhs.lastModified == rhs.lastModified &&
        lhs.type == rhs.type &&
        lhs.formFactor == rhs.formFactor &&
        lhs.operatingSystem == rhs.operatingSystem &&
        lhs.tabs == rhs.tabs
}

extension RemoteClient: Printable {
    public var description: String {
        return "<RemoteClient GUID: \(GUID), name: \(name), lastModified: \(lastModified), type: \(type), formFactor: \(formFactor), OS: \(operatingSystem), with \(tabs.count) tabs>"
    }
}

public struct RemoteTab: Equatable {
    public let clientGUID: String
    public let URL: NSURL
    public let title: String?
    public let history: [NSURL]
    public let lastUsed: Int64
    public let position: Int32

    public init(clientGUID: String, URL: NSURL, title: String?, history: [NSURL], lastUsed: Int64, position: Int32) {
        self.clientGUID = clientGUID
        self.URL = URL
        self.title = title
        self.history = history
        self.lastUsed = lastUsed
        self.position = position
    }

    public func withClientGUID(clientGUID: String) -> RemoteTab {
        return RemoteTab(clientGUID: clientGUID, URL: URL, title: title, history: history, lastUsed: lastUsed, position: position)
    }
}

public func ==(lhs: RemoteTab, rhs: RemoteTab) -> Bool {
    return lhs.clientGUID == rhs.clientGUID &&
        lhs.URL == rhs.URL &&
        lhs.title == rhs.title &&
        lhs.history == rhs.history &&
        lhs.lastUsed == rhs.lastUsed &&
        lhs.position == rhs.position
}

extension RemoteTab: Printable {
    public var description: String {
        return "<RemoteTab clientGUID: \(clientGUID), URL: \(URL), title: \(title), lastUsed: \(lastUsed), position: \(position)>"
    }
}

// We have a Shared target but it's not accessible from Storage.  Eventually Storage will be a
// target within the main Client project, at which point we can kill these.
private let OneMonthInMilliseconds = 30 * OneDayInMilliseconds
private let OneWeekInMilliseconds = 7 * OneDayInMilliseconds
private let OneDayInMilliseconds = 24 * OneHourInMilliseconds
private let OneHourInMilliseconds: Int64 = 60 * OneMinuteInMilliseconds
private let OneMinuteInMilliseconds: Int64 = 60 * 1000

public class MockRemoteClientsAndTabs: RemoteClientsAndTabs {
    // This makes the var read-only to a public consumer.
    public lazy var clients: [RemoteClient] = {
        let now = Int64(NSDate().timeIntervalSince1970 * 1000.0)
        let client1GUID = Bytes.generateGUID()
        let client2GUID = Bytes.generateGUID()
        let tab11 = RemoteTab(clientGUID: client1GUID,
            URL: NSURL(string: "http://test.com/test1")!, title: "Test 1", history: [], lastUsed: now + OneMinuteInMilliseconds, position: 0)
        let tab12 = RemoteTab(clientGUID: client1GUID,
            URL: NSURL(string: "http://test.com/test2")!, title: "Test 2", history: [], lastUsed: now + OneHourInMilliseconds, position: 1)

        let tab21 = RemoteTab(clientGUID: client2GUID,
            URL: NSURL(string: "http://test.com/test1")!, title: "Test 1", history: [], lastUsed: now + OneDayInMilliseconds, position: 0)
        let tab22 = RemoteTab(clientGUID: client2GUID,
            URL: NSURL(string: "http://different.com/test2")!, title: "Different Test 2", history: [], lastUsed: now + OneHourInMilliseconds, position: 1)

        let client1 = RemoteClient(GUID: client1GUID, name: "Test client 1", lastModified: Int64(now + OneMinuteInMilliseconds), type: "mobile", formFactor: "largetablet", operatingSystem: "iOS", tabs: [tab11, tab12])
        let client2 = RemoteClient(GUID: client2GUID, name: "Test client 2", lastModified: Int64(now + OneHourInMilliseconds), type: "desktop", formFactor: "laptop", operatingSystem: "Darwin", tabs: [tab21, tab22])
        return [client1, client2]
    }()

    public init() {
    }

    public func getClientsAndTabs(complete: (clients: [RemoteClient]?) -> Void) {
        complete(clients: clients)
    }
}
