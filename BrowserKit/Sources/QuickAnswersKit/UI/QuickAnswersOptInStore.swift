// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Persists the user's consent for the Quick Answers feature.
struct QuickAnswersOptInStore {
    private let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    /// Whether the user has accepted the Quick Answers opt-in.
    var isOptInCompleted: Bool {
        return prefs.boolForKey(PrefsKeys.QuickAnswers.optInCompleted) ?? false
    }

    /// Marks the Quick Answers opt-in as completed.
    func setOptInCompleted() {
        prefs.setBool(true, forKey: PrefsKeys.QuickAnswers.optInCompleted)
    }
}
