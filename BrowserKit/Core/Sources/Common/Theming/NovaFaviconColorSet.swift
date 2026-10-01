// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct NovaFaviconColorSet: FaviconLetterColorSet {
    public let iconAccentGreen1 = NovaColors.Green10
    public let iconAccentGreen2 = NovaColors.Green20
    public let iconAccentGreen3 = NovaColors.Green30
    public let iconAccentGreen4 = NovaColors.Green40
    public let iconAccentGreen5 = NovaColors.Green50
    public let iconAccentGreen6 = NovaColors.Green60
    public let iconAccentGreen7 = NovaColors.Green70

    public let iconAccentCyan1 = NovaColors.Cyan10
    public let iconAccentCyan2 = NovaColors.Cyan20
    public let iconAccentCyan3 = NovaColors.Cyan30
    public let iconAccentCyan4 = NovaColors.Cyan40
    public let iconAccentCyan5 = NovaColors.Cyan50
    public let iconAccentCyan6 = NovaColors.Cyan60
    public let iconAccentCyan7 = NovaColors.Cyan70

    public let iconAccentBlue1 = NovaColors.Blue10
    public let iconAccentBlue2 = NovaColors.Blue20
    public let iconAccentBlue3 = NovaColors.Blue30
    public let iconAccentBlue4 = NovaColors.Blue40
    public let iconAccentBlue5 = NovaColors.Blue50
    public let iconAccentBlue6 = NovaColors.Blue60
    public let iconAccentBlue7 = NovaColors.Blue70

    public let iconAccentYellow1 = NovaColors.Yellow10
    public let iconAccentYellow2 = NovaColors.Yellow20
    public let iconAccentYellow3 = NovaColors.Yellow30
    public let iconAccentYellow4 = NovaColors.Yellow40
    public let iconAccentYellow5 = NovaColors.Yellow50
    public let iconAccentYellow6 = NovaColors.Yellow60
    public let iconAccentYellow7 = NovaColors.Yellow70

    public let iconAccentOrange1 = NovaColors.Orange10
    public let iconAccentOrange2 = NovaColors.Orange20
    public let iconAccentOrange3 = NovaColors.Orange30
    public let iconAccentOrange4 = NovaColors.Orange40
    public let iconAccentOrange5 = NovaColors.Orange50
    public let iconAccentOrange6 = NovaColors.Orange60
    public let iconAccentOrange7 = NovaColors.Orange70

    public let iconAccentRed1 = NovaColors.Red10
    public let iconAccentRed2 = NovaColors.Red20
    public let iconAccentRed3 = NovaColors.Red30
    public let iconAccentRed4 = NovaColors.Red40
    public let iconAccentRed5 = NovaColors.Red50
    public let iconAccentRed6 = NovaColors.Red60
    public let iconAccentRed7 = NovaColors.Red70

    // Not used by the Nova theme.
    public let iconAccentPink1: UIColor = .clear
    public let iconAccentPink2: UIColor = .clear
    public let iconAccentPink3: UIColor = .clear
    public let iconAccentPink4: UIColor = .clear
    public let iconAccentPink5: UIColor = .clear
    public let iconAccentPink6: UIColor = .clear
    public let iconAccentPink7: UIColor = .clear

    private var families: [[UIColor]] {
        [[iconAccentGreen1, iconAccentGreen2, iconAccentGreen3, iconAccentGreen4,
          iconAccentGreen5, iconAccentGreen6, iconAccentGreen7],
         [iconAccentCyan1, iconAccentCyan2, iconAccentCyan3, iconAccentCyan4,
          iconAccentCyan5, iconAccentCyan6, iconAccentCyan7],
         [iconAccentBlue1, iconAccentBlue2, iconAccentBlue3, iconAccentBlue4,
          iconAccentBlue5, iconAccentBlue6, iconAccentBlue7],
         [iconAccentYellow1, iconAccentYellow2, iconAccentYellow3, iconAccentYellow4,
          iconAccentYellow5, iconAccentYellow6, iconAccentYellow7],
         [iconAccentOrange1, iconAccentOrange2, iconAccentOrange3, iconAccentOrange4,
          iconAccentOrange5, iconAccentOrange6, iconAccentOrange7],
         [iconAccentRed1, iconAccentRed2, iconAccentRed3, iconAccentRed4,
          iconAccentRed5, iconAccentRed6, iconAccentRed7]]
    }

    public var backgroundColors: [UIColor] { families.flatMap { $0 } }
    public var letterColors: [UIColor] {
        families.flatMap { family in
            family.indices.map { $0 < 4 ? NovaColors.VioletDesaturated90 : NovaColors.VioletDesaturated0 }
        }
    }

    public init() {}
}
