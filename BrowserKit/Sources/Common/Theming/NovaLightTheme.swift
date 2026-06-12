// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct NovaLightTheme: Theme {
    public var type: ThemeType = .light
    public var colors: ThemeColourPalette = NovaLightColourPalette()

    public init() {}
}

private struct NovaLightColourPalette: ThemeColourPalette {
    var layer1: UIColor = NovaColors.Gray5
    var layer2: UIColor = NovaColors.White
    var layer3: UIColor = NovaColors.Gray10
    var layer4: UIColor = NovaColors.Gray15
    var layer5: UIColor = NovaColors.White
    var layer5Hover: UIColor = NovaColors.Gray10
    var layerScrim: UIColor = NovaColors.Gray80.withAlphaComponent(0.95)
    var layerGradient = Gradient(colors: [NovaColors.Violet60, NovaColors.Violet50])
    var layerGradientOverlay = Gradient(colors: [
        NovaColors.Violet30.withAlphaComponent(0),
        NovaColors.Violet30.withAlphaComponent(0.4)
    ])
    var layerAccentNonOpaque: UIColor = NovaColors.VioletDesaturated10
    var layerAccentPrivate: UIColor = NovaColors.Violet70
    var layerAccentPrivateNonOpaque: UIColor = NovaColors.VioletDesaturated10
    var layerSepia: UIColor = NovaColors.Yellow0
    var layerHomepage = Gradient(colors: [NovaColors.Gray5, NovaColors.Gray5, NovaColors.Gray5])
    var layerInformation: UIColor = NovaColors.Blue10
    var layerSuccess: UIColor = NovaColors.Green10
    var layerWarning: UIColor = NovaColors.Yellow10
    var layerCritical: UIColor = NovaColors.Red10
    var layerCriticalSubdued: UIColor = NovaColors.Red10.withAlphaComponent(0.7)
    var layerSelectedText: UIColor = NovaColors.VioletDesaturated40.withAlphaComponent(0.93)
    var layerAutofillText: UIColor = NovaColors.Gray40
    var layerEmphasis: UIColor = NovaColors.Gray15
    var layerGradientURL = Gradient(colors: [
        NovaColors.Gray15.withAlphaComponent(0),
        NovaColors.Gray15
    ])
    var layerSurfaceLow = NovaColors.Gray10
    var layerSurfaceMedium = NovaColors.White
    var layerSurfaceMediumAlpha = NovaColors.White.withAlphaComponent(0.4)
    var layerSurfaceMediumAlt = NovaColors.Gray15
    var layerGradientSummary = Gradient(colors: [
        NovaColors.Violet50,
        NovaColors.Pink40,
        NovaColors.Orange30
    ])

    var actionPrimary: UIColor = NovaColors.Violet50
    var actionPrimaryHover: UIColor = NovaColors.Violet60
    var actionPrimaryDisabled: UIColor = NovaColors.Violet50.withAlphaComponent(0.4)
    var actionSecondary: UIColor = NovaColors.Gray15
    var actionSecondaryDisabled: UIColor = NovaColors.Gray15.withAlphaComponent(0.4)
    var actionSecondaryHover: UIColor = NovaColors.Gray25
    var formSurfaceOff: UIColor = NovaColors.Gray15
    var formKnob: UIColor = NovaColors.White
    var indicatorActive: UIColor = NovaColors.Violet50
    var indicatorInactive: UIColor = NovaColors.Gray30
    var actionSuccess: UIColor = NovaColors.Green50
    var actionWarning: UIColor = NovaColors.Yellow50
    var actionCritical: UIColor = NovaColors.Red50
    var actionInformation: UIColor = NovaColors.Blue50
    var actionTabActive: UIColor = NovaColors.White
    var actionTabInactive: UIColor = NovaColors.Gray10
    var actionCloseButton: UIColor = NovaColors.White

