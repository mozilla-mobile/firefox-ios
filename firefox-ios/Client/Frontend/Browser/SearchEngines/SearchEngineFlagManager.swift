// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

struct SearchEngineFlagManager {
    /// Whether Search Engine Consolidation is enabled.
    /// If enabled, search engines are fetched from Remote Settings rather than our pre-bundled XML files.
    static var isSECEnabled: Bool {
        guard !AppConstants.isRunningUnitTest else { return false }
        return LegacyFeatureFlagsManager.shared.isFeatureEnabled(.searchEngineConsolidation, checking: .buildOnly)
    }
}
