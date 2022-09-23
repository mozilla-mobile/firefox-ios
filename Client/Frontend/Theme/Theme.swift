// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

/// The `Theme` protocol, which contains the implementation of themes,
/// which comprise of a set of standardized colours (including light and
/// dark mode) and fonts for the application.
protocol Theme {
    var type: ThemeType { get }
    var colors: ThemeColourPalette { get }
}

struct Gradient {
    var start: UIColor
    var end: UIColor
}

/// The colour palette for a theme.
protocol ThemeColourPalette {

    // MARK: - Layers
    var layer1: UIColor { get }
    var layer2: UIColor { get }
    var layer3: UIColor { get }
    var layer4: UIColor { get }
    var layer5: UIColor { get }
    var layerScrim: UIColor { get }
    var layerGradient: Gradient { get }
    var layerAccentNonOpaque: UIColor { get }
    var layerAccentPrivate: UIColor { get }
    var layerAccentPrivateNonOpaque: UIColor { get }
    var layerLightGrey30: UIColor { get }

    // MARK: - Actions
    var actionPrimary: UIColor { get }
    var actionPrimaryHover: UIColor { get }
    var actionSecondary: UIColor { get }
    var actionSecondaryHover: UIColor { get }
    var formSurfaceOff: UIColor { get }
    var formKnob: UIColor { get }
    var indicatorActive: UIColor { get }
    var indicatorInactive: UIColor { get }

    // MARK: - Text
    var textPrimary: UIColor { get }
    var textSecondary: UIColor { get }
    var textDisabled: UIColor { get }
    var textWarning: UIColor { get }
    var textAccent: UIColor { get }
    var textOnColor: UIColor { get }
    var textInverted: UIColor { get }

    // MARK: - Icons
    var iconPrimary: UIColor { get }
    var iconSecondary: UIColor { get }
    var iconDisabled: UIColor { get }
    var iconAction: UIColor { get }
    var iconOnColor: UIColor { get }
    var iconWarning: UIColor { get }
    var iconAccentViolet: UIColor { get }
    var iconAccentBlue: UIColor { get }
    var iconAccentPink: UIColor { get }
    var iconAccentGreen: UIColor { get }
    var iconAccentYellow: UIColor { get }

    // MARK: - Border
    var borderPrimary: UIColor { get }
    var borderAccent: UIColor { get }
    var borderAccentNonOpaque: UIColor { get }
    var borderAccentPrivate: UIColor { get }

    // MARK: - Shadow
    var shadow: UIColor { get }
}
