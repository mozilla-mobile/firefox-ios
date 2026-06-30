// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct FaviconLetterColorSet: @unchecked Sendable {
    public let backgroundColors: [UIColor]
    public let letterColors: [UIColor]

    public init(backgroundColors: [UIColor], letterColors: [UIColor]) {
        self.backgroundColors = backgroundColors
        self.letterColors = letterColors
    }

    /// Set once at app launch from the Nova feature flag; defaults to legacy.
    nonisolated(unsafe) public static var isNovaDesignEnabled: () -> Bool = { false }

    /// The active palette, selected by `isNovaDesignEnabled`.
    public static var current: FaviconLetterColorSet {
        isNovaDesignEnabled() ? NovaFaviconAccentColors.palette : StandardFaviconAccentColors.palette
    }

    /// Assembles a palette from ordered color families; `letterColor` maps a shade index to its letter.
    static func make(families: [[UIColor]],
                     letterColor: (_ shade: Int) -> UIColor) -> FaviconLetterColorSet {
        return FaviconLetterColorSet(backgroundColors: families.flatMap { $0 },
                                     letterColors: families.flatMap { $0.indices.map(letterColor) })
    }
}

final class NovaFaviconAccentColors {
    static let iconAccentGreen1 = NovaColors.Green10
    static let iconAccentGreen2 = NovaColors.Green20
    static let iconAccentGreen3 = NovaColors.Green30
    static let iconAccentGreen4 = NovaColors.Green40
    static let iconAccentGreen5 = NovaColors.Green50
    static let iconAccentGreen6 = NovaColors.Green60
    static let iconAccentGreen7 = NovaColors.Green70

    static let iconAccentCyan1 = NovaColors.Cyan10
    static let iconAccentCyan2 = NovaColors.Cyan20
    static let iconAccentCyan3 = NovaColors.Cyan30
    static let iconAccentCyan4 = NovaColors.Cyan40
    static let iconAccentCyan5 = NovaColors.Cyan50
    static let iconAccentCyan6 = NovaColors.Cyan60
    static let iconAccentCyan7 = NovaColors.Cyan70

    static let iconAccentBlue1 = NovaColors.Blue10
    static let iconAccentBlue2 = NovaColors.Blue20
    static let iconAccentBlue3 = NovaColors.Blue30
    static let iconAccentBlue4 = NovaColors.Blue40
    static let iconAccentBlue5 = NovaColors.Blue50
    static let iconAccentBlue6 = NovaColors.Blue60
    static let iconAccentBlue7 = NovaColors.Blue70

    static let iconAccentYellow1 = NovaColors.Yellow10
    static let iconAccentYellow2 = NovaColors.Yellow20
    static let iconAccentYellow3 = NovaColors.Yellow30
    static let iconAccentYellow4 = NovaColors.Yellow40
    static let iconAccentYellow5 = NovaColors.Yellow50
    static let iconAccentYellow6 = NovaColors.Yellow60
    static let iconAccentYellow7 = NovaColors.Yellow70

    static let iconAccentOrange1 = NovaColors.Orange10
    static let iconAccentOrange2 = NovaColors.Orange20
    static let iconAccentOrange3 = NovaColors.Orange30
    static let iconAccentOrange4 = NovaColors.Orange40
    static let iconAccentOrange5 = NovaColors.Orange50
    static let iconAccentOrange6 = NovaColors.Orange60
    static let iconAccentOrange7 = NovaColors.Orange70

    static let iconAccentRed1 = NovaColors.Red10
    static let iconAccentRed2 = NovaColors.Red20
    static let iconAccentRed3 = NovaColors.Red30
    static let iconAccentRed4 = NovaColors.Red40
    static let iconAccentRed5 = NovaColors.Red50
    static let iconAccentRed6 = NovaColors.Red60
    static let iconAccentRed7 = NovaColors.Red70

    static let palette: FaviconLetterColorSet = {
        let greens = [iconAccentGreen1, iconAccentGreen2, iconAccentGreen3, iconAccentGreen4,
                      iconAccentGreen5, iconAccentGreen6, iconAccentGreen7]
        let cyans = [iconAccentCyan1, iconAccentCyan2, iconAccentCyan3, iconAccentCyan4,
                     iconAccentCyan5, iconAccentCyan6, iconAccentCyan7]
        let blues = [iconAccentBlue1, iconAccentBlue2, iconAccentBlue3, iconAccentBlue4,
                     iconAccentBlue5, iconAccentBlue6, iconAccentBlue7]
        let yellows = [iconAccentYellow1, iconAccentYellow2, iconAccentYellow3, iconAccentYellow4,
                       iconAccentYellow5, iconAccentYellow6, iconAccentYellow7]
        let oranges = [iconAccentOrange1, iconAccentOrange2, iconAccentOrange3, iconAccentOrange4,
                       iconAccentOrange5, iconAccentOrange6, iconAccentOrange7]
        let reds = [iconAccentRed1, iconAccentRed2, iconAccentRed3, iconAccentRed4,
                    iconAccentRed5, iconAccentRed6, iconAccentRed7]
        // The 3 darkest shades of each family use the on-dark letter; the lighter 4 the on-light one.
        return .make(families: [greens, cyans, blues, yellows, oranges, reds]) {
            $0 < 4 ? NovaColors.VioletDesaturated90 : NovaColors.VioletDesaturated0
        }
    }()
}

