/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Deferred
import SwiftyJSON

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

    /**
     * Sent displayURI commands include the sender client GUID.
     */
    public static func displayURIFromShareItem(_ shareItem: ShareItem, asClient sender: GUID) -> SyncCommand {
        let jsonObj: [String: Any] = [
            "command": "displayURI",
            "args": [shareItem.url, sender, shareItem.title ?? ""]
        ]
        return SyncCommand(value: JSON(jsonObj).stringValue()!)
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
