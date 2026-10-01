// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct StandardFaviconColorSet: FaviconLetterColorSet {
    public let iconAccentGreen1 = FXColors.FaviconGreen1
    public let iconAccentGreen2 = FXColors.FaviconGreen2
    public let iconAccentGreen3 = FXColors.FaviconGreen3
    public let iconAccentGreen4 = FXColors.FaviconGreen4
    public let iconAccentGreen5 = FXColors.FaviconGreen5
    public let iconAccentGreen6 = FXColors.FaviconGreen6
    public let iconAccentGreen7 = FXColors.FaviconGreen7

    public let iconAccentRed1 = FXColors.FaviconRed1
    public let iconAccentRed2 = FXColors.FaviconRed2
    public let iconAccentRed3 = FXColors.FaviconRed3
    public let iconAccentRed4 = FXColors.FaviconRed4
    public let iconAccentRed5 = FXColors.FaviconRed5
    public let iconAccentRed6 = FXColors.FaviconRed6
    public let iconAccentRed7 = FXColors.FaviconRed7

    public let iconAccentBlue1 = FXColors.FaviconBlue1
    public let iconAccentBlue2 = FXColors.FaviconBlue2
    public let iconAccentBlue3 = FXColors.FaviconBlue3
    public let iconAccentBlue4 = FXColors.FaviconBlue4
    public let iconAccentBlue5 = FXColors.FaviconBlue5
    public let iconAccentBlue6 = FXColors.FaviconBlue6
    public let iconAccentBlue7 = FXColors.FaviconBlue7

    public let iconAccentCyan1 = FXColors.FaviconCyan1
    public let iconAccentCyan2 = FXColors.FaviconCyan2
    public let iconAccentCyan3 = FXColors.FaviconCyan3
    public let iconAccentCyan4 = FXColors.FaviconCyan4
    public let iconAccentCyan5 = FXColors.FaviconCyan5
    public let iconAccentCyan6 = FXColors.FaviconCyan6
    public let iconAccentCyan7 = FXColors.FaviconCyan7

    public let iconAccentOrange1 = FXColors.FaviconOrange1
    public let iconAccentOrange2 = FXColors.FaviconOrange2
    public let iconAccentOrange3 = FXColors.FaviconOrange3
    public let iconAccentOrange4 = FXColors.FaviconOrange4
    public let iconAccentOrange5 = FXColors.FaviconOrange5
    public let iconAccentOrange6 = FXColors.FaviconOrange6
    public let iconAccentOrange7 = FXColors.FaviconOrange7

    public let iconAccentPink1 = FXColors.FaviconPink1
    public let iconAccentPink2 = FXColors.FaviconPink2
    public let iconAccentPink3 = FXColors.FaviconPink3
    public let iconAccentPink4 = FXColors.FaviconPink4
    public let iconAccentPink5 = FXColors.FaviconPink5
    public let iconAccentPink6 = FXColors.FaviconPink6
    public let iconAccentPink7 = FXColors.FaviconPink7

    // Not used by the current theme.
    public let iconAccentYellow1: UIColor = .clear
    public let iconAccentYellow2: UIColor = .clear
    public let iconAccentYellow3: UIColor = .clear
    public let iconAccentYellow4: UIColor = .clear
    public let iconAccentYellow5: UIColor = .clear
    public let iconAccentYellow6: UIColor = .clear
    public let iconAccentYellow7: UIColor = .clear

    private var families: [[UIColor]] {
        [[iconAccentGreen1, iconAccentGreen2, iconAccentGreen3, iconAccentGreen4,
          iconAccentGreen5, iconAccentGreen6, iconAccentGreen7],
         [iconAccentRed1, iconAccentRed2, iconAccentRed3, iconAccentRed4,
          iconAccentRed5, iconAccentRed6, iconAccentRed7],
         [iconAccentBlue1, iconAccentBlue2, iconAccentBlue3, iconAccentBlue4,
          iconAccentBlue5, iconAccentBlue6, iconAccentBlue7],
         [iconAccentCyan1, iconAccentCyan2, iconAccentCyan3, iconAccentCyan4,
          iconAccentCyan5, iconAccentCyan6, iconAccentCyan7],
         [iconAccentOrange1, iconAccentOrange2, iconAccentOrange3, iconAccentOrange4,
          iconAccentOrange5, iconAccentOrange6, iconAccentOrange7],
         [iconAccentPink1, iconAccentPink2, iconAccentPink3, iconAccentPink4,
          iconAccentPink5, iconAccentPink6, iconAccentPink7]]
    }

    public var backgroundColors: [UIColor] { families.flatMap { $0 } }
    public var letterColors: [UIColor] { backgroundColors.map { _ in .white } }

    public init() {}
}
