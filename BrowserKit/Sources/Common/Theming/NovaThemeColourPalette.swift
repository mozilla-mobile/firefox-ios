// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Nova only Figma tokens.  Corresponding `ThemeColourPalette` properties are forward to these.
public protocol NovaThemeColourPalette: ThemeColourPalette {
    var layerAccentSubtle: UIColor { get }
    var gradient: Gradient { get }
    var gradientAccent: Gradient { get }
    var gradientAccentSubtle: Gradient { get }
    var gradientAIStrong: Gradient { get }
    var gradientAISubtle: Gradient { get }
    var gradientTabBorder: Gradient { get }
    var gradientPrivacy: Gradient { get }
    var gradientPrivacyMask: Gradient { get }
}
