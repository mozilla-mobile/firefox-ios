// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Provider for all feature flags related to native error pages. We should only
/// use this to check if a native error page feature is enabled.
struct NativeErrorPageFeatureFlag: FeatureFlaggable {
    var isNativeErrorPageEnabled: Bool {
        return featureFlagsProvider.isEnabled(.nativeErrorPage)
    }

    var isNICErrorPageEnabled: Bool {
        return featureFlagsProvider.isEnabled(.nativeErrorPage) &&
               featureFlagsProvider.isEnabled(.noInternetConnectionErrorPage)
    }

    var isBadCertDomainErrorPageEnabled: Bool {
        return featureFlagsProvider.isEnabled(.nativeErrorPage) &&
               featureFlagsProvider.isEnabled(.badCertDomainErrorPage)
    }

    var isWaybackEnabled: Bool {
        return featureFlagsProvider.isEnabled(.nativeErrorPage) &&
               featureFlagsProvider.isEnabled(.waybackMachine)
    }
}
