// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import SyncTelemetry

struct Telemetry: Decodable {
    enum CodingKeys: String, CodingKey {
        case commandsSent = "commands_sent"
        case commandsReceived = "commands_received"
    }

    let commandsSent: [Event]
    let commandsReceived: [Event]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        commandsSent = try values.decode([Event].self, forKey: .commandsSent)
        commandsReceived = try values.decode([Event].self, forKey: .commandsReceived)
    }
}
