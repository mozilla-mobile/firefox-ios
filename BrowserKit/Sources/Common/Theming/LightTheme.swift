// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct LightTheme: Theme {
    public var type: ThemeType = .light
    public var colors: ThemeColourPalette = LightColourPalette()

    public init() {}
}

private struct LightColourPalette: ThemeColourPalette {
    // MARK: - Layers
    var layer1: UIColor = FXColors.LightGrey10
    var layer2: UIColor = FXColors.White
    var layer3: UIColor = FXColors.LightGrey20
    var layer4: UIColor = FXColors.LightGrey30.withAlphaComponent(0.6)
    var layer5: UIColor = FXColors.White
    var layer5Hover: UIColor = FXColors.LightGrey20
    var layerScrim: UIColor = FXColors.DarkGrey30.withAlphaComponent(0.95)
    var layerGradient = Gradient(colors: [FXColors.Violet70, FXColors.Violet60])
    var layerGradientOverlay = Gradient(colors: [FXColors.DarkGrey40.withAlphaComponent(0),
                                                 FXColors.DarkGrey40.withAlphaComponent(0.4)])
    var layerAccentNonOpaque: UIColor = FXColors.Blue50.withAlphaComponent(0.3)
    var layerAccentPrivate: UIColor = FXColors.Purple60
    var layerAccentPrivateNonOpaque: UIColor = FXColors.Purple60.withAlphaComponent(0.1)
    var layerSepia: UIColor = FXColors.Orange05
    var layerHomepage = Gradient(colors: [
        FXColors.LightGrey10.withAlphaComponent(1),
        FXColors.LightGrey10.withAlphaComponent(1),
        FXColors.LightGrey10.withAlphaComponent(1)
    ])
    var layerInformation: UIColor = FXColors.Blue50.withAlphaComponent(0.44)
    var layerSuccess: UIColor = FXColors.Green20
    var layerWarning: UIColor = FXColors.Yellow20
    var layerCritical: UIColor = FXColors.Red10
    var layerSelectedText: UIColor = FXColors.Blue50
    var layerAutofillText: UIColor = FXColors.DarkGrey05.withAlphaComponent(0.73)
    var layerSearch: UIColor = FXColors.LightGrey30
    var layerGradientURL = Gradient(colors: [
        FXColors.LightGrey30.withAlphaComponent(0),
        FXColors.LightGrey30.withAlphaComponent(1)
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
    var actionPrimary: UIColor = FXColors.Blue50
    var actionPrimaryHover: UIColor = FXColors.Blue60
    var actionPrimaryDisabled: UIColor = FXColors.Blue50.withAlphaComponent(0.5)
    var actionSecondary: UIColor = FXColors.LightGrey30
    var actionSecondaryHover: UIColor = FXColors.LightGrey40
    var formSurfaceOff: UIColor = FXColors.LightGrey30
    var formKnob: UIColor = FXColors.White
    var indicatorActive: UIColor = FXColors.LightGrey50
    var indicatorInactive: UIColor = FXColors.LightGrey30
    var actionSuccess: UIColor = FXColors.Green60
    var actionWarning: UIColor = FXColors.Yellow60.withAlphaComponent(0.4)
    var actionCritical: UIColor = FXColors.Red30
    var actionInformation: UIColor = FXColors.Blue50
    var actionTabActive: UIColor = FXColors.White
    var actionTabInactive: UIColor = FXColors.LightGrey20

    // MARK: - Text
    var textPrimary: UIColor = FXColors.DarkGrey90
    var textSecondary: UIColor = FXColors.DarkGrey05
    var textDisabled: UIColor = FXColors.DarkGrey90.withAlphaComponent(0.4)
    var textCritical: UIColor = FXColors.Red70
    var textAccent: UIColor = FXColors.Blue50
    var textOnDark: UIColor = FXColors.LightGrey05
    var textOnLight: UIColor = FXColors.DarkGrey90
    var textInverted: UIColor = FXColors.LightGrey05
    var textInvertedDisabled: UIColor = FXColors.LightGrey05.withAlphaComponent(0.8)

    // MARK: - Icons
    var iconPrimary: UIColor = FXColors.DarkGrey90
    var iconSecondary: UIColor = FXColors.DarkGrey05
    var iconDisabled: UIColor = FXColors.DarkGrey90.withAlphaComponent(0.4)
    var iconAccent: UIColor = FXColors.Blue50
    var iconOnColor: UIColor = FXColors.LightGrey05
    var iconCritical: UIColor = FXColors.Red70
    var iconSpinner: UIColor = FXColors.LightGrey80
    var iconAccentViolet: UIColor = FXColors.Violet70
    var iconAccentBlue: UIColor = FXColors.Blue60
    var iconAccentPink: UIColor = FXColors.Pink60
    var iconAccentGreen: UIColor = FXColors.Green60
    var iconAccentYellow: UIColor = FXColors.Yellow60
    var iconRatingNeutral: UIColor = FXColors.LightGrey40

    // MARK: - Border
    var borderPrimary: UIColor = FXColors.LightGrey30
    var borderAccent: UIColor = FXColors.Blue50
    var borderAccentNonOpaque: UIColor = FXColors.Blue50.withAlphaComponent(0.1)
    var borderAccentPrivate: UIColor = FXColors.Purple60
    var borderInverted: UIColor = FXColors.LightGrey05
    var borderToolbarDivider: UIColor = FXColors.LightGrey10

    // MARK: - Shadow
    var shadowDefault: UIColor = FXColors.DarkGrey40.withAlphaComponent(0.12)
}
