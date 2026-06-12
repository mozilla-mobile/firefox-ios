// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct NovaDarkTheme: Theme {
    public var type: ThemeType = .dark
    public var colors: ThemeColourPalette = NovaDarkColourPalette()

    public init() {}
}

public struct NovaNightModeTheme: Theme {
    public var type: ThemeType = .nightMode
    public var colors: ThemeColourPalette = NovaDarkColourPalette()

    public init() {}
}

struct NovaDarkColourPalette: ThemeColourPalette {
    var layer1: UIColor = NovaColors.Gray80
    var layer2: UIColor = NovaColors.Gray60
    var layer3: UIColor = NovaColors.Gray60
    var layer4: UIColor = NovaColors.Gray70
    var layer5: UIColor = NovaColors.Gray70
    var layer5Hover: UIColor = NovaColors.Gray60
    var layerScrim: UIColor = NovaColors.Gray90.withAlphaComponent(0.95)
    var layerGradient = Gradient(colors: [NovaColors.Violet60, NovaColors.Violet50])
    var layerGradientOverlay = Gradient(colors: [
        NovaColors.Violet30.withAlphaComponent(0),
        NovaColors.Violet30.withAlphaComponent(0.4)
    ])
    var layerAccentNonOpaque: UIColor = NovaColors.VioletDesaturated70
    var layerAccentPrivate: UIColor = NovaColors.Violet70
    var layerAccentPrivateNonOpaque: UIColor = NovaColors.Violet70.withAlphaComponent(0.4)
    var layerSepia: UIColor = NovaColors.Yellow0
    var layerHomepage = Gradient(colors: [NovaColors.Gray80, NovaColors.Gray80, NovaColors.Gray80])
    var layerInformation: UIColor = NovaColors.Blue70
    var layerSuccess: UIColor = NovaColors.Green70
    var layerWarning: UIColor = NovaColors.Yellow70
    var layerCritical: UIColor = NovaColors.Red70
    var layerCriticalSubdued: UIColor = NovaColors.Red70.withAlphaComponent(0.7)
    var layerSelectedText: UIColor = NovaColors.VioletDesaturated30.withAlphaComponent(0.55)
    var layerAutofillText: UIColor = NovaColors.Gray45.withAlphaComponent(0.81)
    var layerEmphasis: UIColor = NovaColors.Gray70
    var layerGradientURL = Gradient(colors: [
        NovaColors.Gray70.withAlphaComponent(0),
        NovaColors.Gray70
    ])
    var layerSurfaceLow = NovaColors.Gray80
    var layerSurfaceMedium = NovaColors.Gray70
    var layerSurfaceMediumAlpha = NovaColors.Gray70.withAlphaComponent(0.4)
    var layerSurfaceMediumAlt = NovaColors.Gray60
    var layerGradientSummary = Gradient(colors: [
        NovaColors.Violet50,
        NovaColors.Pink40,
        NovaColors.Orange30
    ])

    var actionPrimary: UIColor = NovaColors.Violet30
    var actionPrimaryHover: UIColor = NovaColors.Violet40
    var actionPrimaryDisabled: UIColor = NovaColors.Violet30.withAlphaComponent(0.4)
    var actionSecondary: UIColor = NovaColors.Gray55
    var actionSecondaryDisabled: UIColor = NovaColors.Gray55.withAlphaComponent(0.5)
    var actionSecondaryHover: UIColor = NovaColors.Gray60
    var formSurfaceOff: UIColor = NovaColors.Gray55
    var formKnob: UIColor = NovaColors.White
    var indicatorActive: UIColor = NovaColors.Violet30
    var indicatorInactive: UIColor = NovaColors.Gray55
    var actionSuccess: UIColor = NovaColors.Green30
    var actionWarning: UIColor = NovaColors.Yellow30
    var actionCritical: UIColor = NovaColors.Red30
    var actionInformation: UIColor = NovaColors.Blue30
    var actionTabActive: UIColor = NovaColors.Gray70
    var actionTabInactive: UIColor = NovaColors.Gray80
    var actionCloseButton: UIColor = NovaColors.Gray70

    var textPrimary: UIColor = NovaColors.VioletDesaturated0
    var textSecondary: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.7)
    var textDisabled: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.4)
    var textCritical: UIColor = NovaColors.Red30
    var textAccent: UIColor = NovaColors.Violet30
    var textOnDark: UIColor = NovaColors.VioletDesaturated0
    var textOnLight: UIColor = NovaColors.VioletDesaturated90
    var textInverted: UIColor = NovaColors.VioletDesaturated90
    var textInvertedDisabled: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.4)

    var iconPrimary: UIColor = NovaColors.VioletDesaturated0
    var iconSecondary: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.7)
    var iconDisabled: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.4)
    var iconAccent: UIColor = NovaColors.Violet30
    var iconOnColor: UIColor = NovaColors.VioletDesaturated0
    var iconCritical: UIColor = NovaColors.Red30
    var iconSpinner: UIColor = NovaColors.Violet30
    var iconAccentViolet: UIColor = NovaColors.Violet30
    var iconAccentBlue: UIColor = NovaColors.Blue30
    var iconAccentPink: UIColor = NovaColors.Pink40
    var iconAccentGreen: UIColor = NovaColors.Green30
    var iconAccentYellow: UIColor = NovaColors.Yellow30
    var iconRatingNeutral: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.3)
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

    var borderPrimary: UIColor = NovaColors.Gray60
    var borderSecondary: UIColor = NovaColors.Gray55
    var borderAccent: UIColor = NovaColors.Violet30
    var borderAccentNonOpaque: UIColor = NovaColors.Violet30.withAlphaComponent(0.4)
    var borderAccentPrivate: UIColor = NovaColors.Violet70
    var borderInverted: UIColor = NovaColors.Gray15
    var borderToolbarDivider: UIColor = NovaColors.Gray80

    var shadowSubtle: UIColor = NovaColors.Gray80.withAlphaComponent(0.1)
    var shadowDefault: UIColor = NovaColors.Gray80.withAlphaComponent(0.12)
    var shadowStrong: UIColor = NovaColors.Gray80.withAlphaComponent(0.16)
    var shadowBorder: UIColor = NovaColors.Violet30

    var gradientOnboardingStop1: UIColor = NovaColors.Yellow50
    var gradientOnboardingStop2: UIColor = NovaColors.Blue50
    var gradientOnboardingStop3: UIColor = NovaColors.Red50
    var gradientOnboardingStop4: UIColor = NovaColors.Orange50
    var gradientAIStrongStop1: UIColor = NovaColors.Violet50
    var gradientAIStrongStop2: UIColor = NovaColors.Pink40
    var gradientAIStrongStop3: UIColor = NovaColors.Orange30
}
