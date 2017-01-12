/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import JSONSchema

/*
 * A Ping Centre Topic has a name and an associated JSON schema describing the ping data.
 */
public struct PingCentreTopic {
    public let name: String
    public let schema: Schema
}

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
                "locale": ["type": "string"]
            ],
            "required": ["app_version", "build", "locale", "event"]
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
                "locale": ["type": "string"]
            ],
            "required": ["app_version", "build", "locale", "session_duration"]
        ])

        return PingCentreTopic(name: "activity-stream-mobile-sessions", schema: schema)
    }
}
