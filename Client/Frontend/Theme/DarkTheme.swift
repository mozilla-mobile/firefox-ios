// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

struct DarkTheme: Theme {
    var type: ThemeType = .dark
    var colors: ThemeColourPalette = DarkColourPalette()
}

private struct DarkColourPalette: ThemeColourPalette {
    // MARK: - Layers
    var layer1: UIColor = FXColors.DarkGrey60
    var layer2: UIColor = FXColors.DarkGrey30
    var layer3: UIColor = FXColors.DarkGrey80
    var layer4: UIColor = FXColors.DarkGrey20.withAlphaComponent(0.7)
    var layer5: UIColor = FXColors.DarkGrey40
    var layerScrim: UIColor = FXColors.DarkGrey90.withAlphaComponent(0.95)
    var layerGradient: Gradient = Gradient(start: FXColors.Violet70, end: FXColors.Violet40)
    var layerAccentNonOpaque: UIColor = FXColors.Blue20.withAlphaComponent(0.2)
    var layerAccentPrivate: UIColor = FXColors.Purple60
    var layerAccentPrivateNonOpaque: UIColor = FXColors.Purple60.withAlphaComponent(0.3)
    var layerLightGrey30: UIColor = FXColors.LightGrey30

    // MARK: - Actions
    var actionPrimary: UIColor = FXColors.Blue20
    var actionPrimaryHover: UIColor = FXColors.Blue10
    var actionSecondary: UIColor = FXColors.LightGrey30
    var actionSecondaryHover: UIColor = FXColors.LightGrey20
    var formSurfaceOff: UIColor = FXColors.DarkGrey05
    var formKnob: UIColor = FXColors.White
    var indicatorActive: UIColor = FXColors.LightGrey90
    var indicatorInactive: UIColor = FXColors.DarkGrey05

    // MARK: - Text
    var textPrimary: UIColor = FXColors.LightGrey05
    var textSecondary: UIColor = FXColors.LightGrey40
    var textDisabled: UIColor = FXColors.LightGrey05.withAlphaComponent(0.4)
    var textWarning: UIColor = FXColors.Red20
    var textAccent: UIColor = FXColors.Blue20
    var textOnColor: UIColor = FXColors.LightGrey05
    var textInverted: UIColor = FXColors.DarkGrey90

    // MARK: - Icons
    var iconPrimary: UIColor = FXColors.LightGrey05
    var iconSecondary: UIColor = FXColors.LightGrey40
    var iconDisabled: UIColor = FXColors.LightGrey05.withAlphaComponent(0.4)
    var iconAction: UIColor = FXColors.Blue20
    var iconOnColor: UIColor = FXColors.LightGrey05
    var iconWarning: UIColor = FXColors.Red20
    var iconAccentViolet: UIColor = FXColors.Violet20
    var iconAccentBlue: UIColor = FXColors.Blue20
    var iconAccentPink: UIColor = FXColors.Pink20
    var iconAccentGreen: UIColor = FXColors.Green20
    var iconAccentYellow: UIColor = FXColors.Yellow20

    // MARK: - Border
    var borderPrimary: UIColor = FXColors.DarkGrey05
    var borderAccent: UIColor = FXColors.Blue20
    var borderAccentNonOpaque: UIColor = FXColors.Blue20.withAlphaComponent(0.2)
    var borderAccentPrivate: UIColor = FXColors.Purple60

    // MARK: - Shadow
    var shadow: UIColor = FXColors.DarkGrey90.withAlphaComponent(0.16)
}
