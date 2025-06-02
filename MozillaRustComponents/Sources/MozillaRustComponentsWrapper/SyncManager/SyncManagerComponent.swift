/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

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
}
