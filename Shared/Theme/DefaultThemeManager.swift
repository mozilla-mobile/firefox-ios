// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// The `ThemeManager` will be responsible for providing the theme throughout the app
final public class DefaultThemeManager: ThemeManager, Notifiable {
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

    public var currentTheme: Theme = LightTheme()
    public var notificationCenter: NotificationProtocol
    private var userDefaults: UserDefaultsInterface
    private var mainQueue: DispatchQueueInterface

    public var window: UIWindow?

    // MARK: - Init

    public init(userDefaults: UserDefaultsInterface = UserDefaults.standard,
                notificationCenter: NotificationProtocol = NotificationCenter.default,
                mainQueue: DispatchQueueInterface = DispatchQueue.main) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        self.mainQueue = mainQueue

        migrateDefaultsToUseStandard()

        self.userDefaults.register(defaults: [ThemeKeys.systemThemeIsOn: true,
                                              ThemeKeys.NightMode.isOn: NSNumber(value: false)])

        changeCurrentTheme(loadInitialThemeType())

        setupNotifications(forObserver: self,
                           observing: [UIScreen.brightnessDidChangeNotification,
                                       UIApplication.didBecomeActiveNotification])
    }

    // MARK: - ThemeManager

    public func getInterfaceStyle() -> UIUserInterfaceStyle {
        return currentTheme.type.getInterfaceStyle()
    }

    public func changeCurrentTheme(_ newTheme: ThemeType) {
        guard currentTheme.type != newTheme else { return }
        currentTheme = newThemeForType(newTheme)

        // overwrite the user interface style on the window attached to our scene
        // once we have multiple scenes we need to update all of them
        window?.overrideUserInterfaceStyle = currentTheme.type.getInterfaceStyle()

        mainQueue.ensureMainThread { [weak self] in
            self?.notificationCenter.post(name: .ThemeDidChange)
        }
    }

    public func systemThemeChanged() {
        // Ignore if the system theme is off or night mode is on
        guard userDefaults.bool(forKey: ThemeKeys.systemThemeIsOn),
              let nightModeIsOn = userDefaults.object(forKey: ThemeKeys.NightMode.isOn) as? NSNumber,
              nightModeIsOn.boolValue == false
        else { return }
        changeCurrentTheme(getSystemThemeType())
    }

    public func setSystemTheme(isOn: Bool) {
        userDefaults.set(isOn, forKey: ThemeKeys.systemThemeIsOn)

        if isOn {
            systemThemeChanged()
        } else if userDefaults.bool(forKey: ThemeKeys.AutomaticBrightness.isOn) {
            updateThemeBasedOnBrightness()
        }
    }

    public func setAutomaticBrightness(isOn: Bool) {
        let currentState = userDefaults.bool(forKey: ThemeKeys.AutomaticBrightness.isOn)
        guard currentState != isOn else { return }

        userDefaults.set(isOn, forKey: ThemeKeys.AutomaticBrightness.isOn)
        brightnessChanged()
    }

    public func setAutomaticBrightnessValue(_ value: Float) {
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

    private func migrateDefaultsToUseStandard() {
        guard let oldDefaultsStore = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier) else { return }

        if let systemThemeIsOn = oldDefaultsStore.value(forKey: ThemeKeys.systemThemeIsOn) {
            userDefaults.set(systemThemeIsOn, forKey: ThemeKeys.systemThemeIsOn)
        }
        if let nightModeIsOn = oldDefaultsStore.value(forKey: ThemeKeys.NightMode.isOn) {
            userDefaults.set(nightModeIsOn, forKey: ThemeKeys.NightMode.isOn)
        }
        if let automaticBrightnessIsOn = oldDefaultsStore.value(forKey: ThemeKeys.AutomaticBrightness.isOn) {
            userDefaults.set(automaticBrightnessIsOn, forKey: ThemeKeys.AutomaticBrightness.isOn)
        }
        if let automaticBrighnessValue = oldDefaultsStore.value(forKey: ThemeKeys.AutomaticBrightness.thresholdValue) {
            userDefaults.set(automaticBrighnessValue, forKey: ThemeKeys.AutomaticBrightness.thresholdValue)
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
