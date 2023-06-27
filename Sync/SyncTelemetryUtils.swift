// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Glean
import Shared
import Account
import Storage
import SwiftyJSON

public class GleanSyncOperationHelper {
    public init () {}

    public func start() {
        _ = GleanMetrics.Sync.syncUuid.generateAndSet()
    }

    public func reportTelemetry(_ result: SyncResult) {
        guard let json = result.telemetryJson,
              let telemetry = try? RustSyncTelemetryPing.fromJSONString(jsonObjectText: json)
        else { return }

        for sync in telemetry.syncs {
            _ = GleanMetrics.Sync.syncUuid.generateAndSet()

            if let reason = sync.failureReason {
                let failureReason = convertSyncFailureReason(reason: reason)
                GleanMetrics.Sync.failureReason[failureReason].add()
            }

            for engine in sync.engines {
                if engine.failureReason == nil {
                    self.recordRustSyncEngineStats(engine.name,
                                                   incoming: engine.incoming,
                                                   outgoing: engine.outgoing)
                } else if let reason = engine.failureReason {
                    let reason = convertEngineFailureReason(reason: reason)
                    self.recordSyncEngineFailure(
                        engine.name,
                        reason)
                }

                self.submitSyncEnginePing(engine.name)
            }

            GleanMetrics.Pings.shared.tempSync.submit()
        }
    }

    public func convertSyncFailureReason(reason: FailureReason) -> String {
        // The metrics.yaml for the temp sync metrics specifies the failure reasons
        // (`httperror`, `unexpectederror`, `sqlerror`, and `othererror`) associated with
        // the old sync manager. To prevent the rust sync manager failure reasons from
        // being omitted, we map them to the old values. This is a stopgap measure as work
        // has already begun to replace the sync temp metrics entirely.

        switch reason.name {
        case .http:
            return "httperror"
        case .other, .shutdown, .auth, .unknown:
            return "othererror"
        case .unexpected:
            return "unexpectederror"
        }
    }

    public func convertEngineFailureReason(reason: FailureReason) -> String {
        // The metrics.yaml for the temp sync metrics specifies the failure reasons
        // (`httperror`, `unexpectederror`, `sqlerror`, and `othererror`) associated with
        // the old sync manager. They include the following reasons:
        //    - no_account
        //    - offline
        //    - backoff
        //    - remotely_not_enabled
        //    - format_outdated
        //    - format_too_new
        //    - storage_format_outdated
        //    - storage_format_too_new
        //    - state_machine_not_ready
        //    - red_light
        //    - unknown
        // To prevent the rust sync manager failure reasons from being omitted, we map
        // them to the old values. This is a stopgap measure as work has already begun to
        // replace the sync temp metrics entirely.

        switch reason.name {
        case .auth:
            return "no_account"
        case .unknown, .shutdown, .other, .unexpected, .http:
            return "unknown"
        }
    }

    private func recordRustSyncEngineStats(_ engineName: String,
                                           incoming: IncomingInfo?,
                                           outgoing: [OutgoingInfo]) {
        let incomingLabelsToValue = [
            ("applied", incoming?.applied ?? 0),
            ("reconciled", incoming?.reconciled ?? 0),
            ("failed_to_apply", incoming?.failed ?? 0)
        ].filter { (_, stat) in stat > 0 }

        let outgoingLabelsToValue = [
            ("uploaded", outgoing.reduce(0, { totalUploaded, rec in
                totalUploaded + rec.sent
            })),
            ("failed_to_upload", outgoing.reduce(0, { totalFailed, rec in
                totalFailed + rec.failed
            }))
        ].filter { (_, stat) in stat > 0 }

        switch engineName {
        case "tabs":
            incomingLabelsToValue.forEach { (l, v) in GleanMetrics.RustTabsSync.incoming[l].add(Int32(v))}
            outgoingLabelsToValue.forEach { (l, v) in GleanMetrics.RustTabsSync.outgoing[l].add(Int32(v)) }
        case "bookmarks":
            incomingLabelsToValue.forEach { (l, v) in GleanMetrics.BookmarksSync.incoming[l].add(Int32(v))}
            outgoingLabelsToValue.forEach { (l, v) in GleanMetrics.BookmarksSync.outgoing[l].add(Int32(v)) }
        case "history":
            incomingLabelsToValue.forEach { (l, v) in GleanMetrics.HistorySync.incoming[l].add(Int32(v))}
            outgoingLabelsToValue.forEach { (l, v) in GleanMetrics.HistorySync.outgoing[l].add(Int32(v)) }
        case "passwords":
            incomingLabelsToValue.forEach { (l, v) in GleanMetrics.LoginsSync.incoming[l].add(Int32(v))}
            outgoingLabelsToValue.forEach { (l, v) in GleanMetrics.LoginsSync.outgoing[l].add(Int32(v)) }
        case "clients":
            incomingLabelsToValue.forEach { (l, v) in GleanMetrics.ClientsSync.incoming[l].add(Int32(v))}
            outgoingLabelsToValue.forEach { (l, v) in GleanMetrics.ClientsSync.outgoing[l].add(Int32(v)) }
        case "creditcards":
            incomingLabelsToValue.forEach { (l, v) in GleanMetrics.CreditCardsSync.incoming[l].add(Int32(v))}
            outgoingLabelsToValue.forEach { (l, v) in GleanMetrics.CreditCardsSync.outgoing[l].add(Int32(v)) }
        default:
            break
        }
    }

    private func recordSyncEngineFailure(_ engineName: String, _ reason: String) {
        let correctedReson = String(reason.dropFirst("sync.not_started.reason.".count))

        switch engineName {
        case "tabs": GleanMetrics.RustTabsSync.failureReason[correctedReson].add()
        case "bookmarks": GleanMetrics.BookmarksSync.failureReason[correctedReson].add()
        case "history": GleanMetrics.HistorySync.failureReason[correctedReson].add()
        case "logins", "passwords": GleanMetrics.LoginsSync.failureReason[correctedReson].add()
        case "clients": GleanMetrics.ClientsSync.failureReason[correctedReson].add()
        case "creditcards": GleanMetrics.CreditCardsSync.failureReason[correctedReson].add()
        default:
            break
        }
    }

    private func submitSyncEnginePing(_ engineName: String) {
        switch engineName {
        case "tabs": GleanMetrics.Pings.shared.tempRustTabsSync.submit()
        case "bookmarks": GleanMetrics.Pings.shared.tempBookmarksSync.submit()
        case "history": GleanMetrics.Pings.shared.tempHistorySync.submit()
        case "logins", "passwords": GleanMetrics.Pings.shared.tempLoginsSync.submit()
        case "clients": GleanMetrics.Pings.shared.tempClientsSync.submit()
        case "creditcards": GleanMetrics.Pings.shared.tempCreditCardsSync.submit()
        default:
            break
        }
    }
}