    var textPrimary: UIColor = NovaColors.VioletDesaturated90
    var textSecondary: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.7)
    var textDisabled: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.4)
    var textCritical: UIColor = NovaColors.Red50
    var textAccent: UIColor = NovaColors.Violet50
    var textOnDark: UIColor = NovaColors.VioletDesaturated0
    var textOnLight: UIColor = NovaColors.VioletDesaturated90
    var textInverted: UIColor = NovaColors.VioletDesaturated0
    var textInvertedDisabled: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.4)

    var iconPrimary: UIColor = NovaColors.VioletDesaturated90
    var iconSecondary: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.7)
    var iconDisabled: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.4)
    var iconAccent: UIColor = NovaColors.Violet50
    var iconOnColor: UIColor = NovaColors.VioletDesaturated0
    var iconCritical: UIColor = NovaColors.Red50
    var iconSpinner: UIColor = NovaColors.Violet30
    var iconAccentViolet: UIColor = NovaColors.Violet50
    var iconAccentBlue: UIColor = NovaColors.Blue50
    var iconAccentPink: UIColor = NovaColors.Pink40
    var iconAccentGreen: UIColor = NovaColors.Green50
    var iconAccentYellow: UIColor = NovaColors.Yellow50
    var iconRatingNeutral: UIColor = NovaColors.Gray30
    var iconAccentGreen1: UIColor = NovaColors.Green10
    var iconAccentGreen2: UIColor = NovaColors.Green20
    var iconAccentGreen3: UIColor = NovaColors.Green30
    var iconAccentGreen4: UIColor = NovaColors.Green40
    var iconAccentGreen5: UIColor = NovaColors.Green50
    var iconAccentGreen6: UIColor = NovaColors.Green60
    var iconAccentGreen7: UIColor = NovaColors.Green70
    var iconAccentCyan1: UIColor = NovaColors.Cyan10
    var iconAccentCyan2: UIColor = NovaColors.Cyan20
    var iconAccentCyan3: UIColor = NovaColors.Cyan30
    var iconAccentCyan4: UIColor = NovaColors.Cyan40
    var iconAccentCyan5: UIColor = NovaColors.Cyan50
    var iconAccentCyan6: UIColor = NovaColors.Cyan60
    var iconAccentCyan7: UIColor = NovaColors.Cyan70
    var iconAccentBlue1: UIColor = NovaColors.Blue10
    var iconAccentBlue2: UIColor = NovaColors.Blue20
    var iconAccentBlue3: UIColor = NovaColors.Blue30
    var iconAccentBlue4: UIColor = NovaColors.Blue40
    var iconAccentBlue5: UIColor = NovaColors.Blue50
    var iconAccentBlue6: UIColor = NovaColors.Blue60
    var iconAccentBlue7: UIColor = NovaColors.Blue70
    var iconAccentYellow1: UIColor = NovaColors.Yellow10
    var iconAccentYellow2: UIColor = NovaColors.Yellow20
    var iconAccentYellow3: UIColor = NovaColors.Yellow30
    var iconAccentYellow4: UIColor = NovaColors.Yellow40
    var iconAccentYellow5: UIColor = NovaColors.Yellow50
    var iconAccentYellow6: UIColor = NovaColors.Yellow60
    var iconAccentYellow7: UIColor = NovaColors.Yellow70
    var iconAccentOrange1: UIColor = NovaColors.Orange10
    var iconAccentOrange2: UIColor = NovaColors.Orange20
    var iconAccentOrange3: UIColor = NovaColors.Orange30
    var iconAccentOrange4: UIColor = NovaColors.Orange40
    var iconAccentOrange5: UIColor = NovaColors.Orange50
    var iconAccentOrange6: UIColor = NovaColors.Orange60
    var iconAccentOrange7: UIColor = NovaColors.Orange70
    var iconAccentRed1: UIColor = NovaColors.Red10
    var iconAccentRed2: UIColor = NovaColors.Red20
    var iconAccentRed3: UIColor = NovaColors.Red30
    var iconAccentRed4: UIColor = NovaColors.Red40
    var iconAccentRed5: UIColor = NovaColors.Red50
    var iconAccentRed6: UIColor = NovaColors.Red60
    var iconAccentRed7: UIColor = NovaColors.Red70

    var borderPrimary: UIColor = NovaColors.Gray15
    var borderSecondary: UIColor = NovaColors.Gray10
    var borderAccent: UIColor = NovaColors.Violet30
    var borderAccentNonOpaque: UIColor = NovaColors.Violet30.withAlphaComponent(0.4)
    var borderAccentPrivate: UIColor = NovaColors.Violet70
    var borderInverted: UIColor = NovaColors.Gray60
    var borderToolbarDivider: UIColor = NovaColors.Gray10

    var shadowSubtle: UIColor = NovaColors.Gray60.withAlphaComponent(0.1)
    var shadowDefault: UIColor = NovaColors.Gray60.withAlphaComponent(0.12)
    var shadowStrong: UIColor = NovaColors.Gray60.withAlphaComponent(0.16)
    var shadowBorder: UIColor = NovaColors.Violet30

    var gradientOnboardingStop1: UIColor = NovaColors.Yellow50
    var gradientOnboardingStop2: UIColor = NovaColors.Blue50
    var gradientOnboardingStop3: UIColor = NovaColors.Red50
    var gradientOnboardingStop4: UIColor = NovaColors.Orange50
    var gradientAIStrongStop1: UIColor = NovaColors.Violet50
    var gradientAIStrongStop2: UIColor = NovaColors.Pink40
    var gradientAIStrongStop3: UIColor = NovaColors.Orange30
}
