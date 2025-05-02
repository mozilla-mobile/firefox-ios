// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol ThemeManager {
    // Current theme
    func getCurrentTheme(for window: WindowUUID?) -> Theme

    /// Resolves the appropriate theme based on window context and privacy override logic.
    ///
    /// This method determines the correct theme to display based on whether we should show private theme
    /// even though the user may not technically be in private browsing mode. It allows for overriding the default logic
    /// by explicitly specifying whether the private theme should be shown, regardless of the window’s technical private
    /// state. The user is in private mode when the tab they selected is a private tab. This method is used in tab tray view.
    /// - Parameters:
    ///   - shouldUsePrivateTheme: A boolean indicating whether to force the use of the private theme or not.
    /// - Returns: The resolved theme—either the private or default user theme depending on context.
    func resolvedTheme(with shouldShowPrivateTheme: Bool) -> Theme

    /// TODO(FXIOS-11655): Making this a prop of ThemeManager since it's easier to get the flag value this way
    /// instead of having to call the nimbus API each time. This should be removed once experiment is over.
    var isNewAppearanceMenuOn: Bool { get }

    // System theme and brightness settings
    var systemThemeIsOn: Bool { get }
    var automaticBrightnessIsOn: Bool { get }
    var automaticBrightnessValue: Float { get }
    func setSystemTheme(isOn: Bool)
    func setManualTheme(to newTheme: ThemeType)
    func getUserManualTheme() -> ThemeType
    func setAutomaticBrightness(isOn: Bool)
    func setAutomaticBrightnessValue(_ value: Float)

    // Window management and window-specific theming
    func applyThemeUpdatesToWindows()
    func setPrivateTheme(isOn: Bool, for window: WindowUUID)
    func getPrivateThemeIsOn(for window: WindowUUID) -> Bool
    func setWindow(_ window: UIWindow, for uuid: WindowUUID)
    func windowDidClose(uuid: WindowUUID)

    // Theme functions for app extensions

    /// Returns the general theme setting outside of any specific iOS window.
    /// This is generally only meant to be used in scenarios where the UI is
    /// presented outside the context of any particular browser window, such
    /// as in our app extensions.
    func windowNonspecificTheme() -> Theme
}
