/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public protocol RemoteClientsAndTabs {
    func getClientsAndTabs(complete: (clients: [RemoteClient]?) -> Void)
}

public struct RemoteClient: Equatable {
    public let guid: String
    public let modified: UInt64

    public let name: String
    public let type: String?

    let version: String?
    let protocols: [String]?

    let os: String?
    let appPackage: String?
    let application: String?
    let formfactor: String?
    let device: String?

    public let tabs: [RemoteTab]

    // Requires a valid ClientPayload (: CleartextPayloadJSON: JSON).
    public init(json: JSON, modified: UInt64) {
        self.guid = json["id"].asString!
        self.modified = modified
        self.name = json["name"].asString!
        self.type = json["type"].asString

        self.tabs = []

        // TODO more
    }

    public init(guid: String, name: String, modified: UInt64, type: String?, formfactor: String?, os: String?, tabs: [RemoteTab]) {
        self.guid = guid
        self.name = name
        self.modified = modified
        self.type = type
        self.formfactor = formfactor
        self.os = os
        self.tabs = tabs
    }

    public func withTabs(tabs: [RemoteTab]) -> RemoteClient {
        return RemoteClient(guid: self.guid, name: self.name, modified: self.modified, type: self.type, formfactor: self.formfactor, os: self.os, tabs: tabs)
    }
}

// TODO: should this really compare tabs?
public func ==(lhs: RemoteClient, rhs: RemoteClient) -> Bool {
    return lhs.guid == rhs.guid &&
           lhs.name == rhs.name &&
           lhs.modified == rhs.modified &&
           lhs.type == rhs.type &&
           lhs.formfactor == rhs.formfactor &&
           lhs.os == rhs.os &&
           lhs.tabs == rhs.tabs
}

extension RemoteClient: Printable {
    public var description: String {
        return "<RemoteClient GUID: \(guid), name: \(name), modified: \(modified), type: \(type), formfactor: \(formfactor), OS: \(os), with \(tabs.count) tabs>"
    }
}

public struct RemoteTab: Equatable {
    public let clientGUID: String
    public let URL: NSURL
    public let title: String?
    public let history: [NSURL]
    public let lastUsed: UInt64
    public let position: Int32

    public init(clientGUID: String, URL: NSURL, title: String?, history: [NSURL], lastUsed: UInt64, position: Int32) {
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

public class MockRemoteClientsAndTabs: RemoteClientsAndTabs {
    // This makes the var read-only to a public consumer.
    public lazy var clients: [RemoteClient] = {
        let now = NSDate.now()
        let client1GUID = Bytes.generateGUID()
        let client2GUID = Bytes.generateGUID()
        let u11 = NSURL(string: "http://test.com/test1")!
        let tab11 = RemoteTab(clientGUID: client1GUID, URL: u11, title: "Test 1", history: [], lastUsed: (now + OneMinuteInMilliseconds), position: 0)

        let u12 = NSURL(string: "http://test.com/test2")!
        let tab12 = RemoteTab(clientGUID: client1GUID, URL: u12, title: "Test 2", history: [], lastUsed: (now + OneHourInMilliseconds), position: 1)

        let tab21 = RemoteTab(clientGUID: client2GUID, URL: u11, title: "Test 1", history: [], lastUsed: now + OneDayInMilliseconds, position: 0)

        let u22 = NSURL(string: "http://different.com/test2")!
        let tab22 = RemoteTab(clientGUID: client2GUID, URL: u22, title: "Different Test 2", history: [], lastUsed: now + OneHourInMilliseconds, position: 1)

        let client1 = RemoteClient(guid: client1GUID, name: "Test client 1", modified: (now + OneMinuteInMilliseconds), type: "mobile", formfactor: "largetablet", os: "iOS", tabs: [tab11, tab12])
        let client2 = RemoteClient(guid: client2GUID, name: "Test client 2", modified: (now + OneHourInMilliseconds), type: "desktop", formfactor: "laptop", os: "Darwin", tabs: [tab21, tab22])
        return [client1, client2]
    }()

    public init() {
    }

    public func getClientsAndTabs(complete: (clients: [RemoteClient]?) -> Void) {
        complete(clients: clients)
    }
}
