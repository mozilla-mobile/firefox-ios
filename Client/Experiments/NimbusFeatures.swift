// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

/// This file contains configuration objects for application features that can be configured with Nimbus.
/// Eventually, this file may be auto-generated.

import Foundation
import MozillaAppServices

// This struct is populated from JSON coming from nimbus, with for `homescreen`
// feature id. The default values (i.e. user isn't enrolled in an experiment, or
// nimbus is unavailable can be represented in JSON like so:
//
// ```json
// {
//    "sections-enabled": {
//        "topSites": true,
//        "jumpBackIn": false,
//        "recentlySaved": false,
//        "pocket": false,
//        "libraryShortcuts": true,
//    }
// }
// ```
struct Homescreen {
    enum SectionId: String, CaseIterable {
        case topSites
        case jumpBackIn
        case recentlySaved
        case pocket
        case libraryShortcuts

        // The section as enabled if the Nimbus hasn't loaded, or the user
        // is not in an experiment or rollout.
        // This should be as-if MR2 is not enabled.
        var defaultValue: Bool {
            switch self {
            case .topSites: return true
            case .jumpBackIn: return false
            case .recentlySaved: return false
            case .pocket: return true
            case .libraryShortcuts: return true
            }
        }
    }

    // A dictionary of flags enabling the sections on the user's homescreen.
    // If the entry for a given key is missing, it is filled in with the defaults
    // listed in the `SectionId` enum.
    lazy var sectionsEnabled: [SectionId: Bool] = {
        var map: [SectionId: Bool] = variables.getBoolMap("sections-enabled")?.compactMapKeysAsEnums() ?? [:]
        for id in SectionId.allCases {
            map[id] = map[id] ?? id.defaultValue
        }
        return map
    }()

    init(variables: Variables) {
        self.variables = variables
    }
    // Variables is a thin wrapper around a JSON object.
    private let variables: Variables
}
