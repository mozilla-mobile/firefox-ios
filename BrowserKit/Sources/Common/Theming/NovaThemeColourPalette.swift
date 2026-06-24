// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// Nova only Figma tokens.
// TODO: These tokens will be used when updating components design
public protocol NovaThemeColourPalette: ThemeColourPalette {
    var layerAccentSubtle: UIColor { get }
    var layerInverse: UIColor { get }
    var layerGlassTintNova: UIColor { get }

    var textToast: UIColor { get }
    var iconInverted: UIColor { get }
    var iconOnColorDisabled: UIColor { get }
    var iconPrivate: UIColor { get }
    var iconPrivateOutline: UIColor { get }

    var borderStrong: UIColor { get }
    var borderOnColor: UIColor { get }
    var borderRadioButtonDefault: UIColor { get }

    var gradient: Gradient { get }
    var gradientAccent: Gradient { get }
    var gradientAccentSubtle: Gradient { get }
    var gradientAIStrong: Gradient { get }
    var gradientAISubtle: Gradient { get }
    var gradientBorder: Gradient { get }
    var gradientPrivacy: Gradient { get }
    var gradientPrivacyMask: Gradient { get }
}
