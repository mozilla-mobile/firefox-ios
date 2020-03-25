/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private enum ColorScheme {
    case dark
    case light
}

public struct ModernColor {
    var darkColor: UIColor
    var lightColor: UIColor

    public init(dark: UIColor, light: UIColor) {
        self.darkColor = dark
        self.lightColor = light
    }

    public var color: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return self.color(for: .dark)
                } else {
                    return self.color(for: .light)
                }
            }
        } else {
            return color(for: .light)
        }
    }

    private func color(for scheme: ColorScheme) -> UIColor {
        return scheme == .dark ? darkColor : lightColor
    }
}

struct Theme {
    static let defaultBackground = ModernColor(dark: UIColor.Photon.Grey80, light: .white)
    static let doneLabelBackground = ModernColor(dark: UIColor.Photon.Blue40, light: UIColor.Photon.Blue40)
    static let separator = ModernColor(dark: UIColor.Photon.Grey10, light: UIColor.Photon.Grey30)
    static let actionRowTextAndIcon = ModernColor(dark: .white, light: UIColor.Photon.Grey80)
}
