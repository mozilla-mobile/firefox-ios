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
        return UIColor { (traitCollection: UITraitCollection) -> UIColor in
            if traitCollection.userInterfaceStyle == .dark {
                return self.color(for: .dark)
            } else {
                return self.color(for: .light)
            }
        }
    }

    private func color(for scheme: ColorScheme) -> UIColor {
        return scheme == .dark ? darkColor : lightColor
    }
}

struct ShareTheme {
    static let defaultBackground = ModernColor(dark: UIColor.Photon.Grey80, light: .white)
    static let doneLabelBackground = ModernColor(dark: UIColor(rgb: 0x5DD25E), light: UIColor(rgb: 0x008009))
    static let separator = ModernColor(dark: UIColor.Photon.Grey50, light: UIColor.Photon.Grey30)
    static let actionRowTextAndIcon = ModernColor(dark: .white, light: UIColor.Photon.Grey80)
    static let doneRowText = ModernColor(dark: UIColor.Photon.Grey80, light: .white)
}
