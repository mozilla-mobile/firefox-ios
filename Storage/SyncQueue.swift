/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Deferred

public struct SyncCommand: Equatable {
    public let value: String
    public var commandID: Int?
    public var clientGUID: GUID?

    let version: String?

    public init(value: String) {
        self.value = value
        self.version = nil
        self.commandID = nil
        self.clientGUID = nil
    }

    public init(id: Int, value: String) {
        self.value = value
        self.version = nil
        self.commandID = id
        self.clientGUID = nil
    }

    public init(id: Int?, value: String, clientGUID: GUID?) {
        self.value = value
        self.version = nil
        self.clientGUID = clientGUID
        self.commandID = id
    }


    public static func fromShareItem(_ shareItem: ShareItem, withAction action: String) -> SyncCommand {
        let jsonObj: [String: AnyObject] = [
            "command": action,
            "args": [shareItem.url, "", shareItem.title ?? ""]
        ]
        return SyncCommand(value: JSON.stringify(jsonObj, pretty: false))
    }

    public func withClientGUID(_ clientGUID: String?) -> SyncCommand {
        return SyncCommand(id: self.commandID, value: self.value, clientGUID: clientGUID)
    }
}

public func ==(lhs: SyncCommand, rhs: SyncCommand) -> Bool {
    return lhs.value == rhs.value
}

public protocol SyncCommands {
    func deleteCommands() -> Success
    func deleteCommands(_ clientGUID: GUID) -> Success

    func getCommands() -> Deferred<Maybe<[GUID: [SyncCommand]]>>

    func insertCommand(_ command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>>
    func insertCommands(_ commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>>
}
