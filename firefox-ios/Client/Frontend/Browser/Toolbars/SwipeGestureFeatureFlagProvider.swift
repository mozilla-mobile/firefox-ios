// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

public struct SwipeGestureFeatureFlagProvider: FeatureFlaggable {
    /// The interactive gesture is disabled when the swipe variant is enabled, since
    /// `enabled_swipe` overrides the interactive gesture.
    public var isInteractiveGestureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTrayInteractive)
            && !featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTraySwipe)
    }
    public var isSwipeGestureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTraySwipe)
    }
    /// Whether the interactive gesture supports closing tab too.
    public var isCloseTabEnabled: Bool {
        return featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTrayCloseTab)
    }
    public var isAnyGestureEnabled: Bool {
        return isInteractiveGestureEnabled || isSwipeGestureEnabled
    }
}
