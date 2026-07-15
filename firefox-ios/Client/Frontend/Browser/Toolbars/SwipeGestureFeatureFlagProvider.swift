// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

struct SwipeGestureFeatureFlagProvider {
    let featureFlagsProvider: FeatureFlagProviding

    // Defaults to the container-resolved provider; tests inject a mock instead.
    init(featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve()) {
        self.featureFlagsProvider = featureFlagsProvider
    }

    /// The interactive gesture is disabled when the swipe variant is enabled, since
    /// `enabled_swipe` overrides the interactive gesture.
    var isInteractiveGestureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTrayInteractive)
            && !featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTraySwipe)
    }

    var isSwipeGestureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTraySwipe)
    }

    /// Whether the interactive gesture supports closing tab too.
    var isCloseTabEnabled: Bool {
        return featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTrayCloseTab)
    }

    var isAnyGestureEnabled: Bool {
        return isInteractiveGestureEnabled || isSwipeGestureEnabled
    }
}
