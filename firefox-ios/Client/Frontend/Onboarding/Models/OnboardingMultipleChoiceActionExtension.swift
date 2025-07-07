// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension OnboardingMultipleChoiceAction {
    var hasDefaultSelection: Bool {
        switch self {
        case .toolbarBottom, .toolbarTop:
            return true
        default:
            return false
        }
    }

    var defaultSelectionPriority: Int {
        switch self {
        case .toolbarBottom: return 1  // Highest priority
        case .toolbarTop: return 2     // Lower priority
        default: return Int.max        // No priority
        }
    }
}
