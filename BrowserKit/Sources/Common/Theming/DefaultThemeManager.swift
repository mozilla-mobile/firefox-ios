// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

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

        enum PrivateMode {
            static let isOn = "profile.PrivateModeStatus"
        }
    }

    // MARK: - Variables

    public var currentTheme: Theme = LightTheme()
    public var notificationCenter: NotificationProtocol
    public var window: UIWindow?

    private var userDefaults: UserDefaultsInterface
    private var mainQueue: DispatchQueueInterface
    private var sharedContainerIdentifier: String

    private var nightModeIsOn: Bool {
        guard let isOn = userDefaults.object(forKey: ThemeKeys.NightMode.isOn) as? NSNumber,
              isOn.boolValue == true
        else { return false }

        return true
    }

    private var privateModeIsOn: Bool {
        return userDefaults.bool(forKey: ThemeKeys.PrivateMode.isOn)
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
            ThemeKeys.NightMode.isOn: NSNumber(value: false),
            ThemeKeys.PrivateMode.isOn: false,
        ])

        changeCurrentTheme(fetchSavedThemeType())

        setupNotifications(forObserver: self,
                           observing: [UIScreen.brightnessDidChangeNotification,
                                       UIApplication.didBecomeActiveNotification])
    }

    // MARK: - ThemeManager

    public func changeCurrentTheme(_ newTheme: ThemeType) {
        guard currentTheme.type != newTheme else { return }

        updateSavedTheme(to: newTheme)
        updateCurrentTheme(to: fetchSavedThemeType())
    }

    public func systemThemeChanged() {
        // Ignore if:
        // the system theme is off
        // OR night mode is on
        // OR private mode is on
        guard systemThemeIsOn,
              !nightModeIsOn,
              !privateModeIsOn
        else { return }

        changeCurrentTheme(getSystemThemeType())
    }

    public func setSystemTheme(isOn: Bool) {
        userDefaults.set(isOn, forKey: ThemeKeys.systemThemeIsOn)

        if isOn {
            systemThemeChanged()
        } else if automaticBrightnessIsOn {
            updateThemeBasedOnBrightness()
        }
    }

    public func setPrivateTheme(isOn: Bool) {
        userDefaults.set(isOn, forKey: ThemeKeys.PrivateMode.isOn)

        updateCurrentTheme(to: fetchSavedThemeType())
    }

    public func setAutomaticBrightness(isOn: Bool) {
        guard automaticBrightnessIsOn != isOn else { return }

        userDefaults.set(isOn, forKey: ThemeKeys.AutomaticBrightness.isOn)
        brightnessChanged()
    }

    public func setAutomaticBrightnessValue(_ value: Float) {
        userDefaults.set(value, forKey: ThemeKeys.AutomaticBrightness.thresholdValue)
        brightnessChanged()
    }

    public func brightnessChanged() {
        if automaticBrightnessIsOn {
            updateThemeBasedOnBrightness()
        }
    }

    // MARK: - Private methods

    private func updateSavedTheme(to newTheme: ThemeType) {
        // We never want to save the private theme because it's meant to override
        // whatever current theme is set. This means that we need to know the theme
        // before we went into private mode, in order to be able to return to it.
        guard newTheme != .privateMode else { return }
        userDefaults.set(newTheme.rawValue, forKey: ThemeKeys.themeName)
    }

    private func updateCurrentTheme(to newTheme: ThemeType) {
        currentTheme = newThemeForType(newTheme)

        // Overwrite the user interface style on the window attached to our scene
        // once we have multiple scenes we need to update all of them
        window?.overrideUserInterfaceStyle = currentTheme.type.getInterfaceStyle()

        mainQueue.ensureMainThread { [weak self] in
            self?.notificationCenter.post(name: .ThemeDidChange)
        }
    }

    private func fetchSavedThemeType() -> ThemeType {
        if privateModeIsOn { return .privateMode }
        if nightModeIsOn { return .dark }

        var themeType = getSystemThemeType()
        if let savedThemeDescription = userDefaults.string(forKey: ThemeKeys.themeName),
           let savedTheme = ThemeType(rawValue: savedThemeDescription) {
            themeType = savedTheme
        }

        return themeType
    }

    private func getSystemThemeType() -> ThemeType {
        return UIScreen.main.traitCollection.userInterfaceStyle == .dark ? ThemeType.dark : ThemeType.light
    }

    private func newThemeForType(_ type: ThemeType) -> Theme {
        switch type {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        case .privateMode:
            return PrivateModeTheme()
        }
    }

    private func updateThemeBasedOnBrightness() {
        let currentValue = Float(UIScreen.main.brightness)

        if currentValue < automaticBrightnessValue {
            changeCurrentTheme(.dark)
        } else {
            changeCurrentTheme(.light)
        }
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIScreen.brightnessDidChangeNotification:
            brightnessChanged()
        case UIApplication.didBecomeActiveNotification:
            // It seems this notification is fired before the UI is informed of any changes to dark mode
            // So dispatching to the end of the main queue will ensure it's always got the latest info
            DispatchQueue.main.async {
                self.systemThemeChanged()
            }
        default:
            return
        }
    }
}
