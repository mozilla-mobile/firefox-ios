// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

typealias KeyedPrivateModeFlags = [String: NSNumber]

/// The `ThemeManager` will be responsible for providing the theme throughout the app
public final class DefaultThemeManager: ThemeManager, Notifiable {
    // These have been carried over from the legacy system to maintain backwards compatibility
    enum ThemeKeys {
        static let themeName = "prefKeyThemeName"
        static let systemThemeIsOn = "prefKeySystemThemeSwitchOnOff"

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
    public var notificationCenter: NotificationProtocol

    private var userDefaults: UserDefaultsInterface
    private var mainQueue: DispatchQueueInterface
    private var sharedContainerIdentifier: String

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

    // MARK: - Initializers

    public init(
        userDefaults: UserDefaultsInterface = UserDefaults.standard,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        mainQueue: DispatchQueueInterface = DispatchQueue.main,
        sharedContainerIdentifier: String
    ) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        self.mainQueue = mainQueue
        self.sharedContainerIdentifier = sharedContainerIdentifier

        self.userDefaults.register(defaults: [
            ThemeKeys.systemThemeIsOn: true,
            ThemeKeys.NightMode.isOn: false
        ])

        setupNotifications(forObserver: self,
                           observing: [UIScreen.brightnessDidChangeNotification,
                                       UIApplication.didBecomeActiveNotification])
    }

    // MARK: - Themeing general functions
    public func getCurrentTheme(for window: WindowUUID?) -> Theme {
        guard let window else {
            assertionFailure("Attempt to get the theme for a nil window UUID.")
            return DarkTheme()
        }

        return getThemeFrom(type: determineThemeType(for: window))
    }

    public func applyThemeUpdatesToWindows() {
        allWindowUUIDs.forEach {
            applyThemeChanges(for: $0, using: determineThemeType(for: $0))
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

    private func applyThemeChanges(for window: WindowUUID, using newTheme: ThemeType) {
        // Overwrite the user interface style on the window attached to our scene
        // once we have multiple scenes we need to update all of them
        let style = self.getCurrentTheme(for: window).type.getInterfaceStyle()
        self.windows[window]?.overrideUserInterfaceStyle = style
        notifyCurrentThemeDidChange(for: window)
    }

    private func notifyCurrentThemeDidChange(for window: WindowUUID) {
        mainQueue.ensureMainThread { [weak self] in
            self?.notificationCenter.post(
                name: .ThemeDidChange,
                withUserInfo: window.userInfo
            )
        }
    }

    private func determineThemeType(for window: WindowUUID) -> ThemeType {
        if getPrivateThemeIsOn(for: window) { return .privateMode }
        if nightModeIsOn { return .nightMode }
        if systemThemeIsOn { return getThemeTypeBasedOnSystem() }
        if automaticBrightnessIsOn { return getThemeTypeBasedOnBrightness() }

        return getUserManualTheme()
    }

    private func getThemeFrom(type: ThemeType) -> Theme {
        switch type {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        case .nightMode:
            return NightModeTheme()
        case .privateMode:
            return PrivateModeTheme()
        }
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIScreen.brightnessDidChangeNotification,
            UIApplication.didBecomeActiveNotification:
            applyThemeUpdatesToWindows()
        default:
            return
        }
    }
}
