// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

/// The `Theme` protocol, which contains the implementation of themes,
/// which comprise of a set of standardized colours (including light and
/// dark mode) and fonts for the application.
protocol Theme {
    var colours: ThemeColourPalette { get }
    var fonts: ThemeFontPalette { get }
}

/// The colour palette for the theme.
protocol ThemeColourPalette {
    var actionPrimary: UIColor { get }
    var actionSecondary: UIColor { get }
    var borderDivider: UIColor { get }
    var borderSelectedDefault: UIColor { get }
    var borderSelectedPrivate: UIColor { get }
    var controlActive: UIColor { get }
    var controlBase: UIColor { get }
    var iconAccentBlue: UIColor { get }
    var iconAccentGreen: UIColor { get }
    var iconAccentPink: UIColor { get }
    var iconAccentViolet: UIColor { get }
    var iconAccentYellow: UIColor { get }
    var iconDisabled: UIColor { get }
    var iconInverted: UIColor { get }
    var iconPrimary: UIColor { get }
    var iconSecondary: UIColor { get }
    var layer1: UIColor { get }
    var layer2: UIColor { get }
    var layer2Blur: UIColor { get }
    var layer3: UIColor { get }
    var layerEmphasis: UIColor { get }
    var scrim: UIColor { get }
    var textDisabled: UIColor { get }
    var textInverted: UIColor { get }
    var textLink: UIColor { get }
    var textPrimary: UIColor { get }
    var textSecondary: UIColor { get }
    var textWarning: UIColor { get }
}

protocol ThemeFontPalette {

}

