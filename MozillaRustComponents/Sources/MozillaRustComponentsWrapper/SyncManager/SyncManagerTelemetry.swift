/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Glean

typealias SyncMetrics = GleanMetrics.SyncV2
typealias LoginsMetrics = GleanMetrics.LoginsSyncV2
typealias BookmarksMetrics = GleanMetrics.BookmarksSyncV2
typealias HistoryMetrics = GleanMetrics.HistorySyncV2
typealias CreditcardsMetrics = GleanMetrics.CreditcardsSyncV2
typealias TabsMetrics = GleanMetrics.TabsSyncV2

enum SupportedEngines: String {
    case History = "history"
    case Bookmarks = "bookmarks"
    case Logins = "passwords"
    case CreditCards = "creditcards"
    case Tabs = "tabs"
}

enum TelemetryReportingError: Error {
    case InvalidEngine(message: String)
    case UnsupportedEngine(message: String)
}

func processSyncTelemetry(syncTelemetry: RustSyncTelemetryPing,
                          submitGlobalPing: (NoReasonCodes?) -> Void = GleanMetrics.Pings.shared.sync.submit,
                          submitHistoryPing: (NoReasonCodes?) -> Void = GleanMetrics.Pings.shared.historySync.submit,
                          submitBookmarksPing: (NoReasonCodes?) -> Void
                              = GleanMetrics.Pings.shared.bookmarksSync.submit,
                          submitLoginsPing: (NoReasonCodes?) -> Void
                              = GleanMetrics.Pings.shared.loginsSync.submit,
                          submitCreditCardsPing: (NoReasonCodes?) -> Void
                              = GleanMetrics.Pings.shared.creditcardsSync.submit,
                          submitTabsPing: (NoReasonCodes?) -> Void = GleanMetrics.Pings.shared.tabsSync.submit) throws
{
    for syncInfo in syncTelemetry.syncs {
        _ = SyncMetrics.syncUuid.generateAndSet()

        if let failureReason = syncInfo.failureReason {
            recordFailureReason(reason: failureReason,
                                failureReasonMetric: SyncMetrics.failureReason)
        }

        for engineInfo in syncInfo.engines {
            switch engineInfo.name {
            case SupportedEngines.Bookmarks.rawValue:
                try individualBookmarksSync(hashedFxaUid: syncTelemetry.uid,
                                            engineInfo: engineInfo)
                submitBookmarksPing(nil)
            case SupportedEngines.History.rawValue:
                try individualHistorySync(hashedFxaUid: syncTelemetry.uid,
                                          engineInfo: engineInfo)
                submitHistoryPing(nil)
            case SupportedEngines.Logins.rawValue:
                try individualLoginsSync(hashedFxaUid: syncTelemetry.uid,
                                         engineInfo: engineInfo)
                submitLoginsPing(nil)
            case SupportedEngines.CreditCards.rawValue:
                try individualCreditCardsSync(hashedFxaUid: syncTelemetry.uid,
                                              engineInfo: engineInfo)
                submitCreditCardsPing(nil)
            case SupportedEngines.Tabs.rawValue:
                try individualTabsSync(hashedFxaUid: syncTelemetry.uid,
                                       engineInfo: engineInfo)
                submitTabsPing(nil)
            default:
                let message = "Ignoring telemetry for engine \(engineInfo.name)"
                throw TelemetryReportingError.UnsupportedEngine(message: message)
            }
        }
        submitGlobalPing(nil)
    }
}

private func individualLoginsSync(hashedFxaUid: String, engineInfo: EngineInfo) throws {
    guard engineInfo.name == SupportedEngines.Logins.rawValue else {
        let message = "Expected 'passwords', got \(engineInfo.name)"
        throw TelemetryReportingError.InvalidEngine(message: message)
    }

    let base = BaseGleanSyncPing.fromEngineInfo(uid: hashedFxaUid, info: engineInfo)
    LoginsMetrics.uid.set(base.uid)
    LoginsMetrics.startedAt.set(base.startedAt)
    LoginsMetrics.finishedAt.set(base.finishedAt)

    if base.applied > 0 {
        LoginsMetrics.incoming["applied"].add(base.applied)
    }

    if base.failedToApply > 0 {
        LoginsMetrics.incoming["failed_to_apply"].add(base.failedToApply)
    }

    if base.reconciled > 0 {
        LoginsMetrics.incoming["reconciled"].add(base.reconciled)
    }

    if base.uploaded > 0 {
        LoginsMetrics.outgoing["uploaded"].add(base.uploaded)
    }

    if base.failedToUpload > 0 {
        LoginsMetrics.outgoing["failed_to_upload"].add(base.failedToUpload)
    }

    if base.outgoingBatches > 0 {
        LoginsMetrics.outgoingBatches.add(base.outgoingBatches)
    }

    if let reason = base.failureReason {
        recordFailureReason(reason: reason,
                            failureReasonMetric: LoginsMetrics.failureReason)
    }
}

