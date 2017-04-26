/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import JSONSchema
import Telemetry

// MARK: Activity Stream
extension PingCentreTopic {

    static var ActivityStreamEvents: PingCentreTopic {
        let schema = Schema([
            "type": "object",
            "properties": [
                // AS-Specific properties
                "event": ["type": "string"],
                "page": ["type": "string"],
                "source": ["type": "string"],
                "action_position": ["type": "number"],
                "share_provider": ["type": "string"],

                // Application metadata
                "app_version": ["type": "string"],
                "build": ["type": "string"],
                "locale": ["type": "string"],
                "release_channel": ["type": "string"]
            ],
            "required": ["app_version", "build", "locale", "event", "release_channel"]
        ])

        return PingCentreTopic(name: "activity-stream-mobile-events", schema: schema)
    }

    static var ActivityStreamSessions: PingCentreTopic {
        let schema = Schema([
            "type": "object",
            "properties": [
                // AS-Specific properties
                "session_duration": ["type": "number"],

                // Application metadata
                "app_version": ["type": "string"],
                "build": ["type": "string"],
                "locale": ["type": "string"],
                "release_channel": ["type": "string"]
            ],
            "required": ["app_version", "build", "locale", "session_duration", "release_channel"]
        ])

        return PingCentreTopic(name: "activity-stream-mobile-sessions", schema: schema)
    }
}
