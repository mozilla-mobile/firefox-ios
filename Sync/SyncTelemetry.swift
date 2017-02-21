/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account

fileprivate let log = Logger.syncLogger

public enum SyncReason: String {
    case startup = "startup"
    case scheduled = "scheduled"
    case backgrounded = "backgrounded"
    case user = "user"
    case syncNow = "syncNow"
    case didLogin = "didLogin"
}

public protocol Stats {
    func hasData() -> Bool
}

public struct SyncUploadStats: Stats {
    var sent: Int = 0
    var sentFailed: Int = 0

    public func hasData() -> Bool {
        return sent > 0 || sentFailed > 0
    }
}

public struct SyncDownloadStats: Stats {
    var applied: Int = 0
    var succeeded: Int = 0
    var failed: Int = 0
    var newFailed: Int = 0
    var reconciled: Int = 0

    public func hasData() -> Bool {
        return applied > 0 ||
               succeeded > 0 ||
               failed > 0 ||
               newFailed > 0 ||
               reconciled > 0
    }
}

// TODO(sleroux): Implement various bookmark validation issues we can run into
public struct ValidationStats: Stats {
    public func hasData() -> Bool {
        return false
    }
}

public class StatsSession {
    private var took: UInt64 = 0
    private var startUptime: UInt64?

    public func start(uptime: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        self.startUptime = uptime
    }

    public func hasStarted() -> Bool {
        return startUptime != nil
    }

    public func end() -> Self {
        guard let startUptime = startUptime else {
            assertionFailure("SyncOperationStats called end without first calling start!")
            return self
        }

        // Check for potential clock issues to prevent an overflow if our end time is before our start time.
        let (diff, overflowed) = UInt64.subtractWithOverflow(DispatchTime.now().uptimeNanoseconds, startUptime)
        if overflowed {
            log.error("Start uptime is less than end uptime! Setting took to 0.")
            took = 0
        } else {
            // Round to milleseconds
            took = diff / 1000000
        }
        return self
    }
}

// Stats about a single engine's sync
public class SyncEngineStatsSession: StatsSession {
    public let collection: String
    public var failureReason: Any?
    public var validationStats: ValidationStats?

    private(set) var uploadStats: SyncUploadStats
    private(set) var downloadStats: SyncDownloadStats

    public init(collection: String) {
        self.collection = collection
        self.uploadStats = SyncUploadStats()
        self.downloadStats = SyncDownloadStats()
    }

    public func recordDownload(stats: SyncDownloadStats) {
        self.downloadStats.applied += stats.applied
        self.downloadStats.succeeded += stats.succeeded
        self.downloadStats.failed += stats.failed
        self.downloadStats.newFailed += stats.newFailed
        self.downloadStats.reconciled += stats.reconciled
    }

    public func recordUpload(stats: SyncUploadStats) {
        self.uploadStats.sent += stats.sent
        self.uploadStats.sentFailed += stats.sentFailed
    }
}

// Stats and metadata for a sync operation
public class SyncOperationStatsSession: StatsSession {
    public let why: SyncReason
    public var uid: String?
    public var deviceID: String?

    private let didLogin: Bool

    public init(why: SyncReason, uid: String, deviceID: String?) {
        self.why = why
        self.uid = uid
        self.deviceID = deviceID
        self.didLogin = (why == .didLogin)
    }
}
