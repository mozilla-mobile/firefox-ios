// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The `ThemeManager` will be responsible for providing the theme throughout the app
@MainActor
public final class DefaultThemeManager: ThemeManager, Notifiable {
    // These have been carried over from the legacy system to maintain backwards compatibility
    enum ThemeKeys {
        static let themeName = "prefKeyThemeName"
        static let systemThemeIsOn = "prefKeySystemThemeSwitchOnOff"
        static let hasMigratedToNewAppearanceMenu = "prefKeyhasMigratedToNewAppearanceMenu"
        static let accentColor = "prefKeyAccentColor"
        static let backgroundTintColor = "prefKeyBackgroundTintColor"
        static let toolbarTintColor = "prefKeyToolbarTintColor"
        static let customAccentColors = "prefKeyCustomAccentColors"
        static let customBackgroundTintColors = "prefKeyCustomBackgroundTintColors"
        static let customToolbarTintColors = "prefKeyCustomToolbarTintColors"

        enum AutomaticBrightness {
            static let isOn = "prefKeyAutomaticSwitchOnOff"
            static let thresholdValue = "prefKeyAutomaticSliderValue"
        }

        enum NightMode {
            static let isOn = "profile.NightModeStatus"
        }
    }

    // MARK: - Variables

    private var windows: [WindowUUID: UIWindow] = [:]
    private var privateBrowsingState: [WindowUUID: Bool] = [:]
    private var allWindowUUIDs: [WindowUUID] { return Array(windows.keys) }
    public let notificationCenter: NotificationProtocol

    private var userDefaults: UserDefaultsInterface
    private var mainQueue: DispatchQueueInterface
    private var sharedContainerIdentifier: String

    private var isNewAppearanceMenuOnClosure: () -> Bool
    private var isCustomThemingEnabledClosure: () -> Bool

    private var nightModeIsOn: Bool {
        return userDefaults.bool(forKey: ThemeKeys.NightMode.isOn)
    }

    public var systemThemeIsOn: Bool {
        return userDefaults.bool(forKey: ThemeKeys.systemThemeIsOn)
    }

    public var automaticBrightnessIsOn: Bool {
        return userDefaults.bool(forKey: ThemeKeys.AutomaticBrightness.isOn)
    }

    public var automaticBrightnessValue: Float {
        return userDefaults.float(forKey: ThemeKeys.AutomaticBrightness.thresholdValue)
    }

    public var isNewAppearanceMenuOn: Bool {
        return isNewAppearanceMenuOnClosure()
    }

    public var isCustomThemingEnabled: Bool {
        return isCustomThemingEnabledClosure()
    }

    public var hasMigratedToNewAppearanceMenu: Bool {
        return userDefaults.bool(forKey: ThemeKeys.hasMigratedToNewAppearanceMenu)
    }

    public var accentColor: AccentColor {
        guard let value = userDefaults.string(forKey: ThemeKeys.accentColor) else { return .blue }
        return AccentColor.from(persistenceValue: value)
    }

    public var backgroundTintColor: AccentColor {
        guard let value = userDefaults.string(forKey: ThemeKeys.backgroundTintColor) else { return .blue }
        return AccentColor.from(persistenceValue: value)
    }

    public var toolbarTintColor: AccentColor {
        guard let value = userDefaults.string(forKey: ThemeKeys.toolbarTintColor) else { return .blue }
        return AccentColor.from(persistenceValue: value)
    }

    public var customAccentColors: [String] {
        userDefaults.array(forKey: ThemeKeys.customAccentColors) as? [String] ?? []
    }

    public var customBackgroundTintColors: [String] {
        userDefaults.array(forKey: ThemeKeys.customBackgroundTintColors) as? [String] ?? []
    }

    public var customToolbarTintColors: [String] {
        userDefaults.array(forKey: ThemeKeys.customToolbarTintColors) as? [String] ?? []
    }

    // MARK: - Initializers

