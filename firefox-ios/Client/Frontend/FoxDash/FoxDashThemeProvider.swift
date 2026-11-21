// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Provides the identifier of the theme folder under `Assets/FoxDash/themes` the game should load.
protocol FoxDashThemeProviding {
    var themeID: String { get }
}

struct FoxDashThemeProvider: FoxDashThemeProviding {
    var themeID: String {
        return FxNimbus.shared.features.foxDashFeature.value().theme.rawValue
    }
}
