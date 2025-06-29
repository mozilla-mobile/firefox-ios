/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Glean

open class SyncManagerComponent {
    private var api: SyncManager

    public init() {
        api = SyncManager()
    }

    public func disconnect() {
        api.disconnect()
    }

    public func sync(params: SyncParams) throws -> SyncResult {
        return try api.sync(params: params)
    }

    public func getAvailableEngines() -> [String] {
        return api.getAvailableEngines()
    }

    public static func reportSyncTelemetry(syncResult: SyncResult) throws {
        if let json = syncResult.telemetryJson {
            let telemetry = try RustSyncTelemetryPing.fromJSONString(jsonObjectText: json)
            try processSyncTelemetry(syncTelemetry: telemetry)
        }
    }

    public static func reportOpenSyncSettingsMenuTelemetry() {
        GleanMetrics.SyncSettings.openMenu.record()
    }

    public static func reportSaveSyncSettingsTelemetry(enabledEngines: [String], disabledEngines: [String]) {
        let enabledList = enabledEngines.isEmpty ? nil : enabledEngines.joined(separator: ",")
        let disabledList = disabledEngines.isEmpty ? nil : disabledEngines.joined(separator: ",")
        let extras = GleanMetrics.SyncSettings.SaveExtra(disabledEngines: disabledList, enabledEngines: enabledList)

        GleanMetrics.SyncSettings.save.record(extras)
    }
}
