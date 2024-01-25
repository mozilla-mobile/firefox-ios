// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

enum SearchSettingsAction: Action {
    // UI trigger actions
    case searchSettingsDidLoad
    case toggleSearchSuggestions(Bool)
    var windowUUID: UUID? {
        // TODO: [8188] Revisit UUIDs here.
        switch self {
        default: return nil
        }
    }
}
