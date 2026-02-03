// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import CopyWithUpdates

// This file contains a simple executable demo of the CopyWithUpdates macro.
@CopyWithUpdates
struct Report {
    let venue: String
    let sponsor: String?
    let drinks: [String]
    let complexStructure: [Date: [(String, Int)]]
    let characters: [String]?
    let budget: Double
}

let r1 = Report(
    venue: "Grapefruit",
    sponsor: "Oumaouma",
    drinks: ["soda", "tea"],
    complexStructure: [Date(): [("Blunt!", 200)]],
    characters: [],
    budget: 12_345_678.9
)

let r2 = r1.copyWithUpdates(
    characters: ["Jane Doe"]
)

let r3 = r1.copyWithUpdates(
    sponsor: nil,
    complexStructure: [:],
    budget: 0
)
