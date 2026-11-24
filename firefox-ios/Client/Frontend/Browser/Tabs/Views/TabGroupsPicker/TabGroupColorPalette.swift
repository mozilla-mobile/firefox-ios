// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

enum TabGroupColorPalette {
    struct Option: Identifiable {
        let id: String
        let localizedName: String
        let colorToken: KeyPath<ThemeColourPalette, UIColor>
        let gradientToken: KeyPath<ThemeColourPalette, Gradient>

        var color: CodableColor { TabGroupColorPalette.storedColor(for: colorToken) }
    }

    static var defaultColor: CodableColor { storedColor(for: \.tabGroupNoColor) }

    static var options: [Option] {
        [
            Option(id: "default",
                   localizedName: String.TabGroups.ColorNames.Default,
                   colorToken: \.tabGroupNoColor,
                   gradientToken: \.gradientTabBorderNoColor),
            Option(id: "red",
                   localizedName: String.TabGroups.ColorNames.Red,
                   colorToken: \.tabGroupRed,
                   gradientToken: \.gradientTabBorderRed),
            Option(id: "orange",
                   localizedName: String.TabGroups.ColorNames.Orange,
                   colorToken: \.tabGroupOrange,
                   gradientToken: \.gradientTabBorderOrange),
            Option(id: "yellow",
                   localizedName: String.TabGroups.ColorNames.Yellow,
                   colorToken: \.tabGroupYellow,
                   gradientToken: \.gradientTabBorderYellow),
            Option(id: "green",
                   localizedName: String.TabGroups.ColorNames.Green,
                   colorToken: \.tabGroupGreen,
                   gradientToken: \.gradientTabBorderGreen),
            Option(id: "cyan",
                   localizedName: String.TabGroups.ColorNames.Cyan,
                   colorToken: \.tabGroupCyan,
                   gradientToken: \.gradientTabBorderCyan),
            Option(id: "blue",
                   localizedName: String.TabGroups.ColorNames.Blue,
                   colorToken: \.tabGroupBlue,
                   gradientToken: \.gradientTabBorderBlue),
            Option(id: "purple",
                   localizedName: String.TabGroups.ColorNames.Purple,
                   colorToken: \.tabGroupPurple,
                   gradientToken: \.gradientTabBorderPurple),
            Option(id: "pink",
                   localizedName: String.TabGroups.ColorNames.Pink,
                   colorToken: \.tabGroupPink,
                   gradientToken: \.gradientTabBorderPink),
            Option(id: "gray",
                   localizedName: String.TabGroups.ColorNames.Gray,
                   colorToken: \.tabGroupGrey,
                   gradientToken: \.gradientTabBorderGrey)
        ]
    }

    static func color(for saved: CodableColor, theme: any Theme) -> UIColor {
        guard theme.isNova, let option = option(for: saved) else {
            let traits = UITraitCollection(userInterfaceStyle: theme.type.getInterfaceStyle())
            return saved.uiColor.resolvedColor(with: traits)
        }
        return theme.colors[keyPath: option.colorToken]
    }

    static func borderGradient(for saved: CodableColor, theme: any Theme) -> Gradient {
        guard theme.isNova, let option = option(for: saved) else {
            let resolved = color(for: saved, theme: theme)
            return Gradient(colors: [resolved, resolved])
        }
        return theme.colors[keyPath: option.gradientToken]
    }

    static func isDefault(_ saved: CodableColor) -> Bool { optionID(for: saved) == "default" }

    static func optionID(for saved: CodableColor) -> String? { option(for: saved)?.id }

    private static func option(for saved: CodableColor) -> Option? {
        options.first { $0.color == saved }
    }

    private static func storedColor(for token: KeyPath<ThemeColourPalette, UIColor>) -> CodableColor {
        let light = NovaLightTheme().colors[keyPath: token]
        let dark = NovaDarkTheme().colors[keyPath: token]
        let color = UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
        guard let stored = CodableColor(uiColor: color) else {
            preconditionFailure("Tab group color tokens must resolve to sRGB.")
        }
        return stored
    }
}