    public init(
        userDefaults: UserDefaultsInterface = UserDefaults.standard,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        mainQueue: DispatchQueueInterface = DispatchQueue.main,
        sharedContainerIdentifier: String,
        isNewAppearanceMenuOnClosure: @escaping () -> Bool = { false },
        isCustomThemingEnabledClosure: @escaping () -> Bool = { false }
    ) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        self.mainQueue = mainQueue
        self.sharedContainerIdentifier = sharedContainerIdentifier
        self.isNewAppearanceMenuOnClosure = isNewAppearanceMenuOnClosure
        self.isCustomThemingEnabledClosure = isCustomThemingEnabledClosure

        self.userDefaults.register(defaults: [
            ThemeKeys.systemThemeIsOn: true,
            ThemeKeys.NightMode.isOn: false
        ])

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIScreen.brightnessDidChangeNotification,
                        UIApplication.didBecomeActiveNotification]
        )
    }

    // MARK: - Theming general functions
    @MainActor
    public func getCurrentTheme(for window: WindowUUID?) -> Theme {
        guard let window else {
            assertionFailure("Attempt to get the theme for a nil window UUID.")
            return DarkTheme()
        }

        return getThemeFrom(type: determineThemeType(for: window))
    }

    public func resolvedTheme(with shouldShowPrivateTheme: Bool) -> Theme {
        return shouldShowPrivateTheme ? PrivateModeTheme() : getThemeFrom(type: determineUserTheme())
    }

    @MainActor
    public func applyThemeUpdatesToWindows() {
        allWindowUUIDs.forEach { windowUUID in
            applyThemeChanges(for: windowUUID, using: determineThemeType(for: windowUUID))
        }
    }

    // MARK: - Manual theme functions
    public func setManualTheme(to newTheme: ThemeType) {
        updateSavedTheme(to: newTheme)
        applyThemeUpdatesToWindows()
    }

    public func getUserManualTheme() -> ThemeType {
        guard let savedThemeDescription = userDefaults.string(forKey: ThemeKeys.themeName),
              let savedTheme = ThemeType(rawValue: savedThemeDescription)
        else { return getThemeTypeBasedOnSystem() }

        return savedTheme
    }

    // MARK: - System theme functions
    public func setSystemTheme(isOn: Bool) {
        userDefaults.set(isOn, forKey: ThemeKeys.systemThemeIsOn)
        applyThemeUpdatesToWindows()
    }

    private func getThemeTypeBasedOnSystem() -> ThemeType {
        return UIScreen.main.traitCollection.userInterfaceStyle == .dark ? ThemeType.dark : ThemeType.light
    }

    // MARK: - Private theme functions
    public func setPrivateTheme(isOn: Bool, for window: WindowUUID) {
        guard getPrivateThemeIsOn(for: window) != isOn else { return }
        privateBrowsingState[window] = isOn
        applyThemeChanges(for: window, using: determineThemeType(for: window))
    }

    public func getPrivateThemeIsOn(for window: WindowUUID) -> Bool {
        return privateBrowsingState[window] ?? false
    }

    // MARK: - Automatic brightness theme functions
    public func setAutomaticBrightness(isOn: Bool) {
        guard automaticBrightnessIsOn != isOn else { return }
        userDefaults.set(isOn, forKey: ThemeKeys.AutomaticBrightness.isOn)
        applyThemeUpdatesToWindows()
    }

    public func setAutomaticBrightnessValue(_ value: Float) {
        userDefaults.set(value, forKey: ThemeKeys.AutomaticBrightness.thresholdValue)
        applyThemeUpdatesToWindows()
    }

    // MARK: - Accent color functions
    public func setAccentColor(_ color: AccentColor) {
        userDefaults.set(color.persistenceValue, forKey: ThemeKeys.accentColor)
        applyThemeUpdatesToWindows()
    }

    // MARK: - Background tint color functions
    public func setBackgroundTintColor(_ color: AccentColor) {
        userDefaults.set(color.persistenceValue, forKey: ThemeKeys.backgroundTintColor)
        applyThemeUpdatesToWindows()
    }

    // MARK: - Toolbar tint color functions
    public func setToolbarTintColor(_ color: AccentColor) {
        userDefaults.set(color.persistenceValue, forKey: ThemeKeys.toolbarTintColor)
        applyThemeUpdatesToWindows()
    }

    // MARK: - Custom accent color functions
    public func addCustomAccentColor(_ hex: String) {
        var colors = customAccentColors
        guard !colors.contains(hex) else { return }
        colors.append(hex)
        userDefaults.set(colors, forKey: ThemeKeys.customAccentColors)
        setAccentColor(.custom(hex: hex))
    }

    public func removeCustomAccentColor(_ hex: String) {
        var colors = customAccentColors
        colors.removeAll { $0 == hex }
        userDefaults.set(colors, forKey: ThemeKeys.customAccentColors)
        if accentColor == .custom(hex: hex) {
            setAccentColor(.blue)
        } else {
            applyThemeUpdatesToWindows()
        }
    }

    // MARK: - Custom background tint color functions
    public func addCustomBackgroundTintColor(_ hex: String) {
        var colors = customBackgroundTintColors
        guard !colors.contains(hex) else { return }
        colors.append(hex)
        userDefaults.set(colors, forKey: ThemeKeys.customBackgroundTintColors)
        setBackgroundTintColor(.custom(hex: hex))
    }

    public func removeCustomBackgroundTintColor(_ hex: String) {
        var colors = customBackgroundTintColors
        colors.removeAll { $0 == hex }
        userDefaults.set(colors, forKey: ThemeKeys.customBackgroundTintColors)
        if backgroundTintColor == .custom(hex: hex) {
            setBackgroundTintColor(.blue)
        } else {
            applyThemeUpdatesToWindows()
        }
    }

    // MARK: - Custom toolbar tint color functions
    public func addCustomToolbarTintColor(_ hex: String) {
        var colors = customToolbarTintColors
        guard !colors.contains(hex) else { return }
        colors.append(hex)
        userDefaults.set(colors, forKey: ThemeKeys.customToolbarTintColors)
        setToolbarTintColor(.custom(hex: hex))
    }

    public func removeCustomToolbarTintColor(_ hex: String) {
        var colors = customToolbarTintColors
        colors.removeAll { $0 == hex }
        userDefaults.set(colors, forKey: ThemeKeys.customToolbarTintColors)
        if toolbarTintColor == .custom(hex: hex) {
            setToolbarTintColor(.blue)
        } else {
            applyThemeUpdatesToWindows()
        }
    }

    private func getThemeTypeBasedOnBrightness() -> ThemeType {
        return Float(UIScreen.main.brightness) < automaticBrightnessValue ? .dark : .light
    }

    // MARK: - Window specific functions
    public func windowNonspecificTheme() -> Theme {
        switch getUserManualTheme() {
        case .dark, .nightMode, .privateMode: return DarkTheme()
        case .light: return LightTheme()
        }
    }

    public func windowDidClose(uuid: WindowUUID) {
        windows.removeValue(forKey: uuid)
    }

    public func setWindow(_ window: UIWindow, for uuid: WindowUUID) {
        windows[uuid] = window
        updateSavedTheme(to: getUserManualTheme())
        applyThemeChanges(for: uuid, using: determineThemeType(for: uuid))
    }

    // MARK: - Private helper methods

    private func updateSavedTheme(to newTheme: ThemeType) {
        userDefaults.set(newTheme.rawValue, forKey: ThemeKeys.themeName)
    }

    @MainActor
    private func applyThemeChanges(for window: WindowUUID, using newTheme: ThemeType) {
        // Overwrite the user interface style on the window attached to our scene
        // once we have multiple scenes we need to update all of them
        let style = self.getCurrentTheme(for: window).type.getInterfaceStyle()
        self.windows[window]?.overrideUserInterfaceStyle = style
        notifyCurrentThemeDidChange(for: window)
    }

    @MainActor
    private func notifyCurrentThemeDidChange(for window: WindowUUID) {
        notificationCenter.post(
            name: .ThemeDidChange,
            withUserInfo: window.userInfo
        )
    }

    private func determineThemeType(for window: WindowUUID) -> ThemeType {
        if getPrivateThemeIsOn(for: window) { return .privateMode }
        return determineUserTheme()
    }

    private func determineUserTheme() -> ThemeType {
        // Check if a migration override should be applied. This is mainly done because the new behaviour splits
        // dark theme appearance of the app and web content. Once FXIOS-11655, both this check and nightMode
        // in general will be removed.
        if let migratedTheme = migratedTheme() { return migratedTheme }
        if !isNewAppearanceMenuOn && nightModeIsOn { return .nightMode }
        if systemThemeIsOn { return getThemeTypeBasedOnSystem() }
        if automaticBrightnessIsOn { return getThemeTypeBasedOnBrightness() }

        return getUserManualTheme()
    }

    private func getThemeFrom(type: ThemeType) -> Theme {
        let baseTheme: Theme
        switch type {
        case .light:
            baseTheme = LightTheme()
        case .dark:
            baseTheme = DarkTheme()
        case .nightMode:
            baseTheme = NightModeTheme()
        case .privateMode:
            baseTheme = PrivateModeTheme()
        }

        // Only apply tinting to light and dark themes.
        // Private mode and night mode retain their hardcoded palettes.
        guard type == .light || type == .dark else { return baseTheme }

        let accent = accentColor
        let bgTint = backgroundTintColor
        let hasTinting = !accent.isDefault || !bgTint.isDefault

        if hasTinting {
            let resolvedBgTint: UIColor? = bgTint.isDefault ? nil : bgTint.color(for: type)
            return TintedTheme(
                type: type,
                colors: TintedThemeColourPalette(
                    base: baseTheme.colors,
                    accent: accent.isDefault ? baseTheme.colors.actionPrimary : accent.color(for: type),
                    themeType: type,
                    backgroundTint: resolvedBgTint
                )
            )
        }
        return baseTheme
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIScreen.brightnessDidChangeNotification,
            UIApplication.didBecomeActiveNotification:
            ensureMainThread {
                self.applyThemeUpdatesToWindows()
            }
        default:
            return
        }
    }

    /// Checks if theme migration should override the current theme selection.
    /// Returns:
    /// - .dark if migration conditions are met and NightMode is active.
    /// - nil otherwise.
    /// NOTE(FXIOS-11655): This code will be removed once the new appearance menu experiment ends.
    @MainActor
    private func migratedTheme() -> ThemeType? {
        if isNewAppearanceMenuOn && !hasMigratedToNewAppearanceMenu {
            // Mark that migration has been performed to avoid repeating the process.
            userDefaults.set(true, forKey: ThemeKeys.hasMigratedToNewAppearanceMenu)
            if nightModeIsOn {
                // If nightMode was on, force dark mode in the new UI and update all other themes.
                updateSavedTheme(to: .dark)
                setSystemTheme(isOn: false)
                setAutomaticBrightness(isOn: false)
                return .dark
            } else if automaticBrightnessIsOn {
                // If automaticBrightness was on, apply the computed theme.
                updateSavedTheme(to: getThemeTypeBasedOnBrightness())
                setSystemTheme(isOn: false)
                setAutomaticBrightness(isOn: false)
            }
        } else if !isNewAppearanceMenuOn && hasMigratedToNewAppearanceMenu {
            // Reset the migration flag (mostly for debugging or rare cases).
            userDefaults.set(false, forKey: ThemeKeys.hasMigratedToNewAppearanceMenu)
        }
        return nil
    }
}
