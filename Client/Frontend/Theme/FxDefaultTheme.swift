/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct FxDefaultTheme: Theme {

    var colours: ThemeColourPalette = FxDefaultColourPalette()
    var fonts: ThemeFontPalette = FxDefaultFontPalette()
}

fileprivate struct FxDefaultColourPalette: ThemeColourPalette {
    // Generally, force unwrapping should be avoided. However,
    // because we expect to ship these colours, we should force
    // unwrap to force a crash in case that these colours aren't found.
    var layer1: UIColor { return UIColor(named: "Layer1")! }
}

fileprivate struct FxDefaultFontPalette: ThemeFontPalette {

}
