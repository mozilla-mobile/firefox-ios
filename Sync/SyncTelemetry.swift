/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account
import SwiftyJSON
import Telemetry

fileprivate let log = Logger.syncLogger

public enum SyncReason: String {
    case startup = "startup"
    case scheduled = "scheduled"
    case backgrounded = "backgrounded"
    case user = "user"
    case syncNow = "syncNow"
    case didLogin = "didLogin"
    case push = "push"
}

public enum SyncPingReason: String {
    case shutdown = "shutdown"
    case schedule = "schedule"
    case idChanged = "idchanged"
}

public protocol Stats {
    func hasData() -> Bool
}

private protocol DictionaryRepresentable {
    func asDictionary() -> [String: Any]
}

public struct SyncUploadStats: Stats {
    var sent: Int = 0
    var sentFailed: Int = 0

    public func hasData() -> Bool {
        return sent > 0 || sentFailed > 0
    }
}

extension SyncUploadStats: DictionaryRepresentable {
    func asDictionary() -> [String: Any] {
        return [
            "sent": sent,
            "sentFailed": sentFailed
        ]
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

extension SyncDownloadStats: DictionaryRepresentable {
    func asDictionary() -> [String: Any] {
        return [
            "applied": applied,
            "succeeded": succeeded,
            "failed": failed,
            "newFailed": newFailed,
            "reconciled": reconciled
        ]
    }
}

// TODO(sleroux): Implement various bookmark validation issues we can run into.
public struct ValidationStats: Stats {
    public func hasData() -> Bool {
        return false
    }
}

public class StatsSession {
    var took: Int64 = 0
    var when: Timestamp?

    private var startUptimeNanos: UInt64?

    public func start(when: UInt64 = Date.now()) {
        self.when = when
        self.startUptimeNanos = DispatchTime.now().uptimeNanoseconds
    }

    public func hasStarted() -> Bool {
        return startUptimeNanos != nil
    }

    public func end() -> Self {
        guard let startUptime = startUptimeNanos else {
            assertionFailure("SyncOperationStats called end without first calling start!")
            return self
        }

        // Casting to Int64 should be safe since we're using uptime since boot in both cases.
        // Convert to milliseconds as stated in the sync ping format
        took = (Int64(DispatchTime.now().uptimeNanoseconds) - Int64(startUptime)) / 1000000
        return self
    }
}

// Stats about a single engine's sync.
public class SyncEngineStatsSession: StatsSession {
    public var failureReason: Any?
    public var validationStats: ValidationStats?

    private(set) var uploadStats: SyncUploadStats
    private(set) var downloadStats: SyncDownloadStats

    public init(collection: String) {
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

extension SyncEngineStatsSession: DictionaryRepresentable {
    func asDictionary() -> [String : Any] {
        var dict: [String: Any] = [
            "took": took,
        ]

        if downloadStats.hasData() {
            dict["incoming"] = downloadStats.asDictionary()
        }

        if uploadStats.hasData() {
            dict["outgoing"] = uploadStats.asDictionary()
        }

        return dict
    }
}

// Stats and metadata for a sync operation.
public class SyncOperationStatsSession: StatsSession {
    public let why: SyncReason
    public var uid: String?
    public var deviceID: String?

    fileprivate let didLogin: Bool

    public init(why: SyncReason, uid: String, deviceID: String?) {
        self.why = why
        self.uid = uid
        self.deviceID = deviceID
        self.didLogin = (why == .didLogin)
    }
}

extension SyncOperationStatsSession: DictionaryRepresentable {
    func asDictionary() -> [String : Any] {
        let whenValue = when ?? 0
        return [
            "when": whenValue,
            "took": took,
            "didLogin": didLogin,
            "why": why.rawValue
        ]
    }
}

public struct SyncPing: TelemetryPing {
    public var payload: JSON

    public init(account: FirefoxAccount?, why: SyncPingReason, syncOperationResult: SyncOperationResult) {
        var ping: [String: Any] = [
            "version": 1,
            "why": why.rawValue,
            "uid": account?.uid ?? String(repeating: "0", count: 32)
        ]

        if let deviceID = account?.deviceRegistration?.id {
            ping["deviceID"] = deviceID
        }

        if let syncStats = syncOperationResult.stats {
            var singleSync = syncStats.asDictionary()
            if let engineResults = syncOperationResult.engineResults.successValue {
                singleSync["engines"] = SyncPing.enginePingDataFrom(engineResults: engineResults)
            }

            ping["syncs"] = [singleSync]
        }

        payload = JSON(ping)
    }

    private static func enginePingDataFrom(engineResults: EngineResults) -> [[String: Any]] {
        return engineResults.map { result in
            let (name, status) = result
            var engine: [String: Any] = [
                "name": name
            ]

            // For complete/partial results, extract out the collect stats
            // and add it to engine information. For syncs that were not able to
            // start, return why and a reason.
            switch status {
            case .completed(let stats):
                engine.merge(with: stats.asDictionary())
            case .partial(let stats):
                engine.merge(with: stats.asDictionary())
            case .notStarted(let reason):
                engine.merge(with: [
                    "status": reason.telemetryId
                ])
            }

            return engine
        }
    }
}
