// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

enum ThemeType: String {
    case light = "normal" // This needs to match the string used in the legacy system
    case dark

    func getInterfaceStyle() -> UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

protocol ThemeManager {
    var currentTheme: Theme { get }

    func getInterfaceStyle() -> UIUserInterfaceStyle
    func changeCurrentTheme(_ newTheme: ThemeType)
    func systemThemeChanged()
    func setSystemTheme(isOn: Bool)
    func setAutomaticBrightness(isOn: Bool)
    func setAutomaticBrightnessValue(_ value: Float)
}

/// The `ThemeManager` will be responsible for providing the theme throughout the app
final class DefaultThemeManager: ThemeManager, Notifiable {

    // These have been carried over from the legacy system to maintain backwards compatibility
    private enum ThemeKeys {
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

    var currentTheme: Theme = LightTheme()
    var notificationCenter: NotificationProtocol
    private var userDefaults: UserDefaultsInterface
    private var appDelegate: UIApplicationDelegate?

    // MARK: - Init

    init(userDefaults: UserDefaultsInterface? = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         appDelegate: UIApplicationDelegate?) {
        self.userDefaults = userDefaults ?? UserDefaults.standard
        self.notificationCenter = notificationCenter
        self.appDelegate = appDelegate

        self.userDefaults.register(defaults: [ThemeKeys.systemThemeIsOn: true,
                                              ThemeKeys.NightMode.isOn: NSNumber(value: false)])

        changeCurrentTheme(loadInitialThemeType())

        setupNotifications(forObserver: self,
                           observing: [UIScreen.brightnessDidChangeNotification,
                                       UIApplication.didBecomeActiveNotification])
    }

    // MARK: - ThemeManager

    func getInterfaceStyle() -> UIUserInterfaceStyle {
        return currentTheme.type.getInterfaceStyle()
    }

    func changeCurrentTheme(_ newTheme: ThemeType) {
        guard currentTheme.type != newTheme else { return }
        currentTheme = newThemeForType(newTheme)
        appDelegate?.window??.overrideUserInterfaceStyle = currentTheme.type.getInterfaceStyle()

        ensureMainThread { [weak self] in
            self?.notificationCenter.post(name: .ThemeDidChange)
        }
    }

    func systemThemeChanged() {
        // Ignore if the system theme is off or night mode is on
        guard userDefaults.bool(forKey: ThemeKeys.systemThemeIsOn),
              let nightModeIsOn = userDefaults.object(forKey: ThemeKeys.NightMode.isOn) as? NSNumber,
              nightModeIsOn.boolValue == false
        else { return }

        // TODO: This is hack because the notification is not arriving all the time
        // Should be removed once the ThemeManager is done. 
        let userInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
        LegacyThemeManager.instance.current = userInterfaceStyle == .dark ? LegacyDarkTheme() : LegacyNormalTheme()
        changeCurrentTheme(getSystemThemeType())
    }

    func setSystemTheme(isOn: Bool) {
        userDefaults.set(isOn, forKey: ThemeKeys.systemThemeIsOn)

        if isOn {
            systemThemeChanged()
        } else if userDefaults.bool(forKey: ThemeKeys.AutomaticBrightness.isOn) {
            updateThemeBasedOnBrightness()
        }
    }

    func setAutomaticBrightness(isOn: Bool) {
        let currentState = userDefaults.bool(forKey: ThemeKeys.AutomaticBrightness.isOn)
        guard currentState != isOn else { return }

        userDefaults.set(isOn, forKey: ThemeKeys.AutomaticBrightness.isOn)
        brightnessChanged()
    }

    func setAutomaticBrightnessValue(_ value: Float) {
        userDefaults.set(value, forKey: ThemeKeys.AutomaticBrightness.thresholdValue)
        brightnessChanged()
    }

    // MARK: - Private methods

    private func loadInitialThemeType() -> ThemeType {
        if let nightModeIsOn = userDefaults.object(forKey: ThemeKeys.NightMode.isOn) as? NSNumber,
           nightModeIsOn.boolValue == true {
            return .dark
        }
        var themeType = getSystemThemeType()

        // TODO: Temporarily use user defaults directly until we figure out how to manage these values FXIOS-5058
        if let savedThemeDescription = UserDefaults.standard.string(forKey: ThemeKeys.themeName),
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
        }
    }

    private func brightnessChanged() {
        let brightnessIsOn = userDefaults.bool(forKey: ThemeKeys.AutomaticBrightness.isOn)

        if brightnessIsOn {
            updateThemeBasedOnBrightness()
        } else {
            systemThemeChanged()
        }
    }

    private func updateThemeBasedOnBrightness() {
        let thresholdValue = userDefaults.float(forKey: ThemeKeys.AutomaticBrightness.thresholdValue)
        let currentValue = Float(UIScreen.main.brightness)

        if currentValue < thresholdValue {
            changeCurrentTheme(.dark)
        } else {
            changeCurrentTheme(.light)
        }
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
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
