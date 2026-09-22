// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct ThemePrivacyOverrideKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

public extension EnvironmentValues {
    /// The private theme override in effect for this part of the view tree, or `nil` when views should
    /// follow their window's own private state.
    ///
    /// This is the SwiftUI counterpart of `Themeable.updateThemeApplicableSubviews(_:for:)`: in UIKit the
    /// override reaches a whole hierarchy because the resolved theme is pushed onto every subview, whereas in
    /// SwiftUI each view resolves its own theme, so the override has to travel down through the environment.
    var themePrivacyOverride: Bool? {
        get { self[ThemePrivacyOverrideKey.self] }
        set { self[ThemePrivacyOverrideKey.self] = newValue }
    }
}

public extension View {
    /// Forces the theme of this view and its descendants to be private or not private, regardless of whether
    /// the window is technically in private browsing mode.
    /// - Parameters:
    ///   - shouldUsePrivateOverride: Whether to override the theme at all. When `false`, an override
    ///   inherited from an ancestor is left untouched.
    ///   - shouldBeInPrivateTheme: Whether the private theme should be forced on or off.
    func themePrivacyOverride(shouldUsePrivateOverride: Bool, shouldBeInPrivateTheme: Bool) -> some View {
        transformEnvironment(\.themePrivacyOverride) { value in
            guard shouldUsePrivateOverride else { return }
            value = shouldBeInPrivateTheme
        }
    }
}
