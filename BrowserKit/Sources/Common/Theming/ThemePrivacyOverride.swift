// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct ThemePrivacyOverrideKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

public extension EnvironmentValues {
    /// `nil` means views should follow their window's own private state.
    var themePrivacyOverride: Bool? {
        get { self[ThemePrivacyOverrideKey.self] }
        set { self[ThemePrivacyOverrideKey.self] = newValue }
    }
}

public extension View {
    func themePrivacyOverride(shouldUsePrivateOverride: Bool, shouldBeInPrivateTheme: Bool) -> some View {
        transformEnvironment(\.themePrivacyOverride) { value in
            guard shouldUsePrivateOverride else { return }
            value = shouldBeInPrivateTheme
        }
    }
}
