// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Compile-time build channel checks. No instance needed.
///
/// These are features that are used for developer purposes and are
/// not directly user impacting, which is why these should be kept
/// separate from other feature flags
enum CoreBuildFlags {
    static var isAdjustEnvironmentProd: Bool {
        #if MOZ_CHANNEL_release || MOZ_CHANNEL_beta
        return true
        #else
        return false
        #endif
    }

    static var isUsingMockData: Bool {
        #if MOZ_CHANNEL_developer
        return true
        #else
        return false
        #endif
    }

    static var isUsingStagingUnifiedAdsAPI: Bool {
        #if MOZ_CHANNEL_developer
        return true
        #else
        return false
        #endif
    }
}
