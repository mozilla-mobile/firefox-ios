// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

/// TODO: Temporarily used in Reducer side will be moved to View side next
/// Builds the address bar's back/forward buttons, shown only when the navigation toolbar is
/// hidden (e.g. compact layout). Every input is already resolved by `AddressBarState`, so
/// there's nothing here to persist across dispatches. `backAction`/`forwardAction` are also
/// reused directly by `NavigationBarState` for the navigation toolbar's own back/forward buttons.
enum NavigationActionsBuilder {
    static func getActions(isShowingNavigationToolbar: Bool,
                           canGoBack: Bool,
                           canGoForward: Bool) -> [ToolbarActionConfiguration] {
        guard !isShowingNavigationToolbar else { return [] }
        return [
            backAction(enabled: canGoBack),
            forwardAction(enabled: canGoForward)
        ]
    }

    // MARK: - Helper
    static func backAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.chevronLeft,
            isFlippedForRTL: true,
            isEnabled: enabled,
            contextualHintType: ContextualHintType.navigation.rawValue,
            a11yLabel: .TabToolbarBackAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.backButton)
    }

    static func forwardAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .forward,
            iconName: StandardImageIdentifiers.Large.chevronRight,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarForwardAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.forwardButton)
    }
}
