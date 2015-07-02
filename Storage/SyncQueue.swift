/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

public struct SyncCommand: Equatable {
    public let value: String
    public let commandID: Int?

    let version: String?

    public init(value: String) {
        self.value = value
        self.version = nil
        self.commandID = nil
    }

    public init(id: Int, value: String) {
        self.value = value
        self.version = nil
        self.commandID = id
    }

    public static func fromShareItem(shareItem: ShareItem, withAction action: String) -> SyncCommand {
        let jsonObj:[String: AnyObject] = [
            "command": action,
            "args": [shareItem.url, shareItem.title ?? ""]
        ]
        return SyncCommand(value: JSON.stringify(jsonObj, pretty: false))
    }
}

public func ==(lhs: SyncCommand, rhs: SyncCommand) -> Bool {
    return lhs.value == rhs.value
}


public protocol SyncCommands {
    func deleteCommands() -> Success
    func deleteCommandsForClient(client: RemoteClient) -> Success

    func getCommands() -> Deferred<Result<[SyncCommand]>>
    func getCommandsForClient(client: RemoteClient) -> Deferred<Result<[SyncCommand]>>
    
    func insertCommand(command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Result<Int>>
    func insertCommands(commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Result<Int>>

    func onRemovedAccount() -> Success
}