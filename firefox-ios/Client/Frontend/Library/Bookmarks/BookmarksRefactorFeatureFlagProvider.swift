// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol BookmarksRefactorFeatureFlagProvider {}

extension BookmarksRefactorFeatureFlagProvider {
    private var featureFlags: LegacyFeatureFlagsManager {
        return LegacyFeatureFlagsManager.shared
    }

    var isBookmarkRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.bookmarksRefactor, checking: .buildOnly)
    }
}
