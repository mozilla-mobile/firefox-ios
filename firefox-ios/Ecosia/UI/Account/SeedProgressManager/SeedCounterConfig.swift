// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct SeedCounterConfig {
    let sparklesAnimationDuration: Double
    let maxCappedLevel: Int?  // Optional field to cap the level as part of the experiment
    let maxCappedSeeds: Int? // Optional field to cap the total seeds as part of the experiment
    let levels: [SeedLevel]

    struct SeedLevel: Codable {
        let level: Int
        let requiredSeeds: Int
    }
}

extension SeedCounterConfig: Decodable {}
