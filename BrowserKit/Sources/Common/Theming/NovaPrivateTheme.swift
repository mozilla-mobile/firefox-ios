// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct NovaPrivateTheme: Theme {
    public var type: ThemeType = .privateMode
    public var colors: ThemeColourPalette = NovaPrivateColourPalette()

    public init() {}
}

private struct NovaPrivateColourPalette: ThemeColourPalette {
    var base = NovaDarkColourPalette()

    var layer1: UIColor = NovaColors.VioletDesaturated90
    var layer2: UIColor = NovaColors.VioletDesaturated70
    var layer3: UIColor = NovaColors.VioletDesaturated70
    var layer4: UIColor = NovaColors.VioletDesaturated80
    var layer5: UIColor = NovaColors.VioletDesaturated80
    var layer5Hover: UIColor = NovaColors.VioletDesaturated70
    var layerScrim: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.95)
    var layerGradient = Gradient(colors: [NovaColors.Violet60, NovaColors.Violet50])
    var layerGradientOverlay = Gradient(colors: [
        NovaColors.Violet30.withAlphaComponent(0),
        NovaColors.Violet30.withAlphaComponent(0.4)
    ])
    var layerAccentNonOpaque: UIColor = NovaColors.Violet70
    var layerAccentPrivate: UIColor = NovaColors.Violet70
    var layerAccentPrivateNonOpaque: UIColor = NovaColors.Violet70.withAlphaComponent(0.4)
    var layerSepia: UIColor = NovaColors.Yellow0
    var layerHomepage = Gradient(colors: [
        NovaColors.VioletDesaturated90,
        NovaColors.VioletDesaturated80,
        NovaColors.VioletDesaturated70
    ])
    var layerInformation: UIColor = NovaColors.Blue70
    var layerSuccess: UIColor = NovaColors.Green70
    var layerWarning: UIColor = NovaColors.Yellow70
    var layerCritical: UIColor = NovaColors.Red70
    var layerCriticalSubdued: UIColor = NovaColors.Red70.withAlphaComponent(0.7)
    var layerSelectedText: UIColor = NovaColors.VioletDesaturated30.withAlphaComponent(0.55)
    var layerAutofillText: UIColor = NovaColors.Gray45.withAlphaComponent(0.81)
    var layerEmphasis: UIColor = NovaColors.VioletDesaturated80
    var layerGradientURL = Gradient(colors: [
        NovaColors.VioletDesaturated90.withAlphaComponent(0),
        NovaColors.VioletDesaturated90
    ])
    var layerSurfaceLow = NovaColors.VioletDesaturated90
    var layerSurfaceMedium = NovaColors.VioletDesaturated80
    var layerSurfaceMediumAlpha = NovaColors.VioletDesaturated80.withAlphaComponent(0.4)
    var layerSurfaceMediumAlt = NovaColors.VioletDesaturated70
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
    var actionTabActive: UIColor = NovaColors.VioletDesaturated80
    var actionTabInactive: UIColor = NovaColors.VioletDesaturated90
    var actionCloseButton: UIColor = NovaColors.VioletDesaturated80

    var textPrimary: UIColor { base.textPrimary }
    var textSecondary: UIColor { base.textSecondary }
    var textDisabled: UIColor { base.textDisabled }
    var textCritical: UIColor { base.textCritical }
    var textAccent: UIColor { base.textAccent }
    var textOnDark: UIColor { base.textOnDark }
    var textOnLight: UIColor { base.textOnLight }
    var textInverted: UIColor { base.textInverted }
    var textInvertedDisabled: UIColor { base.textInvertedDisabled }

    var iconPrimary: UIColor { base.iconPrimary }
    var iconSecondary: UIColor { base.iconSecondary }
    var iconDisabled: UIColor { base.iconDisabled }
    var iconAccent: UIColor { base.iconAccent }
    var iconOnColor: UIColor { base.iconOnColor }
    var iconCritical: UIColor { base.iconCritical }
    var iconSpinner: UIColor { base.iconSpinner }
    var iconAccentViolet: UIColor { base.iconAccentViolet }
    var iconAccentBlue: UIColor { base.iconAccentBlue }
    var iconAccentPink: UIColor { base.iconAccentPink }
    var iconAccentGreen: UIColor { base.iconAccentGreen }
    var iconAccentYellow: UIColor { base.iconAccentYellow }
    var iconRatingNeutral: UIColor { base.iconRatingNeutral }
    var iconAccentGreen1: UIColor { base.iconAccentGreen1 }
    var iconAccentGreen2: UIColor { base.iconAccentGreen2 }
    var iconAccentGreen3: UIColor { base.iconAccentGreen3 }
    var iconAccentGreen4: UIColor { base.iconAccentGreen4 }
    var iconAccentGreen5: UIColor { base.iconAccentGreen5 }
    var iconAccentGreen6: UIColor { base.iconAccentGreen6 }
    var iconAccentGreen7: UIColor { base.iconAccentGreen7 }
    var iconAccentCyan1: UIColor { base.iconAccentCyan1 }
    var iconAccentCyan2: UIColor { base.iconAccentCyan2 }
    var iconAccentCyan3: UIColor { base.iconAccentCyan3 }
    var iconAccentCyan4: UIColor { base.iconAccentCyan4 }
    var iconAccentCyan5: UIColor { base.iconAccentCyan5 }
    var iconAccentCyan6: UIColor { base.iconAccentCyan6 }
    var iconAccentCyan7: UIColor { base.iconAccentCyan7 }
    var iconAccentBlue1: UIColor { base.iconAccentBlue1 }
    var iconAccentBlue2: UIColor { base.iconAccentBlue2 }
    var iconAccentBlue3: UIColor { base.iconAccentBlue3 }
    var iconAccentBlue4: UIColor { base.iconAccentBlue4 }
    var iconAccentBlue5: UIColor { base.iconAccentBlue5 }
    var iconAccentBlue6: UIColor { base.iconAccentBlue6 }
    var iconAccentBlue7: UIColor { base.iconAccentBlue7 }
    var iconAccentYellow1: UIColor { base.iconAccentYellow1 }
    var iconAccentYellow2: UIColor { base.iconAccentYellow2 }
    var iconAccentYellow3: UIColor { base.iconAccentYellow3 }
    var iconAccentYellow4: UIColor { base.iconAccentYellow4 }
    var iconAccentYellow5: UIColor { base.iconAccentYellow5 }
    var iconAccentYellow6: UIColor { base.iconAccentYellow6 }
    var iconAccentYellow7: UIColor { base.iconAccentYellow7 }
    var iconAccentOrange1: UIColor { base.iconAccentOrange1 }
    var iconAccentOrange2: UIColor { base.iconAccentOrange2 }
    var iconAccentOrange3: UIColor { base.iconAccentOrange3 }
    var iconAccentOrange4: UIColor { base.iconAccentOrange4 }
    var iconAccentOrange5: UIColor { base.iconAccentOrange5 }
    var iconAccentOrange6: UIColor { base.iconAccentOrange6 }
    var iconAccentOrange7: UIColor { base.iconAccentOrange7 }
    var iconAccentRed1: UIColor { base.iconAccentRed1 }
    var iconAccentRed2: UIColor { base.iconAccentRed2 }
    var iconAccentRed3: UIColor { base.iconAccentRed3 }
    var iconAccentRed4: UIColor { base.iconAccentRed4 }
    var iconAccentRed5: UIColor { base.iconAccentRed5 }
    var iconAccentRed6: UIColor { base.iconAccentRed6 }
    var iconAccentRed7: UIColor { base.iconAccentRed7 }

    var borderPrimary: UIColor = NovaColors.VioletDesaturated70
    var borderSecondary: UIColor = NovaColors.VioletDesaturated80
    var borderAccent: UIColor = NovaColors.Violet30
    var borderAccentNonOpaque: UIColor = NovaColors.Violet30.withAlphaComponent(0.4)
    var borderAccentPrivate: UIColor = NovaColors.Violet70
    var borderInverted: UIColor = NovaColors.Gray15
    var borderToolbarDivider: UIColor = NovaColors.VioletDesaturated90

    var shadowSubtle: UIColor { base.shadowSubtle }
    var shadowDefault: UIColor { base.shadowDefault }
    var shadowStrong: UIColor { base.shadowStrong }
    var shadowBorder: UIColor { base.shadowBorder }

    var gradientOnboardingStop1: UIColor { base.gradientOnboardingStop1 }
    var gradientOnboardingStop2: UIColor { base.gradientOnboardingStop2 }
    var gradientOnboardingStop3: UIColor { base.gradientOnboardingStop3 }
    var gradientOnboardingStop4: UIColor { base.gradientOnboardingStop4 }
    var gradientAIStrongStop1: UIColor { base.gradientAIStrongStop1 }
    var gradientAIStrongStop2: UIColor { base.gradientAIStrongStop2 }
    var gradientAIStrongStop3: UIColor { base.gradientAIStrongStop3 }
}
