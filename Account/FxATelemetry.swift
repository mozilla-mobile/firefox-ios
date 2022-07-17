// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import SyncTelemetry

open class FxATelemetry {
    /// Parses a JSON blob returned from `FxAccountManager#parseTelemetry()`
    /// into a list of events that can be recorded into prefs, and then
    /// included in the next Sync ping. Ignores malformed and unknown events.
    public static func parseTelemetry(fromJSONString string: String) -> [Event] {
        guard let data = string.data(using: .utf8) else { return [] }

        var telemetry: Telemetry?
        do {
            telemetry = try JSONDecoder().decode(Telemetry.self, from: data)
        } catch {
            print("Unable to decode telemetry: \(error)")
        }

        guard let telemetry = telemetry else { return [] }

        return telemetry.commandsReceived + telemetry.commandsSent
    }
}
