// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct PrivateModeTheme: Theme {
    public var type: ThemeType = .privateMode
    public var colors: ThemeColourPalette = PrivateModeColorPalette()

    public init() {}
}

private struct PrivateModeColorPalette: ThemeColourPalette {
    // MARK: - Layers
    var layer1: UIColor = FXColors.Violet90
    var layer2: UIColor = FXColors.Violet90
    var layer3: UIColor = FXColors.Ink90
    var layer4: UIColor = FXColors.DarkGrey20.withAlphaComponent(0.7)
    var layer5: UIColor = FXColors.Ink20
    var layer5Hover: UIColor = FXColors.DarkGrey40
    var layerScrim: UIColor = FXColors.DarkGrey90.withAlphaComponent(0.95)
    var layerGradient = Gradient(colors: [FXColors.Violet70, FXColors.Violet60])
    var layerGradientOverlay = Gradient(colors: [
        FXColors.DarkGrey40.withAlphaComponent(0),
        FXColors.DarkGrey40.withAlphaComponent(1)
    ])
    var layerAccentNonOpaque: UIColor = FXColors.Blue20.withAlphaComponent(0.2)
    var layerAccentPrivate: UIColor = FXColors.Purple60
    var layerAccentPrivateNonOpaque: UIColor = FXColors.Purple60.withAlphaComponent(0.3)
    var layerSepia: UIColor = FXColors.Orange05
    var layerHomepage = Gradient(colors: [
        FXColors.Ink05,
        FXColors.Violet80,
        FXColors.Purple70
    ])
    var layerInformation: UIColor = FXColors.Blue50
    var layerSuccess: UIColor = FXColors.Green80
    var layerWarning: UIColor = FXColors.Yellow70.withAlphaComponent(0.77)
    var layerCritical: UIColor = FXColors.Pink80
    var layerSelectedText: UIColor = FXColors.Blue40
    var layerAutofillText: UIColor = FXColors.Violet60
    var layerSearch: UIColor = FXColors.Ink90
    var layerGradientURL = Gradient(colors: [
        FXColors.Ink90.withAlphaComponent(0),
        FXColors.Ink90.withAlphaComponent(1)
    ])

    // MARK: - Ratings
    var layerRatingA: UIColor = FXColors.Green20
    var layerRatingASubdued: UIColor = FXColors.Green05.withAlphaComponent(0.7)
    var layerRatingB: UIColor = FXColors.Blue10
    var layerRatingBSubdued: UIColor = FXColors.Blue05.withAlphaComponent(0.4)
    var layerRatingC: UIColor = FXColors.Yellow20
    var layerRatingCSubdued: UIColor = FXColors.Yellow05.withAlphaComponent(0.7)
    var layerRatingD: UIColor = FXColors.Orange20
    var layerRatingDSubdued: UIColor = FXColors.Orange05.withAlphaComponent(0.7)
    var layerRatingF: UIColor = FXColors.Red30
    var layerRatingFSubdued: UIColor = FXColors.Red05.withAlphaComponent(0.6)

    // MARK: - Actions
    var actionPrimary: UIColor = FXColors.Blue30
    var actionPrimaryHover: UIColor = FXColors.Blue20
    var actionPrimaryDisabled: UIColor = FXColors.Blue30.withAlphaComponent(0.5)
    var actionSecondary: UIColor = FXColors.DarkGrey05
    var actionSecondaryHover: UIColor = FXColors.LightGrey90
    var formSurfaceOff: UIColor = FXColors.DarkGrey05
    var formKnob: UIColor = FXColors.White
    var indicatorActive: UIColor = FXColors.LightGrey90
    var indicatorInactive: UIColor = FXColors.DarkGrey05
    var actionSuccess: UIColor = FXColors.Green70
    var actionWarning: UIColor = FXColors.Yellow40.withAlphaComponent(0.41)
    var actionCritical: UIColor = FXColors.Pink70.withAlphaComponent(0.69)
    var actionInformation: UIColor = FXColors.Blue60
    var actionTabActive: UIColor = FXColors.Purple60
    var actionTabInactive: UIColor = FXColors.Ink90

    // MARK: - Text
    var textPrimary: UIColor = FXColors.LightGrey05
    var textSecondary: UIColor = FXColors.LightGrey40
    var textDisabled: UIColor = FXColors.LightGrey05.withAlphaComponent(0.4)
    var textCritical: UIColor = FXColors.Red20
    var textAccent: UIColor = FXColors.Blue30
    var textOnDark: UIColor = FXColors.LightGrey05
    var textOnLight: UIColor = FXColors.DarkGrey90
    var textInverted: UIColor = FXColors.DarkGrey90
    var textInvertedDisabled: UIColor = FXColors.DarkGrey90.withAlphaComponent(0.7)

    // MARK: - Icons
    var iconPrimary: UIColor = FXColors.LightGrey05
    var iconSecondary: UIColor = FXColors.LightGrey40
    var iconDisabled: UIColor = FXColors.LightGrey05.withAlphaComponent(0.4)
    var iconAccent: UIColor = FXColors.Blue30
    var iconOnColor: UIColor = FXColors.LightGrey05
    var iconCritical: UIColor = FXColors.Red20
    var iconSpinner: UIColor = FXColors.White
    var iconAccentViolet: UIColor = FXColors.Violet20
    var iconAccentBlue: UIColor = FXColors.Blue30
    var iconAccentPink: UIColor = FXColors.Pink20
    var iconAccentGreen: UIColor = FXColors.Green20
    var iconAccentYellow: UIColor = FXColors.Yellow20
    var iconRatingNeutral: UIColor = FXColors.LightGrey05.withAlphaComponent(0.3)

    // MARK: - Border
    var borderPrimary: UIColor = FXColors.Ink05
    var borderAccent: UIColor = FXColors.Purple60
    var borderAccentNonOpaque: UIColor = FXColors.Blue20.withAlphaComponent(0.2)
    var borderAccentPrivate: UIColor = FXColors.Purple60
    var borderInverted: UIColor = FXColors.DarkGrey90
    var borderToolbarDivider: UIColor = FXColors.Violet90

    // MARK: - Shadow
    var shadowDefault: UIColor = FXColors.DarkGrey80.withAlphaComponent(0.12)
}