private func individualBookmarksSync(hashedFxaUid: String, engineInfo: EngineInfo) throws {
    guard engineInfo.name == SupportedEngines.Bookmarks.rawValue else {
        let message = "Expected 'bookmarks', got \(engineInfo.name)"
        throw TelemetryReportingError.InvalidEngine(message: message)
    }

    let base = BaseGleanSyncPing.fromEngineInfo(uid: hashedFxaUid, info: engineInfo)
    BookmarksMetrics.uid.set(base.uid)
    BookmarksMetrics.startedAt.set(base.startedAt)
    BookmarksMetrics.finishedAt.set(base.finishedAt)

    if base.applied > 0 {
        BookmarksMetrics.incoming["applied"].add(base.applied)
    }

    if base.failedToApply > 0 {
        BookmarksMetrics.incoming["failed_to_apply"].add(base.failedToApply)
    }

    if base.reconciled > 0 {
        BookmarksMetrics.incoming["reconciled"].add(base.reconciled)
    }

    if base.uploaded > 0 {
        BookmarksMetrics.outgoing["uploaded"].add(base.uploaded)
    }

    if base.failedToUpload > 0 {
        BookmarksMetrics.outgoing["failed_to_upload"].add(base.failedToUpload)
    }

    if base.outgoingBatches > 0 {
        BookmarksMetrics.outgoingBatches.add(base.outgoingBatches)
    }

    if let reason = base.failureReason {
        recordFailureReason(reason: reason,
                            failureReasonMetric: BookmarksMetrics.failureReason)
    }

    if let validation = engineInfo.validation {
        for problemInfo in validation.problems {
            BookmarksMetrics.remoteTreeProblems[problemInfo.name].add(Int32(problemInfo.count))
        }
    }
}

private func individualHistorySync(hashedFxaUid: String, engineInfo: EngineInfo) throws {
    guard engineInfo.name == SupportedEngines.History.rawValue else {
        let message = "Expected 'history', got \(engineInfo.name)"
        throw TelemetryReportingError.InvalidEngine(message: message)
    }

    let base = BaseGleanSyncPing.fromEngineInfo(uid: hashedFxaUid, info: engineInfo)
    HistoryMetrics.uid.set(base.uid)
    HistoryMetrics.startedAt.set(base.startedAt)
    HistoryMetrics.finishedAt.set(base.finishedAt)

    if base.applied > 0 {
        HistoryMetrics.incoming["applied"].add(base.applied)
    }

    if base.failedToApply > 0 {
        HistoryMetrics.incoming["failed_to_apply"].add(base.failedToApply)
    }

    if base.reconciled > 0 {
        HistoryMetrics.incoming["reconciled"].add(base.reconciled)
    }

    if base.uploaded > 0 {
        HistoryMetrics.outgoing["uploaded"].add(base.uploaded)
    }

    if base.failedToUpload > 0 {
        HistoryMetrics.outgoing["failed_to_upload"].add(base.failedToUpload)
    }

    if base.outgoingBatches > 0 {
        HistoryMetrics.outgoingBatches.add(base.outgoingBatches)
    }

    if let reason = base.failureReason {
        recordFailureReason(reason: reason,
                            failureReasonMetric: HistoryMetrics.failureReason)
    }
}

private func individualCreditCardsSync(hashedFxaUid: String, engineInfo: EngineInfo) throws {
    guard engineInfo.name == SupportedEngines.CreditCards.rawValue else {
        let message = "Expected 'creditcards', got \(engineInfo.name)"
        throw TelemetryReportingError.InvalidEngine(message: message)
    }

    let base = BaseGleanSyncPing.fromEngineInfo(uid: hashedFxaUid, info: engineInfo)
    CreditcardsMetrics.uid.set(base.uid)
    CreditcardsMetrics.startedAt.set(base.startedAt)
    CreditcardsMetrics.finishedAt.set(base.finishedAt)

    if base.applied > 0 {
        CreditcardsMetrics.incoming["applied"].add(base.applied)
    }

    if base.failedToApply > 0 {
        CreditcardsMetrics.incoming["failed_to_apply"].add(base.failedToApply)
    }

    if base.reconciled > 0 {
        CreditcardsMetrics.incoming["reconciled"].add(base.reconciled)
    }

    if base.uploaded > 0 {
        CreditcardsMetrics.outgoing["uploaded"].add(base.uploaded)
    }

    if base.failedToUpload > 0 {
        CreditcardsMetrics.outgoing["failed_to_upload"].add(base.failedToUpload)
    }

    if base.outgoingBatches > 0 {
        CreditcardsMetrics.outgoingBatches.add(base.outgoingBatches)
    }

    if let reason = base.failureReason {
        recordFailureReason(reason: reason,
                            failureReasonMetric: CreditcardsMetrics.failureReason)
    }
}

