/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account
import Storage
import SwiftyJSON
import SyncTelemetry

fileprivate let log = Logger.syncLogger

public let PrefKeySyncEvents = "sync.telemetry.events"

public enum SyncReason: String {
    case startup = "startup"
    case scheduled = "scheduled"
    case backgrounded = "backgrounded"
    case user = "user"
    case syncNow = "syncNow"
    case didLogin = "didLogin"
    case push = "push"
    case engineEnabled = "engineEnabled"
    case clientNameChanged = "clientNameChanged"
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
            "failed": sentFailed
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

public struct ValidationStats: Stats, DictionaryRepresentable {
    let problems: [ValidationProblem]
    let took: Int64
    let checked: Int?

    public func hasData() -> Bool {
        return !problems.isEmpty
    }

    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "problems": problems.map { $0.asDictionary() },
            "took": took
        ]
        if let checked = self.checked {
            dict["checked"] = checked
        }
        return dict
    }
}

public struct ValidationProblem: DictionaryRepresentable {
    let name: String
    let count: Int

    func asDictionary() -> [String: Any] {
        return ["name": name, "count": count]
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
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "took": took,
        ]

        if downloadStats.hasData() {
            dict["incoming"] = downloadStats.asDictionary()
        }

        if uploadStats.hasData() {
            dict["outgoing"] = [uploadStats.asDictionary()]
        }

        if let validation = self.validationStats, validation.hasData() {
            dict["validation"] = validation.asDictionary()
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
    func asDictionary() -> [String: Any] {
        let whenValue = when ?? 0
        return [
            "when": whenValue,
            "took": took,
            "didLogin": didLogin,
            "why": why.rawValue
        ]
    }
}

public enum SyncPingError: MaybeErrorType {
    case failedToRestoreScratchpad

    public var description: String {
        switch self {
        case .failedToRestoreScratchpad: return "Failed to restore Scratchpad from prefs"
        }
    }
}

public enum SyncPingFailureReasonName: String {
    case httpError = "httperror"
    case unexpectedError = "unexpectederror"
    case sqlError = "sqlerror"
    case otherError = "othererror"
}

public protocol SyncPingFailureFormattable {
    var failureReasonName: SyncPingFailureReasonName { get }
}

public struct SyncPing: SyncTelemetryPing {
    public private(set) var payload: JSON

    public static func from(result: SyncOperationResult,
                            remoteClientsAndTabs: RemoteClientsAndTabs,
                            prefs: Prefs,
                            why: SyncPingReason) -> Deferred<Maybe<SyncPing>> {
        // Grab our token so we can use the hashed_fxa_uid and clientGUID from our scratchpad for
        // our ping's identifiers
        return RustFirefoxAccounts.shared.syncAuthState.token(Date.now(), canBeExpired: false) >>== { (token, kSync) in
            let scratchpadPrefs = prefs.branch("sync.scratchpad")
            guard let scratchpad = Scratchpad.restoreFromPrefs(scratchpadPrefs, syncKeyBundle: KeyBundle.fromKSync(kSync)) else {
                return deferMaybe(SyncPingError.failedToRestoreScratchpad)
            }

            var ping: [String: Any] = pingCommonData(
                why: why,
                hashedUID: token.hashedFxAUID,
                hashedDeviceID: (scratchpad.clientGUID + token.hashedFxAUID).sha256.hexEncodedString
            )

            // TODO: We don't cache our sync pings so if it fails, it fails. Once we add
            // some kind of caching we'll want to make sure we don't dump the events if
            // the ping has failed.
            let pickledEvents = prefs.arrayForKey(PrefKeySyncEvents) as? [Data] ?? []
            let events = pickledEvents.compactMap(Event.unpickle).map { $0.toArray() }
            ping["events"] = events
            prefs.setObject(nil, forKey: PrefKeySyncEvents)

            return dictionaryFrom(result: result, storage: remoteClientsAndTabs, token: token) >>== { syncDict in
                // TODO: Split the sync ping metadata from storing a single sync.
                ping["syncs"] = [syncDict]
                return deferMaybe(SyncPing(payload: JSON(ping)))
            }
        }
    }

    static func pingCommonData(why: SyncPingReason, hashedUID: String, hashedDeviceID: String) -> [String: Any] {
         return [
            "version": 1,
            "why": why.rawValue,
            "uid": hashedUID,
            "deviceID": hashedDeviceID,
            "os": [
                "name": "iOS",
                "version": UIDevice.current.systemVersion,
                "locale": Locale.current.identifier
            ]
        ]
    }

    // Generates a single sync ping payload that is stored in the 'syncs' list in the sync ping.
    private static func dictionaryFrom(result: SyncOperationResult,
                                       storage: RemoteClientsAndTabs,
                                       token: TokenServerToken) -> Deferred<Maybe<[String: Any]>> {
        return connectedDevices(fromStorage: storage, token: token) >>== { devices in
            guard let stats = result.stats else {
                return deferMaybe([String: Any]())
            }

            var dict = stats.asDictionary()
            if let engineResults = result.engineResults.successValue {
                dict["engines"] = SyncPing.enginePingDataFrom(engineResults: engineResults)
            } else if let failure = result.engineResults.failureValue {
                var errorName: SyncPingFailureReasonName
                if let formattableFailure = failure as? SyncPingFailureFormattable {
                    errorName = formattableFailure.failureReasonName
                } else {
                    errorName = .unexpectedError
                }

                dict["failureReason"] = [
                    "name": errorName.rawValue,
                    "error": "\(type(of: failure))",
                ]
            }

            dict["devices"] = devices
            return deferMaybe(dict)
        }
    }

    // Returns a list of connected devices formatted for use in the 'devices' property in the sync ping.
    private static func connectedDevices(fromStorage storage: RemoteClientsAndTabs,
                                         token: TokenServerToken) -> Deferred<Maybe<[[String: Any]]>> {
        func dictionaryFrom(client: RemoteClient) -> [String: Any]? {
            var device = [String: Any]()
            if let os = client.os {
                device["os"] = os
            }
            if let version = client.version {
                device["version"] = version
            }
            if let guid = client.guid {
                device["id"] = (guid + token.hashedFxAUID).sha256.hexEncodedString
            }
            return device
        }

        return storage.getClients() >>== { deferMaybe($0.compactMap(dictionaryFrom)) }
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
