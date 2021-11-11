// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import SwiftyJSON
import SyncTelemetry

open class FxATelemetry {
    /// Parses a JSON blob returned from `FxAccountManager#parseTelemetry()`
    /// into a list of events that can be recorded into prefs, and then
    /// included in the next Sync ping. Ignores malformed and unknown events.
    public static func parseTelemetry(fromJSONString string: String) -> [Event] {
        let json = JSON(parseJSON: string)
        let commandsSent = json["commands_sent"].array?.compactMap {
            sentCommand -> Event? in
                guard let flowID = sentCommand["flow_id"].string,
                    let streamID = sentCommand["stream_id"].string else {
                        return nil
                }
                let extra: [String: String] = [
                    flowID: flowID,
                    streamID: streamID,
                ]
                return Event(category: "sync",
                             method: "open-uri",
                             object: "command-sent",
                             extra: extra)
        } ?? []
        let commandsReceived = json["commands_received"].array?.compactMap {
            receivedCommand -> Event? in
                guard let flowID = receivedCommand["flow_id"].string,
                    let streamID = receivedCommand["stream_id"].string,
                    let reason = receivedCommand["reason"].string else {
                        return nil
                }
                let extra: [String: String] = [
                    flowID: flowID,
                    streamID: streamID,
                    reason: reason,
                ]
                return Event(category: "sync",
                             method: "open-uri",
                             object: "command-received",
                             extra: extra)
        } ?? []
        return commandsSent + commandsReceived
    }
}
