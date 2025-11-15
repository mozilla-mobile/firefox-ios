// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

struct SearchEngineFlagManager {
    /// Whether Search Engine Consolidation is enabled.
    /// If enabled, search engines are fetched from Remote Settings rather than our pre-bundled XML files.
    /// TODO: [FXIOS-13834 & 11403] Remove hardcoded override once UI & unit tests are updated (or deleted)
    static var isSECEnabled: Bool {
        // If you want to disable during unit tests, do it here:
        if AppConstants.isRunningUnitTest {
            return false
        }
        // SEC enabled for all users. Related clean-up forthcoming in [FXIOS-11403].
        return true
    }
}
