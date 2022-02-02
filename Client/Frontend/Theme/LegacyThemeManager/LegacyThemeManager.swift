// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0
import UIKit

enum LegacyThemeManagerPrefs: String {
    case systemThemeIsOn = "prefKeySystemThemeSwitchOnOff"
    case automaticSwitchIsOn = "prefKeyAutomaticSwitchOnOff"
    case automaticSliderValue = "prefKeyAutomaticSliderValue"
    case themeName = "prefKeyThemeName"
}

class LegacyThemeManager {
    static let instance = LegacyThemeManager()

    var current: LegacyTheme = themeFrom(name: UserDefaults.standard.string(forKey: LegacyThemeManagerPrefs.themeName.rawValue)) {
        didSet {
            UserDefaults.standard.set(current.name, forKey: LegacyThemeManagerPrefs.themeName.rawValue)
            NotificationCenter.default.post(name: .DisplayThemeChanged, object: nil)
        }
    }

    var currentName: BuiltinThemeName {
        return BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
    }

    var automaticBrightnessValue: Float = UserDefaults.standard.float(forKey: LegacyThemeManagerPrefs.automaticSliderValue.rawValue) {
        didSet {
            UserDefaults.standard.set(automaticBrightnessValue, forKey: LegacyThemeManagerPrefs.automaticSliderValue.rawValue)
        }
    }

    var automaticBrightnessIsOn: Bool = UserDefaults.standard.bool(forKey: LegacyThemeManagerPrefs.automaticSwitchIsOn.rawValue) {
        didSet {
            UserDefaults.standard.set(automaticBrightnessIsOn, forKey: LegacyThemeManagerPrefs.automaticSwitchIsOn.rawValue)
            guard automaticBrightnessIsOn else { return }
            updateCurrentThemeBasedOnScreenBrightness()
        }
    }

    var systemThemeIsOn: Bool {
        didSet {
            UserDefaults.standard.set(systemThemeIsOn, forKey: LegacyThemeManagerPrefs.systemThemeIsOn.rawValue)
        }
    }

    private init() {
        UserDefaults.standard.register(defaults: [LegacyThemeManagerPrefs.systemThemeIsOn.rawValue: true])
        systemThemeIsOn = UserDefaults.standard.bool(forKey: LegacyThemeManagerPrefs.systemThemeIsOn.rawValue)

        NotificationCenter.default.addObserver(self, selector: #selector(brightnessChanged), name: UIScreen.brightnessDidChangeNotification, object: nil)
    }

    // UIViewControllers / UINavigationControllers need to have `preferredStatusBarStyle` and call this.
    var statusBarStyle: UIStatusBarStyle {
        return .default
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch currentName {
        case .dark:
            return .dark
        default:
            return .light
        }
    }

    func updateCurrentThemeBasedOnScreenBrightness() {
        let prefValue = UserDefaults.standard.float(forKey: LegacyThemeManagerPrefs.automaticSliderValue.rawValue)

        let screenLessThanPref = Float(UIScreen.main.brightness) < prefValue

        if screenLessThanPref, self.currentName == .normal {
            self.current = DarkTheme()
        } else if !screenLessThanPref, self.currentName == .dark {
            self.current = NormalTheme()
        }
    }

    @objc private func brightnessChanged() {
        guard automaticBrightnessIsOn else { return }
        updateCurrentThemeBasedOnScreenBrightness()
    }
}

fileprivate func themeFrom(name: String?) -> LegacyTheme {
    guard let name = name, let theme = BuiltinThemeName(rawValue: name) else { return NormalTheme() }
    switch theme {
    case .dark:
        return DarkTheme()
    default:
        return NormalTheme()
    }
}
