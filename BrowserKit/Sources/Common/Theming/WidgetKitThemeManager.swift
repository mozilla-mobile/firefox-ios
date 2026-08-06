// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// Lightweight `ThemeManager` for the WidgetKit extension.
///
/// Widgets can't share the app's full theming stack (window management, user preferences,
/// nimbus flags, notifications, etc.) so this manager relies on the system's built-in
/// light/dark detection and always returns Nova themes. Setter/window methods are no-ops
/// since widgets don't have windows or user-configurable theming.
@MainActor
public final class WidgetKitThemeManager: ThemeManager {
    public init() {}

    // MARK: - Theme accessors

    /// Resolves the widget theme from the SwiftUI color scheme, which is the only reliable
    /// light/dark signal available inside a widget extension.
    public func theme(for colorScheme: ColorScheme) -> Theme {
        return colorScheme == .dark ? NovaDarkTheme() : NovaLightTheme()
    }

    public func getCurrentTheme(for window: WindowUUID?) -> Theme {
        return systemTheme()
    }

    public func resolvedTheme(with shouldShowPrivateTheme: Bool) -> Theme {
        return systemTheme()
    }

    public func windowNonspecificTheme() -> Theme {
        return systemTheme()
    }

    public func getUserManualTheme() -> ThemeType {
        return systemTheme().type
    }

    private func systemTheme() -> Theme {
        return UIScreen.main.traitCollection.userInterfaceStyle == .dark
            ? NovaDarkTheme()
            : NovaLightTheme()
    }

    // MARK: - Unsupported settings

    public var isNewAppearanceMenuOn: Bool { true }
    public var systemThemeIsOn: Bool { true }
    public var automaticBrightnessIsOn: Bool { false }
    public var automaticBrightnessValue: Float { 0 }

    public func setSystemTheme(isOn: Bool) {}
    public func setManualTheme(to newTheme: ThemeType) {}
    public func setAutomaticBrightness(isOn: Bool) {}
    public func setAutomaticBrightnessValue(_ value: Float) {}

    // MARK: - Window management (no-op in widgets)

    public func applyThemeUpdatesToWindows() {}
    public func setPrivateTheme(isOn: Bool, for window: WindowUUID) {}
    public func getPrivateThemeIsOn(for window: WindowUUID) -> Bool { false }
    public func setWindow(_ window: UIWindow, for uuid: WindowUUID) {}
    public func windowDidClose(uuid: WindowUUID) {}
}