final class StandardFaviconAccentColors {
    static let iconAccentGreen1 = FXColors.FaviconGreen1
    static let iconAccentGreen2 = FXColors.FaviconGreen2
    static let iconAccentGreen3 = FXColors.FaviconGreen3
    static let iconAccentGreen4 = FXColors.FaviconGreen4
    static let iconAccentGreen5 = FXColors.FaviconGreen5
    static let iconAccentGreen6 = FXColors.FaviconGreen6
    static let iconAccentGreen7 = FXColors.FaviconGreen7

    static let iconAccentRed1 = FXColors.FaviconRed1
    static let iconAccentRed2 = FXColors.FaviconRed2
    static let iconAccentRed3 = FXColors.FaviconRed3
    static let iconAccentRed4 = FXColors.FaviconRed4
    static let iconAccentRed5 = FXColors.FaviconRed5
    static let iconAccentRed6 = FXColors.FaviconRed6
    static let iconAccentRed7 = FXColors.FaviconRed7

    static let iconAccentBlue1 = FXColors.FaviconBlue1
    static let iconAccentBlue2 = FXColors.FaviconBlue2
    static let iconAccentBlue3 = FXColors.FaviconBlue3
    static let iconAccentBlue4 = FXColors.FaviconBlue4
    static let iconAccentBlue5 = FXColors.FaviconBlue5
    static let iconAccentBlue6 = FXColors.FaviconBlue6
    static let iconAccentBlue7 = FXColors.FaviconBlue7

    static let iconAccentCyan1 = FXColors.FaviconCyan1
    static let iconAccentCyan2 = FXColors.FaviconCyan2
    static let iconAccentCyan3 = FXColors.FaviconCyan3
    static let iconAccentCyan4 = FXColors.FaviconCyan4
    static let iconAccentCyan5 = FXColors.FaviconCyan5
    static let iconAccentCyan6 = FXColors.FaviconCyan6
    static let iconAccentCyan7 = FXColors.FaviconCyan7

    static let iconAccentOrange1 = FXColors.FaviconOrange1
    static let iconAccentOrange2 = FXColors.FaviconOrange2
    static let iconAccentOrange3 = FXColors.FaviconOrange3
    static let iconAccentOrange4 = FXColors.FaviconOrange4
    static let iconAccentOrange5 = FXColors.FaviconOrange5
    static let iconAccentOrange6 = FXColors.FaviconOrange6
    static let iconAccentOrange7 = FXColors.FaviconOrange7

    static let iconAccentPink1 = FXColors.FaviconPink1
    static let iconAccentPink2 = FXColors.FaviconPink2
    static let iconAccentPink3 = FXColors.FaviconPink3
    static let iconAccentPink4 = FXColors.FaviconPink4
    static let iconAccentPink5 = FXColors.FaviconPink5
    static let iconAccentPink6 = FXColors.FaviconPink6
    static let iconAccentPink7 = FXColors.FaviconPink7

    static let palette: FaviconLetterColorSet = {
        let greens = [iconAccentGreen1, iconAccentGreen2, iconAccentGreen3, iconAccentGreen4,
                      iconAccentGreen5, iconAccentGreen6, iconAccentGreen7]
        let reds = [iconAccentRed1, iconAccentRed2, iconAccentRed3, iconAccentRed4,
                    iconAccentRed5, iconAccentRed6, iconAccentRed7]
        let blues = [iconAccentBlue1, iconAccentBlue2, iconAccentBlue3, iconAccentBlue4,
                     iconAccentBlue5, iconAccentBlue6, iconAccentBlue7]
        let cyans = [iconAccentCyan1, iconAccentCyan2, iconAccentCyan3, iconAccentCyan4,
                     iconAccentCyan5, iconAccentCyan6, iconAccentCyan7]
        let oranges = [iconAccentOrange1, iconAccentOrange2, iconAccentOrange3, iconAccentOrange4,
                       iconAccentOrange5, iconAccentOrange6, iconAccentOrange7]
        let pinks = [iconAccentPink1, iconAccentPink2, iconAccentPink3, iconAccentPink4,
                     iconAccentPink5, iconAccentPink6, iconAccentPink7]
        return .make(families: [greens, reds, blues, cyans, oranges, pinks]) { _ in .white }
    }()
}
