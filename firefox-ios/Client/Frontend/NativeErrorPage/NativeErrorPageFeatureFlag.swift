// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct NativeErrorPageFeatureFlag: FeatureFlaggable {
    var isNativeErrorPageEnabled: Bool {
        return featureFlags.isFeatureEnabled(.nativeErrorPage, checking: .buildOnly)
    }

    /// Temporary flag for showing no internet connection native error page only.
    var isNICErrorPageEnabled: Bool {
        return featureFlags.isFeatureEnabled(.nativeErrorPage, checking: .buildOnly) &&
            featureFlags.isFeatureEnabled(.noInternetConnectionErrorPage, checking: .buildOnly)
    }

    /// Flag for showing other native error pages 
    var isOtherErrorPagesEnabled: Bool {
        return featureFlags.isFeatureEnabled(.otherErrorPages, checking: .buildOnly)
    }
}
