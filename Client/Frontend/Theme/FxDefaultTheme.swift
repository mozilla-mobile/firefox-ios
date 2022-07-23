// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

// This file contains the default theme for iOS, as outlined in Figma.
// While no fonts have yet been implemented, they will be part of the
// themeing system, and as such, have been roughly included.

struct FxDefaultTheme: Theme {
    var colours: ThemeColourPalette = FxDefaultColourPalette()
    var fonts: ThemeFontPalette = FxDefaultFontPalette()
}

private struct FxDefaultColourPalette: ThemeColourPalette {
    // Generally, force unwrapping should be avoided. However,
    // because we expect to ship these colours, we should force
    // unwrap to force a crash in case that these colours aren't found.
    var actionPrimary: UIColor {
        UIColor(named: "ActionPrimary")!
    }
    var actionSecondary: UIColor {
        UIColor(named: "ActionSecondary")!
    }
    var borderDivider: UIColor {
        UIColor(named: "BorderDivider")!
    }
    var borderSelectedDefault: UIColor {
        UIColor(named: "BorderSelectedDefault")!
    }
    var borderSelectedPrivate: UIColor {
        UIColor(named: "BorderSelectedPrivate")!
    }
    var controlActive: UIColor {
        UIColor(named: "ControlActive")!
    }
    var controlBase: UIColor {
        UIColor(named: "ControlBase")!
    }
    var iconAccentBlue: UIColor {
        UIColor(named: "IconAccentBlue")!
    }
    var iconAccentGreen: UIColor {
        UIColor(named: "IconAccentGreen")!
    }
    var iconAccentPink: UIColor {
        UIColor(named: "IconAccentPink")!
    }
    var iconAccentViolet: UIColor {
        UIColor(named: "IconAccentViolet")!
    }
    var iconAccentYellow: UIColor {
        UIColor(named: "IconAccentYellow")!
    }
    var iconDisabled: UIColor {
        UIColor(named: "IconDisabled")!
    }
    var iconInverted: UIColor {
        UIColor(named: "IconInverted")!
    }
    var iconPrimary: UIColor {
        UIColor(named: "IconPrimary")!
    }
    var iconSecondary: UIColor {
        UIColor(named: "IconSecondary")!
    }
    var layer1: UIColor {
        UIColor(named: "Layer1")!
    }
    var layer2: UIColor {
        UIColor(named: "Layer2")!
    }
    var layer2Blur: UIColor {
        UIColor(named: "Layer2Blur")!
    }
    var layer3: UIColor {
        UIColor(named: "Layer3")!
    }
    var layer4: UIColor {
        UIColor(named: "Layer4")!
    }
    var layerEmphasis: UIColor {
        UIColor(named: "LayerEmphasis")!
    }
    var scrim: UIColor {
        UIColor(named: "Scrim")!
    }
    var textDisabled: UIColor {
        UIColor(named: "TextDisabled")!
    }
    var textInverted: UIColor {
        UIColor(named: "TextInverted")!
    }
    var textLink: UIColor {
        UIColor(named: "TextLink")!
    }
    var textPrimary: UIColor {
        UIColor(named: "TextPrimary")!
    }
    var textSecondary: UIColor {
        UIColor(named: "TextSecondary")!
    }
    var textWarning: UIColor {
        UIColor(named: "TextWarning")!
    }
}

private struct FxDefaultFontPalette: ThemeFontPalette {

}
