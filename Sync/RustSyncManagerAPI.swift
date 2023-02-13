// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Logger
import Shared
@_exported import MozillaAppServices

open class RustSyncManagerAPI {
//    let queue: DispatchQueue
    private let logger: Logger
    var api: SyncManager

    public init(logger: Logger = DefaultLogger.shared) {
//        queue = DispatchQueue(label: "RustSyncManager queue", attributes: [])
        self.api = SyncManager()
        self.logger = logger
    }

    public func disconnect() {
//        queue.async {
            self.api.disconnect()
//        }
    }
    
    public func sync(
        params: SyncParams,
        completion: @escaping (MozillaAppServices.SyncResult) -> Void
    ) {
//        queue.async {
            do {
                let result = try self.api.sync(params: params)
                completion(result)
            } catch let err as NSError {
                if let syncError = err as? SyncManagerError {
                    self.logger.log("""
                        Rust SyncManager sync error: \(syncError.localizedDescription)
                        """,
                        level: .warning,
                        category: .sync)
                } else {
                    self.logger.log("""
                        Unknown error when attempting a rust SyncManager sync:
                        \(err.localizedDescription)
                        """,
                        level: .warning,
                        category: .sync)
                }
            }
//        }
    }

    public func getAvailableEngines() -> Deferred<[String]> {
        let deferred = Deferred<[String]>()
        
//        queue.async {
            let engines = self.api.getAvailableEngines()
            deferred.fill(engines)
//        }
        
        return deferred
    }
}

public func toRustSyncReason(reason: Sync.SyncReason) -> MozillaAppServices.SyncReason {
    switch reason{
    case .startup:
        return MozillaAppServices.SyncReason.startup
    case .scheduled:
        return MozillaAppServices.SyncReason.scheduled
    case .backgrounded:
        return MozillaAppServices.SyncReason.backgrounded
    case .user, .syncNow:
        return MozillaAppServices.SyncReason.user
    case .didLogin, .clientNameChanged, .engineEnabled:
        return MozillaAppServices.SyncReason.enabledChange
    }
}

// Names of collections that can be enabled/disabled locally.
public let RustTogglableEngines: [String] = [
    "bookmarks",
    "history",
    "tabs",
    "passwords"
]
