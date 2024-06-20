// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

import class MozillaAppServices.TabsStore
import enum MozillaAppServices.TabsApiError
import struct MozillaAppServices.ClientRemoteTabs
import struct MozillaAppServices.RemoteTabRecord

public class RustRemoteTabs {
    let databasePath: String
    let queue: DispatchQueue
    var store: TabsStore?
    private(set) var isOpen = false
    private var didAttemptToMoveToBackup = false
    private let logger: Logger

    public init(databasePath: String,
                logger: Logger = DefaultLogger.shared) {
        self.databasePath = databasePath
        self.logger = logger

        queue = DispatchQueue(label: "RustRemoteTabs queue: \(databasePath)", attributes: [])
    }

    private func open() -> NSError? {
        store = TabsStore(path: databasePath)
        isOpen = true
        return nil
    }

    private func close() -> NSError? {
        store = nil
        isOpen = false
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
