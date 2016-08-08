/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sync
import XCGLogger
import Deferred
import Shared
import Storage

public enum SyncDisplayState {
    case InProgress
    case Good
    case Bad(message: String?)
    case Warning(message: String)

    func asObject() -> [String: String]? {
        switch self {
        case .Bad(let msg):
            guard let message = msg else {
                return ["state": "Error"]
            }
            return ["state": "Error",
                    "message": message]
        case .Warning(let message):
            return ["state": "Warning",
                    "message": message]
        default:
            break
        }
        return nil
    }
}

public func ==(a: SyncDisplayState, b: SyncDisplayState) -> Bool {
    switch (a, b) {
    case (.InProgress,   .InProgress):
        return true
    case (.Good,   .Good):
        return true
    case (.Bad(let a), .Bad(let b)) where a == b:
        return true
    case (.Warning(let a), .Warning(let b)) where a == b:
        return true
    default:
        return false
    }
}

private let log = Logger.syncLogger

/*
 * Translates the fine-grained SyncStatuses of each sync engine into a more coarse-grained
 * display-oriented state for displaying warnings/errors to the user.
 */
public struct SyncStatusResolver {

    let engineResults: Maybe<EngineResults>

    public func resolveResults() -> SyncDisplayState {
        guard let results = engineResults.successValue else {
            switch engineResults.failureValue {
            case _ as BookmarksMergeError, _ as BookmarksDatabaseError:
                return SyncDisplayState.Warning(message: String(format: Strings.FirefoxSyncPartialTitle, Strings.localizedStringForSyncComponent("bookmarks") ?? ""))
            default:
                return SyncDisplayState.Bad(message: nil)
            }
        }

        // Run through the engine results and produce a relevant display status for each one
        let displayStates: [SyncDisplayState] = results.map { (engineIdentifier, syncStatus) in
            log.debug("Sync status for \(engineIdentifier): \(syncStatus)")

            // Explicitly call out each of the enum cases to let us lean on the compiler when
            // we add new error states
            switch syncStatus {
            case .NotStarted(let reason):
                switch reason {
                case .Offline:
                    return .Bad(message: Strings.FirefoxSyncOfflineTitle)
                case .NoAccount:
                    return .Warning(message: Strings.FirefoxSyncOfflineTitle)
                case .Backoff(_):
                    return .Good
                case .EngineRemotelyNotEnabled(_):
                    return .Good
                case .EngineFormatOutdated(_):
                    return .Good
                case .EngineFormatTooNew(_):
                    return .Good
                case .StorageFormatOutdated(_):
                    return .Good
                case .StorageFormatTooNew(_):
                    return .Good
                case .StateMachineNotReady:
                    return .Good
                case .RedLight:
                    return .Good
                case .Unknown:
                    return .Good
                }
            case .Completed:
                return .Good
            case .Partial:
                return .Good
            }
        }

        // TODO: Instead of finding the worst offender in a list of statuses, we should better surface
        // what might have happened with a particular engine when syncing.
        let aggregate: SyncDisplayState = displayStates.reduce(.Good) { carried, displayState in
            switch displayState {

            case .Bad(_):
                return displayState

            case .Warning(_):
                // If the state we're carrying is worse than the stale one, keep passing
                // along the worst one
                switch carried {
                case .Bad(_):
                    return carried
                default:
                    return displayState
                }
            default:
                // This one is good so just pass on what was being carried
                return carried
            }
        }

        log.debug("Resolved sync display state: \(aggregate)")
        return aggregate
    }
}
