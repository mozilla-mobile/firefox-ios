// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public enum ThemeType: String {
    case light = "normal" // This needs to match the string used in the legacy system
    case dark
    case privateMode
    case nightMode

    public func getInterfaceStyle() -> UIUserInterfaceStyle {
        return switch self {
        case .dark, .nightMode, .privateMode: .dark
        case .light: .light
        }
    }

    public func getBarStyle() -> UIBarStyle {
        return switch self {
        case .dark, .nightMode, .privateMode: .black
        case .light: .default
        }
    }

    public func keyboardAppearence(isPrivate: Bool) -> UIKeyboardAppearance {
        if isPrivate { return .dark }
        return switch self {
        case .dark, .nightMode, .privateMode: .dark
        case .light: .light
        }
    }

    public func tabTitleBlurStyle() -> UIBlurEffect.Style {
        return switch self {
        case .dark, .nightMode, .privateMode: UIBlurEffect.Style.dark
        case .light: UIBlurEffect.Style.extraLight
        }
    }
}
