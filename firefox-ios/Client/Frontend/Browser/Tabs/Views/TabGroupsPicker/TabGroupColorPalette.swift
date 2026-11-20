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
        // Snapshots saved by the temporary palette before its tokens merged.
        fileprivate var legacyRGB: (light: Int, dark: Int)?

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
                   gradientToken: \.gradientTabBorderRed,
                   legacyRGB: (0xc52d4f, 0xff8090)),
            Option(id: "orange",
                   localizedName: String.TabGroups.ColorNames.Orange,
                   colorToken: \.tabGroupOrange,
                   gradientToken: \.gradientTabBorderOrange,
                   legacyRGB: (0xd24300, 0xff8f5d)),
            Option(id: "yellow",
                   localizedName: String.TabGroups.ColorNames.Yellow,
                   colorToken: \.tabGroupYellow,
                   gradientToken: \.gradientTabBorderYellow,
                   legacyRGB: (0xb26100, 0xf0a000)),
            Option(id: "green",
                   localizedName: String.TabGroups.ColorNames.Green,
                   colorToken: \.tabGroupGreen,
                   gradientToken: \.gradientTabBorderGreen,
                   legacyRGB: (0x008865, 0x2dc79e)),
            Option(id: "cyan",
                   localizedName: String.TabGroups.ColorNames.Cyan,
                   colorToken: \.tabGroupCyan,
                   gradientToken: \.gradientTabBorderCyan,
                   legacyRGB: (0x0a809f, 0x41bdda)),
            Option(id: "blue",
                   localizedName: String.TabGroups.ColorNames.Blue,
                   colorToken: \.tabGroupBlue,
                   gradientToken: \.gradientTabBorderBlue,
                   legacyRGB: (0x455fe7, 0x70abff)),
            Option(id: "purple",
                   localizedName: String.TabGroups.ColorNames.Purple,
                   colorToken: \.tabGroupPurple,
                   gradientToken: \.gradientTabBorderPurple,
                   legacyRGB: (0x764edd, 0xb393ff)),
            Option(id: "pink",
                   localizedName: String.TabGroups.ColorNames.Pink,
                   colorToken: \.tabGroupPink,
                   gradientToken: \.gradientTabBorderPink,
                   legacyRGB: (0xb32e9f, 0xf07dcd)),
            Option(id: "gray",
                   localizedName: String.TabGroups.ColorNames.Gray,
                   colorToken: \.tabGroupGrey,
                   gradientToken: \.gradientTabBorderGrey)
        ]
    }

    static func adaptiveColor(for saved: CodableColor) -> UIColor {
        option(for: saved)?.color.uiColor ?? saved.uiColor
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
        options.first { option in
            if option.color == saved { return true }
            if option.id == "default" {
                return legacyColor(light: 0x180e30, dark: 0xf2f0f8, alpha: 0.7) == saved
            }
            guard let legacy = option.legacyRGB else { return false }
            return legacyColor(light: legacy.light, dark: legacy.dark) == saved
        }
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

    private static func legacyColor(light: Int, dark: Int, alpha: CGFloat = 1) -> CodableColor? {
        CodableColor(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light).withAlphaComponent(alpha)
        })
    }
}
