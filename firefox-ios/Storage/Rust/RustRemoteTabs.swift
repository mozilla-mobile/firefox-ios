// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

import class MozillaAppServices.TabsStore
import class MozillaAppServices.RemoteCommandStore
import enum MozillaAppServices.TabsApiError
import enum MozillaAppServices.RemoteCommand
import struct MozillaAppServices.ClientRemoteTabs
import struct MozillaAppServices.RemoteTabRecord
import struct MozillaAppServices.PendingCommand

public class RustRemoteTabs {
    let databasePath: String
    let queue: DispatchQueue
    let commandQueue: DispatchQueue
    var store: TabsStore?
    internal var tabsCommandQueue: RemoteTabsCommandQueue?

    private(set) var isOpen = false
    private var didAttemptToMoveToBackup = false
    private let logger: Logger

    public init(databasePath: String,
                logger: Logger = DefaultLogger.shared) {
        self.databasePath = databasePath
        self.logger = logger

        queue = DispatchQueue(label: "RustRemoteTabs queue: \(databasePath)", attributes: [])
        commandQueue = DispatchQueue(label: "RustRemoteTabs command queue", attributes: [])
    }

    private func open() -> NSError? {
        store = TabsStore(path: databasePath)
        isOpen = true
        tabsCommandQueue = RemoteTabsCommandQueue(tabsStore: store!)
        return nil
    }

    private func close() -> NSError? {
        store = nil
        isOpen = false
        tabsCommandQueue = nil
        return nil
    }

    public func reopenIfClosed() -> NSError? {
        var error: NSError?

        queue.sync {
            guard !isOpen else { return }

            error = open()
        }

        return error
    }

    public func forceClose() -> NSError? {
        var error: NSError?

        queue.sync {
            guard isOpen else { return }

            error = close()
        }

        return error
    }

    public func setLocalTabs(localTabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        let deferred = Deferred<Maybe<Int>>()
        queue.async {
            guard let store = self.store else {
                let error = TabsApiError.UnexpectedTabsError(reason: "TabsStore is not available")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }
            let tabs = localTabs.map { $0.toRemoteTabRecord() }
            store.setLocalTabs(remoteTabs: tabs)
            deferred.fill(Maybe(success: tabs.count))
        }
        return deferred
    }

