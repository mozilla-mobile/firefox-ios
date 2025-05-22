// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct TabTrayPanelSwipeTheme: Theme {
    var type: ThemeType
    var colors: ThemeColourPalette

    init(from: Theme, to: Theme, progress: CGFloat) {
        let mixColor = Self.mixColors(from: from.colors, to: to.colors, progress: progress)

        let overrides = TabTrayPanelSwipePalette.PartialOverrides(
            layer1: mixColor(\.layer1),
            iconPrimary: mixColor(\.iconPrimary),
            textPrimary: mixColor(\.textPrimary),
            actionSecondary: mixColor(\.actionSecondary),
            layerScrim: mixColor(\.layerScrim),
            layer3: mixColor(\.layer3),
            textOnDark: mixColor(\.textOnDark),
            borderPrimary: mixColor(\.borderPrimary),
            borderAccent: mixColor(\.borderAccent),
            borderAccentPrivate: mixColor(\.borderAccentPrivate),
            shadowDefault: mixColor(\.shadowDefault),
            iconDisabled: mixColor(\.iconDisabled)
        )

        self.type = from.type
        self.colors = TabTrayPanelSwipePalette(base: from.colors, overrides: overrides)
    }

    private static func mixColors(
        from: ThemeColourPalette,
        to: ThemeColourPalette,
        progress: CGFloat
    ) -> (_ keyPath: KeyPath<ThemeColourPalette, UIColor>) -> UIColor {
        return { keyPath in
            let fromColor = from[keyPath: keyPath]
            let toColor = to[keyPath: keyPath]
            return mix(fromColor, toColor, progress: progress)
        }
    }

    private static func mix(_ from: UIColor, _ to: UIColor, progress: CGFloat) -> UIColor {
        let clamped = max(0, min(1, progress))
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(
            red: r1 + (r2 - r1) * clamped,
            green: g1 + (g2 - g1) * clamped,
            blue: b1 + (b2 - b1) * clamped,
            alpha: a1 + (a2 - a1) * clamped
        )
    }
}
