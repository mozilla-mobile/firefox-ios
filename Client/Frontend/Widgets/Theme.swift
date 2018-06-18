/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation

typealias ThemeName = String

enum BuiltinThemes: ThemeName {
    case normal
    case dark
    case pbm
}

struct AppThemeState {
    fileprivate static var _activeNonPrivateTheme = BuiltinThemes.normal.rawValue

    static var activeNonPrivateTheme: ThemeName {
        get { return _activeNonPrivateTheme }
        set {
            if newValue != _activeNonPrivateTheme, newValue != BuiltinThemes.pbm.rawValue {
                _activeNonPrivateTheme = newValue
            }
        }
    }

    static var isPrivate: Bool = false

    static func currentTheme() -> ThemeName {
        return isPrivate ? BuiltinThemes.pbm.rawValue : _activeNonPrivateTheme 
    }
}

protocol Themeable {
    // Protocol extension provides a no-arg applyTheme() for using current active theme
    func applyTheme(_ theme: ThemeName)
}

extension Themeable {
    func applyTheme() {
        applyTheme(AppThemeState.currentTheme())
    }
}

// Represents the color of UI for a given theme.
struct AppColor {
    var colors = [ThemeName: UIColor]()

    init(normal: UIColor, pbm: UIColor, dark: UIColor = UIColor.yellow) {
        colors[BuiltinThemes.normal.rawValue] = normal
        colors[BuiltinThemes.pbm.rawValue] = pbm
        colors[BuiltinThemes.dark.rawValue] = dark
    }

    init(normal: Int, pbm: Int, dark: Int = 0) {
        colors[BuiltinThemes.normal.rawValue] = UIColor(rgb: normal)
        colors[BuiltinThemes.pbm.rawValue] = UIColor(rgb: pbm)
        colors[BuiltinThemes.dark.rawValue] = UIColor(rgb: dark)
    }

    func colorFor(_ theme: ThemeName) -> UIColor {
        guard let color = colors[theme] else {
            assertionFailure("Bad theme name, now you get brown. Enjoy.")
            return UIColor.brown
        }
        return color
    }
}