    public func getAll() -> Deferred<Maybe<[ClientRemoteTabs]>> {
        // Note: this call will get all of the client and tabs data from
        // the application storage tabs store without filter against the
        // BrowserDB client records.
        let deferred = Deferred<Maybe<[ClientRemoteTabs]>>()

        queue.async {
            guard self.isOpen else {
                let error = TabsApiError.UnexpectedTabsError(reason: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            if let storage = self.store {
                let records = storage.getAll()
                deferred.fill(Maybe(success: records))
            } else {
                deferred.fill(
                    Maybe(
                        failure: TabsApiError.UnexpectedTabsError(
                            reason: "Unknown error when getting all Rust Tabs"
                        ) as MaybeErrorType
                    )
                )
            }
        }

        return deferred
    }

    public func getClient(fxaDeviceId: String) -> Deferred<Maybe<RemoteClient?>> {
        return self.getAll().bind { result in
            if let failureValue = result.failureValue {
                return deferMaybe(failureValue)
            }

            guard let records = result.successValue else {
                return deferMaybe(nil)
            }

            let client = records.first(where: { $0.clientId == fxaDeviceId })?.toRemoteClient()
            return deferMaybe(client)
        }
    }

    public func getClientGUIDs(completion: @escaping (Set<GUID>?, Error?) -> Void) {
        self.getAll().upon { result in
            if let failureValue = result.failureValue {
                completion(nil, failureValue)
                return
            }
            guard let records = result.successValue else {
                completion(Set<GUID>(), nil)
                return
            }

            let guids = records.map({ $0.clientId })
            completion(Set(guids), nil)
        }
    }

    public func getRemoteClients(remoteDeviceIds: [String]) -> Deferred<Maybe<[ClientAndTabs]>> {
        return self.getAll().bind { result in
            if let failureValue = result.failureValue {
                return deferMaybe(failureValue)
            }
            guard let rustClientAndTabs = result.successValue else {
                return deferMaybe([])
            }

            let clientAndTabs = rustClientAndTabs
                .map { $0.toClientAndTabs() }
                .filter({ record in
                    remoteDeviceIds.contains { deviceId in
                        return record.client.fxaDeviceId != nil &&
                            record.client.fxaDeviceId! == deviceId
                    }
                })
            return deferMaybe(clientAndTabs)
        }
    }

    public func registerWithSyncManager() {
        queue.async { [unowned self] in
           self.store?.registerWithSyncManager()
        }
    }

    // MARK: Remote Command APIs
    public func addRemoteCommand(deviceId: String, url: URL) {
        commandQueue.async { [unowned self] in
            guard let tabsCommandQueue = self.tabsCommandQueue else {
                let err = TabsApiError.UnexpectedTabsError(reason: "Command queue is not initialized") as MaybeErrorType
                self.logger.log(err.description,
                                level: .warning,
                                category: .tabs)
                return
            }
            tabsCommandQueue
                .addRemoteCommand(deviceId: deviceId, command: RemoteCommand.closeTab(url: url.absoluteString)) { result in
                    switch result {
                    case .failure(let error):
                        self.logger.log("Failed to update command queue: \(String(describing: error))",
                                        level: .warning,
                                        category: .tabs)
                    default:
                        break
                    }
                }
        }
    }

    public func removeRemoteCommand(deviceId: String, url: URL) {
        commandQueue.async { [unowned self] in
            guard let tabsCommandQueue = self.tabsCommandQueue else {
                let err = TabsApiError.UnexpectedTabsError(reason: "Command queue is not initialized") as MaybeErrorType
                self.logger.log(err.description,
                                level: .warning,
                                category: .tabs)
                return
            }

            tabsCommandQueue
                .removeRemoteCommand(deviceId: deviceId,
                                     command: RemoteCommand.closeTab(url: url.absoluteString)) { result in
                    switch result {
                    case .failure(let error):
                        self.logger.log("Failed to update command queue: \(String(describing: error))",
                                        level: .warning,
                                        category: .tabs)
                    default:
                        break
                    }
                }
        }
    }

    public func getUnsentCommandUrlsByDeviceId(deviceId: String, completion: @escaping ([String]) -> Void) {
        self.getUnsentCommandsByDeviceId(deviceId: deviceId) { commands in
            let urls = commands.map { item in
                switch item.command {
                case .closeTab(let url):
                    return url
                }
            }
            completion(urls)
        }
    }

    public func setPendingCommandsSent(deviceId: String, unsentCommandUrls: [String] = [String]()) {
        guard let tabsCommandQueue = self.tabsCommandQueue else {
            let err = TabsApiError.UnexpectedTabsError(reason: "Command queue is not initialized") as MaybeErrorType
            self.logger.log(err.description,
                            level: .warning,
                            category: .tabs)
            return
        }

        self.getUnsentCommandsByDeviceId(deviceId: deviceId) { commands in
            let sentCommands = self.getSentCommands(unsentCommandUrls: unsentCommandUrls, commands: commands)

            // mark the commands we know to be successfully sent as sent so we don't attempt to send the
            // commands again
            tabsCommandQueue.setPendingCommandsSent(deviceId: deviceId, commands: sentCommands) { errors in
                if errors.isEmpty {
                    return
                } else {
                    let errHeader = "Failed to set some pending commands as sent:\n"
                    let errMessages: String = errors.reduce(errHeader, { result, err in
                        result.appending("  - \(err.localizedDescription)\n")
                    })
                    self.logger.log(errMessages,
                                    level: .warning,
                                    category: .tabs)
                }
            }
        }
    }

    func getSentCommands(unsentCommandUrls: [String], commands: [PendingCommand]) -> [PendingCommand] {
        var sentCommands = [PendingCommand]()
        if unsentCommandUrls.isEmpty {
            // All of the commands we attempted to send were successfully sent so we do not need to filter
            // against `unsentCommandUrls`.
            sentCommands = commands
        } else {
            // Filtering the commands we retrieved against the `unsentCommandUrls` we received after
            // attempting to send close tab commands. This will leave the commands associated with the
            // `unsentCommandUrls` in the command queue for a future potentially successful close tab
            // command execution.
            sentCommands = commands.filter({
                switch $0.command {
                case .closeTab(let commandUrl):
                    return !unsentCommandUrls.contains(commandUrl)
                }
            })
        }
        return sentCommands
    }

    private func getUnsentCommandsByDeviceId(deviceId: String, completion: @escaping ([PendingCommand]) -> Void) {
        commandQueue.async { [unowned self] in
            guard let tabsCommandQueue = self.tabsCommandQueue else {
                let err = TabsApiError.UnexpectedTabsError(reason: "Command queue is not initialized") as MaybeErrorType
                self.logger.log(err.description,
                                level: .warning,
                                category: .tabs)
                completion([PendingCommand]())
                return
            }

            tabsCommandQueue.getUnsentCommands { result in
                switch result {
                case .success(let commands):
                    let filteredCommands = commands.filter { $0.deviceId == deviceId }
                    completion(filteredCommands)
                case .failure(let error):
                    self.logger.log("Failed to get unsent commands: \(String(describing: error))",
                                    level: .warning,
                                    category: .tabs)
                    completion([PendingCommand]())
                }
            }
        }
    }
}

internal class RemoteTabsCommandQueue {
    var commandStore: RemoteCommandStore

    init(tabsStore: TabsStore) {
        self.commandStore = tabsStore.newRemoteCommandStore()
    }

    func addRemoteCommand(deviceId: String,
                          command: RemoteCommand,
                          completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let didQueueCommand = try commandStore.addRemoteCommand(deviceId: deviceId, command: command)

            if didQueueCommand {
                completion(.success(didQueueCommand))
            } else {
                let err = TabsApiError.UnexpectedTabsError(reason: "Command already existed")
                completion(.failure(err))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func removeRemoteCommand(deviceId: String,
                             command: RemoteCommand,
                             completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let didRemoveCommand = try commandStore.removeRemoteCommand(deviceId: deviceId, command: command)

            if didRemoveCommand {
                completion(.success(didRemoveCommand))
            } else {
                let err = TabsApiError.UnexpectedTabsError(reason: "Command to remove wasn't found")
                completion(.failure(err))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func getUnsentCommands(completion: @escaping (Result<[PendingCommand], Error>) -> Void) {
        do {
            let commands = try commandStore.getUnsentCommands()
            completion(.success(commands))
        } catch {
            completion(.failure(error))
        }
    }

    func setPendingCommandsSent(deviceId: String,
                                commands: [PendingCommand],
                                completion: @escaping ([Error]) -> Void) {
        var errors = [Error]()
        commands.forEach {
            do {
                let pendingCommand = PendingCommand(deviceId: deviceId,
                                                    command: $0.command,
                                                    timeRequested: Date().toMillisecondsSince1970(),
                                                    timeSent: nil)
                let didSetSent = try commandStore.setPendingCommandSent(command: pendingCommand)
                if !didSetSent {
                    switch $0.command {
                    case .closeTab(let url):
                        let errMsg = "Unknown error setting close tab command for URL \(url) on device \(deviceId) to sent"
                        errors.append(TabsApiError.UnexpectedTabsError(reason: errMsg))
                    }
                }
            } catch {
                errors.append(error)
            }
        }
        completion(errors)
    }
}

public extension RemoteTabRecord {
    func toRemoteTab(client: RemoteClient) -> RemoteTab? {
        guard let url = Foundation.URL(string: self.urlHistory[0], invalidCharacters: false) else { return nil }
        let history = self.urlHistory[1...].map { url in
            Foundation.URL(
                string: url,
                invalidCharacters: false
            )
        }.compactMap { $0 }
        let icon = self.icon != nil ? Foundation.URL(fileURLWithPath: self.icon ?? "") : nil

        return RemoteTab(
            clientGUID: client.guid,
            URL: url,
            title: self.title,
            history: history,
            lastUsed: Timestamp(self.lastUsed),
            icon: icon,
            inactive: self.inactive
        )
    }
}

public extension ClientRemoteTabs {
    func toClientAndTabs(client: RemoteClient) -> ClientAndTabs {
        return ClientAndTabs(
            client: client,
            tabs: self.remoteTabs.map { $0.toRemoteTab(client: client) }.compactMap { $0 })
    }

    func toClientAndTabs() -> ClientAndTabs {
        let client = self.toRemoteClient()
        let tabs = self.remoteTabs.map { $0.toRemoteTab(client: client) }.compactMap { $0 }

        let clientAndTabs = ClientAndTabs(client: client, tabs: tabs)
        return clientAndTabs
    }

    func toRemoteClient() -> RemoteClient {
        let remoteClient = RemoteClient(guid: self.clientId,
                                        name: self.clientName,
                                        modified: UInt64(self.lastModified),
                                        type: "\(self.deviceType)",
                                        formfactor: nil,
                                        os: nil,
                                        version: nil,
                                        fxaDeviceId: self.clientId)
        return remoteClient
    }
}
