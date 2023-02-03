// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@_exported import MozillaAppServices

open class RustSyncManagerAPI {
    let queue: DispatchQueue
    var api: SyncManager

    public init() {
        queue = DispatchQueue(label: "RustSyncManager queue", attributes: [])
        self.api = SyncManager()
    }

    public func disconnect() {
        queue.async {
            self.api.disconnect()
        }
    }
    
    public func sync(params: SyncParams, completion: @escaping (RustSyncResult) -> Void) {
        queue.async {
            do {
                let result = try self.api.sync(params: params)
                completion(result)
            } catch let err as NSError {
                if let syncError = err as? SyncManagerError {
                    SentryIntegration.shared.sendWithStacktrace(
                        message: "Rust SyncManager sync error",
                        tag: SentryTag.rustSyncManager,
                        severity: .error,
                        description: syncError.localizedDescription)
                } else {
                    SentryIntegration.shared.sendWithStacktrace(
                        message: "Unknown error when attempting a rust SyncManager sync",
                        tag: SentryTag.rustSyncManager,
                        severity: .error,
                        description: err.localizedDescription)
                }
            }
        }
    }

    public func getAvailableEngines() -> Deferred<[String]> {
        let deferred = Deferred<[String]>()
        
        queue.async {
            let engines = self.api.getAvailableEngines()
            deferred.fill(engines)
        }
        
        return deferred
    }
}

public func toRustSyncReason(reason: SyncReason) -> RustSyncReason {
    switch reason{
    case .startup:
        return RustSyncReason.startup
    case .scheduled:
        return RustSyncReason.scheduled
    case .backgrounded:
        return RustSyncReason.backgrounded
    case .user, .syncNow:
        return RustSyncReason.user
    case .didLogin, .clientNameChanged, .engineEnabled:
        return RustSyncReason.enabledChange
    }
}

// Names of collections that can be enabled/disabled locally.
public let RustTogglableEngines: [String] = [
    "bookmarks",
    "history",
    "tabs",
    "passwords"
]
