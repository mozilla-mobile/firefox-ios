// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

import class MozillaAppServices.SyncManagerComponent
import enum MozillaAppServices.SyncManagerError
import struct MozillaAppServices.SyncParams
import struct MozillaAppServices.SyncResult

open class RustSyncManagerAPI {
    private let logger: Logger
    let api: SyncManagerComponent

    // Names of collections that can be enabled/disabled locally.
    public enum TogglableEngine: String, CaseIterable {
        case tabs
        case passwords
        case bookmarks
        case history
        case creditcards
        case addresses
    }

    public var rustTogglableEngines: [TogglableEngine] = [.tabs, .passwords, .bookmarks, .history, .creditcards, .addresses]
    public init(logger: Logger = DefaultLogger.shared) {
        self.api = SyncManagerComponent()
        self.logger = logger
    }

    public func disconnect() {
        DispatchQueue.global().async { [unowned self] in
            self.api.disconnect()
        }
    }

    public func sync(params: SyncParams,
                     completion: @escaping (SyncResult) -> Void) {
        DispatchQueue.global().async { [weak self] in
            do {
                guard let result = try self?.api.sync(params: params) else { return }

                completion(result)
            } catch let err as NSError {
                if let syncError = err as? SyncManagerError {
                    let syncErrDescription = syncError.localizedDescription
                    self?.logger.log("Rust SyncManager sync error: \(syncErrDescription)",
                                     level: .warning,
                                     category: .sync)
                } else {
                    let errDescription = err.localizedDescription
                    self?.logger.log("""
                        Unknown error when attempting a rust SyncManager sync:
                        \(errDescription)
                        """,
                        level: .warning,
                        category: .sync)
                }
            }
        }
    }

    public func reportSyncTelemetry(syncResult: SyncResult,
                                    completion: @escaping (String) -> Void) {
        DispatchQueue.global().async { [unowned self] in
            do {
                try SyncManagerComponent.reportSyncTelemetry(syncResult: syncResult)
            } catch let err as NSError {
                let description = err.localizedDescription
                self.logger.log("""
                    Unknown error when reporting telemetry for the Rust SyncManager:
                    \(description)
                    """,
                    level: .warning,
                    category: .sync)
                completion(description)
            }
        }
    }

    public func getAvailableEngines(completion: @escaping ([String]) -> Void) {
        DispatchQueue.global().async { [unowned self] in
            let engines = self.api.getAvailableEngines()
            completion(engines)
        }
    }
}