private func individualTabsSync(hashedFxaUid: String, engineInfo: EngineInfo) throws {
    guard engineInfo.name == SupportedEngines.Tabs.rawValue else {
        let message = "Expected 'tabs', got \(engineInfo.name)"
        throw TelemetryReportingError.InvalidEngine(message: message)
    }

    let base = BaseGleanSyncPing.fromEngineInfo(uid: hashedFxaUid, info: engineInfo)
    TabsMetrics.uid.set(base.uid)
    TabsMetrics.startedAt.set(base.startedAt)
    TabsMetrics.finishedAt.set(base.finishedAt)

    if base.applied > 0 {
        TabsMetrics.incoming["applied"].add(base.applied)
    }

    if base.failedToApply > 0 {
        TabsMetrics.incoming["failed_to_apply"].add(base.failedToApply)
    }

    if base.reconciled > 0 {
        TabsMetrics.incoming["reconciled"].add(base.reconciled)
    }

    if base.uploaded > 0 {
        TabsMetrics.outgoing["uploaded"].add(base.uploaded)
    }

    if base.failedToUpload > 0 {
        TabsMetrics.outgoing["failed_to_upload"].add(base.failedToUpload)
    }

    if base.outgoingBatches > 0 {
        TabsMetrics.outgoingBatches.add(base.outgoingBatches)
    }

    if let reason = base.failureReason {
        recordFailureReason(reason: reason,
                            failureReasonMetric: TabsMetrics.failureReason)
    }
}

private func recordFailureReason(reason: FailureReason,
                                 failureReasonMetric: LabeledMetricType<StringMetricType>)
{
    let metric: StringMetricType? = {
        switch reason.name {
        case .other, .unknown:
            return failureReasonMetric["other"]
        case .unexpected, .http:
            return failureReasonMetric["unexpected"]
        case .auth:
            return failureReasonMetric["auth"]
        case .shutdown:
            return nil
        }
    }()

    let MAX_FAILURE_REASON_LENGTH = 100 // Maximum length for Glean labeled strings
    let message = reason.message ?? "Unexpected error: \(reason.code)"
    metric?.set(String(message.prefix(MAX_FAILURE_REASON_LENGTH)))
}

class BaseGleanSyncPing {
    static let MILLIS_PER_SEC: Int64 = 1000

    var uid: String
    var startedAt: Date
    var finishedAt: Date
    var applied: Int32
    var failedToApply: Int32
    var reconciled: Int32
    var uploaded: Int32
    var failedToUpload: Int32
    var outgoingBatches: Int32
    var failureReason: FailureReason?

    init(uid: String,
         startedAt: Date,
         finishedAt: Date,
         applied: Int32,
         failedToApply: Int32,
         reconciled: Int32,
         uploaded: Int32,
         failedToUpload: Int32,
         outgoingBatches: Int32,
         failureReason: FailureReason? = nil)
    {
        self.uid = uid
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.applied = applied
        self.failedToApply = failedToApply
        self.reconciled = reconciled
        self.uploaded = uploaded
        self.failedToUpload = failedToUpload
        self.outgoingBatches = outgoingBatches
        self.failureReason = failureReason
    }

    static func fromEngineInfo(uid: String, info: EngineInfo) -> BaseGleanSyncPing {
        let failedToApply = (info.incoming?.failed ?? 0) + (info.incoming?.newFailed ?? 0)
        let (uploaded, failedToUpload) = info.outgoing.reduce((0, 0)) { totals, batch in
            let (totalSent, totalFailed) = totals
            return (totalSent + batch.sent, totalFailed + batch.failed)
        }
        let startedAt = info.at * MILLIS_PER_SEC
        let ping = BaseGleanSyncPing(uid: uid,
                                     startedAt: Date(timeIntervalSince1970: TimeInterval(startedAt)),
                                     finishedAt: Date(timeIntervalSince1970: TimeInterval(startedAt + info.took)),
                                     applied: Int32(info.incoming?.applied ?? 0),
                                     failedToApply: Int32(failedToApply),
                                     reconciled: Int32(info.incoming?.reconciled ?? 0),
                                     uploaded: Int32(uploaded),
                                     failedToUpload: Int32(failedToUpload),
                                     outgoingBatches: Int32(info.outgoing.count),
                                     failureReason: info.failureReason)

        return ping
    }
}
