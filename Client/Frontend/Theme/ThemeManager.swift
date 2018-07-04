/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation

fileprivate let prefKeyAutomaticSwitchIsOn = "prefKeyAutomaticSwitchOnOff"
fileprivate let prefKeyAutomaticSliderValue = "prefKeyAutomaticSliderValue"
fileprivate let prefKeyThemeName = "prefKeyThemeName"

class ThemeManager {
    static let instance = ThemeManager()

    var current: Theme = themeFrom(name: UserDefaults.standard.string(forKey: prefKeyThemeName)) {
        didSet {
            UserDefaults.standard.set(current.name, forKey: prefKeyThemeName)
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.browserViewController.applyTheme()
            appDelegate?.browserViewController.setNeedsStatusBarAppearanceUpdate()
        }
    }

    var currentName: BuiltinThemeName {
        return BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
    }

    var automaticBrightnessValue: Float = UserDefaults.standard.float(forKey: prefKeyAutomaticSliderValue) {
        didSet {
            UserDefaults.standard.set(automaticBrightnessValue, forKey: prefKeyAutomaticSliderValue)
        }
    }

    var automaticBrightnessIsOn: Bool = UserDefaults.standard.bool(forKey: prefKeyAutomaticSwitchIsOn) {
        didSet {
            UserDefaults.standard.set(automaticBrightnessIsOn, forKey: prefKeyAutomaticSwitchIsOn)
        }
    }

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(brightnessChanged), name: .UIScreenBrightnessDidChange, object: nil)
    }

    // UIViewControllers / UINavigationControllers need to have `preferredStatusBarStyle` and call this.
    var statusBarStyle: UIStatusBarStyle {
        // On iPad the dark and normal theme both have a dark tab bar
        guard UIDevice.current.userInterfaceIdiom == .phone else { return .lightContent }
        return currentName == .dark ? .lightContent : .default
    }

    func updateCurrentThemeBasedOnScreenBrightness() {
        let prefValue = UserDefaults.standard.float(forKey: prefKeyAutomaticSliderValue)

        let screenLessThanPref = Float(UIScreen.main.brightness) < prefValue

        if screenLessThanPref, self.currentName == .dark {
            self.current = NormalTheme()
        } else if !screenLessThanPref, self.currentName == .normal {
            self.current = DarkTheme()
        }
    }

    @objc private func brightnessChanged() {
        guard automaticBrightnessIsOn else { return }
        updateCurrentThemeBasedOnScreenBrightness()
    }
}

fileprivate func themeFrom(name: String?) -> Theme {
    guard let name = name, let theme = BuiltinThemeName(rawValue: name) else { return NormalTheme() }
    switch theme {
    case .dark:
        return DarkTheme()
    default:
        return NormalTheme()
    }
}
