//
//  Commands.swift
//  Client
//
//  Created by Emily Toop on 6/29/15.
//  Copyright (c) 2015 Mozilla. All rights reserved.
//

import Shared

public struct SyncCommand: Equatable {
    public let guid: GUID
    public let modified: Timestamp

    public let title: String?
    public let url: String?
    public let action: String?
    public let client: GUID

    let version: String?

    public init(guid: GUID, clientGuid: GUID, url: String?, title: String?, action: String, lastUsed: Timestamp) {
        self.guid = guid
        self.client = clientGuid
        self.url = url
        self.title = title
        self.action = action
        self.modified = lastUsed
        self.version = nil
    }
}

public func ==(lhs: SyncCommand, rhs: SyncCommand) -> Bool {
    return lhs.guid == rhs.guid
}


public protocol SyncCommands {
    func wipeCommands() -> Deferred<Result<()>>
    func wipeCommandsForClient(client: RemoteClient) -> Deferred<Result<()>>

    func getCommands() -> Deferred<Result<[SyncCommand]>>
    func getCommandsForClient(client: RemoteClient) -> Deferred<Result<[SyncCommand]>>
    
    func insertCommand(command: SyncCommand) -> Deferred<Result<Int>>
    func insertCommands(commands: [SyncCommand]) -> Deferred<Result<Int>>

    func onRemovedAccount() -> Success
}