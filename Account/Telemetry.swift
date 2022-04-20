//
// Created by Michael Pace on 4/3/22.
// Copyright (c) 2022 Mozilla. All rights reserved.
//

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
