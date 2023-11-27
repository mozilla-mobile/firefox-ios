// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public enum ThemeType: String {
    case light = "normal" // This needs to match the string used in the legacy system
    case dark
    case privateMode

    public func getInterfaceStyle() -> UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .privateMode:
            return .dark
        }
    }

    public func getBarStyle() -> UIBarStyle {
        switch self {
        case .light:
            return .default
        case .dark:
            return .black
        case .privateMode:
            return .black
        }
    }

    public func keyboardAppearence(isPrivate: Bool) -> UIKeyboardAppearance {
        if isPrivate {
            return .dark
        }
        return switch self {
        case .dark:
            .dark
        case .light:
            .light
        case .privateMode:
            .dark
        }
    }
}
