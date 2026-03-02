// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A theme that carries a tinted colour palette derived from accent color selection.
public struct TintedTheme: Theme {
    public var type: ThemeType
    public var colors: ThemeColourPalette

    public init(type: ThemeType, colors: TintedThemeColourPalette) {
        self.type = type
        self.colors = colors
    }
}
