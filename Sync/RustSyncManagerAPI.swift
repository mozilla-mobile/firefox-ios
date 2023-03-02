// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
@_exported import MozillaAppServices

open class RustSyncManagerAPI {
    private let logger: Logger
    let api: SyncManager

    public init(logger: Logger = DefaultLogger.shared) {
        self.api = SyncManager()
        self.logger = logger
    }

    public func disconnect() {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            self.api.disconnect()
        }
    }

    public func sync(params: SyncParams,
                     completion: @escaping (MozillaAppServices.SyncResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            do {
                let result = try self.api.sync(params: params)
                completion(result)
            } catch let err as NSError {
                if let syncError = err as? SyncManagerError {
                    let syncErrDescription = syncError.localizedDescription
                    self.logger.log("Rust SyncManager sync error: \(syncErrDescription)",
                                    level: .warning,
                                    category: .sync)
                } else {
                    let errDescription = err.localizedDescription
                    self.logger.log("""
                        Unknown error when attempting a rust SyncManager sync:
                        \(errDescription)
                        """,
                        level: .warning,
                        category: .sync)
                }
            }
        }
    }

    public func getAvailableEngines(completion: @escaping ([String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            let engines = self.api.getAvailableEngines()
            completion(engines)
        }
    }
}

public func toRustSyncReason(reason: OldSyncReason) -> MozillaAppServices.SyncReason {
    switch reason {
    case .startup:
        return MozillaAppServices.SyncReason.startup
    case .scheduled:
        return MozillaAppServices.SyncReason.scheduled
    case .backgrounded:
        return MozillaAppServices.SyncReason.backgrounded
    case .push, .user, .syncNow:
        return MozillaAppServices.SyncReason.user
    case .didLogin, .clientNameChanged, .engineEnabled:
        return MozillaAppServices.SyncReason.enabledChange
    }
}

// Names of collections that can be enabled/disabled locally.
public let RustTogglableEngines: [String] = [
    "tabs",
    "bookmarks",
    "history",
    "passwords",
]
