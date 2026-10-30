// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct NovaLightTheme: Theme {
    public var type: ThemeType = .light
    private let palette = NovaLightColourPalette()
    public var colors: ThemeColourPalette { palette }
    public var isNova = true

    public init() {}
}

private struct NovaLightColourPalette: ThemeColourPalette {
    private let fallbackPalette: ThemeColourPalette = LightTheme().colors

    // MARK: - Layer

    var layer1: UIColor = NovaColors.Gray5
    var layer2: UIColor = NovaColors.White
    var layer3: UIColor = NovaColors.Gray10
    var layer4: UIColor = NovaColors.Gray15
    var layerSurfaceLow = NovaColors.Gray10
    var layerSurfaceMedium = NovaColors.White
    var layerSurfaceMediumAlt: UIColor = NovaColors.White
    var layerSurfaceMediumAltGlass = NovaColors.White
    var layerSurfaceMediumAlpha = NovaColors.White.withAlphaComponent(0.4)
    var layerAccentSubtle: UIColor = NovaColors.VioletDesaturated10
    var layerInverse: UIColor = NovaColors.Gray70
    var layerWarning: UIColor = NovaColors.Yellow10
    var layerSuccess: UIColor = NovaColors.Green10
    var layerCritical: UIColor = NovaColors.Red10
    var layerInformation: UIColor = NovaColors.Blue10
    var layerSepia: UIColor = NovaColors.Yellow0
    var layerAutofillText: UIColor = NovaColors.VioletDesaturated30
    var layerSelectedText: UIColor = NovaColors.VioletDesaturated30
    var layerGlassTintNova: UIColor = .clear
    var layerGlassSelectedFill: UIColor = NovaColors.Gray15
    var layerAccentPrivateNonOpaque: UIColor { layerAccentSubtle }
    var layerToolbarGlass: UIColor = NovaColors.Gray5

    // MARK: - Action

    var actionPrimary: UIColor = NovaColors.Violet50
    var actionPrimaryHover: UIColor = NovaColors.Violet60
    var actionPrimaryDisabled: UIColor = NovaColors.Violet50.withAlphaComponent(0.4)
    var actionSecondary: UIColor = NovaColors.Gray15
    var actionSecondaryHover: UIColor = NovaColors.Gray20
    var actionSecondaryDisabled: UIColor = NovaColors.Gray15.withAlphaComponent(0.4)
    var actionWarning: UIColor = NovaColors.Yellow50
    var actionSuccess: UIColor = NovaColors.Green50
    var actionCritical: UIColor = NovaColors.Red50
    var actionInformation: UIColor = NovaColors.Blue50
    var formKnob: UIColor = NovaColors.White
    var formSurfaceOff: UIColor = NovaColors.Gray15
    var actionTabActive: UIColor = NovaColors.White
    var actionTabInactive: UIColor = NovaColors.Gray10
    var actionCloseButton: UIColor = NovaColors.White

    // MARK: - Text

    var textPrimary: UIColor = NovaColors.VioletDesaturated90
    var textSecondary: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.7)
    var textDisabled: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.4)
    var textAccent: UIColor = NovaColors.Violet50
    var textCritical: UIColor = NovaColors.Red50
    var textInverted: UIColor = NovaColors.VioletDesaturated0
    var textInvertedDisabled: UIColor = NovaColors.VioletDesaturated0
    var textOnDark: UIColor = NovaColors.VioletDesaturated0
    var textOnLight: UIColor = NovaColors.VioletDesaturated90
    var textOnColorPrimary: UIColor = NovaColors.VioletDesaturated0
    var textToast: UIColor = NovaColors.Violet30

    // MARK: - Icon

    var iconPrimary: UIColor = NovaColors.VioletDesaturated90
    var iconSecondary: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.7)
    var iconDisabled: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.4)
    var iconAccent: UIColor = NovaColors.Violet50
    var iconCritical: UIColor = NovaColors.Red50
    var iconInverted: UIColor = NovaColors.VioletDesaturated0
    var iconOnColor: UIColor = NovaColors.VioletDesaturated0
    var iconOnColorDisabled: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.4)
    var iconSpinner: UIColor = NovaColors.Gray40
    var iconPrivate: UIColor = NovaColors.Violet50

    // MARK: - Border

    var borderPrimary: UIColor = NovaColors.Gray15
    var borderStrong: UIColor = NovaColors.Gray20
    var borderInverted: UIColor = NovaColors.Gray60
    var borderAccentToast: UIColor = NovaColors.Violet30
    var borderRadioButtonDefault: UIColor = NovaColors.Gray35

    // MARK: - Shadow

    var shadowSubtle: UIColor = NovaColors.Gray60.withAlphaComponent(0.10)
    var shadowDefault: UIColor = NovaColors.Gray60.withAlphaComponent(0.12)
    var shadowStrong: UIColor = NovaColors.Gray60.withAlphaComponent(0.16)
    var shadowBorder: UIColor = NovaColors.Gray65.withAlphaComponent(0.50)

    // MARK: - Gradients

    var gradient = Gradient(colors: [NovaColors.Violet60, NovaColors.Violet50])
    var gradientAccent = Gradient(colors: [NovaColors.Violet30, NovaColors.Orange30])
    var gradientAccentSubtle = Gradient(colors: [
        NovaColors.Violet10.withAlphaComponent(0.5),
        NovaColors.Orange10.withAlphaComponent(0.5)
    ])
    var gradientAIStrong = Gradient(colors: [
        NovaColors.Violet50,
        NovaColors.Pink40,
        NovaColors.Orange30
    ])
    var gradientBorder = Gradient(colors: [NovaColors.Violet30, NovaColors.Violet50])
    var gradientPrivacy = Gradient(colors: [
        NovaColors.Purple40,
        NovaColors.VioletDesaturated90
    ])
    var gradientPrivacyMask = Gradient(colors: [NovaColors.White, NovaColors.Violet20])
    var gradientWidgetSurface = Gradient(colors: [NovaColors.Gray0, NovaColors.Gray0])
    var gradientWidgetSurfaceStandard = Gradient(colors: [NovaColors.Gray15, NovaColors.Gray10])
    var gradientWidgetSurfacePrivate = Gradient(colors: [NovaColors.VioletDesaturated70, NovaColors.VioletDesaturated60])
    var gradientAIStrongStop1: UIColor = NovaColors.Violet50
    var gradientAIStrongStop2: UIColor = NovaColors.Pink40
    var gradientAIStrongStop3: UIColor = NovaColors.Orange30

    // Default values from LightTheme
    var layerGradient: Gradient { fallbackPalette.layerGradient }
    var layerGradientURL: Gradient { fallbackPalette.layerGradientURL }
    var layerGradientSummary: Gradient { fallbackPalette.layerGradientSummary }
    var layerScrim: UIColor { fallbackPalette.layerScrim }
    var layerCriticalSubdued: UIColor { fallbackPalette.layerCriticalSubdued }
    var layerEmphasis: UIColor { fallbackPalette.layerEmphasis }
    var layer5Hover: UIColor { fallbackPalette.layer5Hover }
    var indicatorActive: UIColor { fallbackPalette.indicatorActive }
    var indicatorInactive: UIColor { fallbackPalette.indicatorInactive }
    var iconAccentViolet: UIColor { fallbackPalette.iconAccentViolet }
    var iconAccentBlue: UIColor { fallbackPalette.iconAccentBlue }
    var iconAccentPink: UIColor { fallbackPalette.iconAccentPink }
    var iconAccentGreen: UIColor { fallbackPalette.iconAccentGreen }
    var iconAccentYellow: UIColor { fallbackPalette.iconAccentYellow }

    // MARK: - Deprecated
    var layer5: UIColor { layerSurfaceMedium }
    var layerGradientOverlay: Gradient { fallbackPalette.layerGradientOverlay }
    var layerHomepage: Gradient { fallbackPalette.layerHomepage }
    var layerAccentNonOpaque: UIColor { fallbackPalette.layerAccentNonOpaque }
    var layerAccentPrivate: UIColor { fallbackPalette.layerAccentPrivate }
    var gradientOnboardingStop1: UIColor { fallbackPalette.gradientOnboardingStop1 }
    var gradientOnboardingStop2: UIColor { fallbackPalette.gradientOnboardingStop2 }
    var gradientOnboardingStop3: UIColor { fallbackPalette.gradientOnboardingStop3 }
    var gradientOnboardingStop4: UIColor { fallbackPalette.gradientOnboardingStop4 }
    var iconRatingNeutral: UIColor { fallbackPalette.iconRatingNeutral }
    var borderSecondary: UIColor { fallbackPalette.borderSecondary }
    var borderAccent: UIColor { fallbackPalette.borderAccent }
    var borderAccentNonOpaque: UIColor { fallbackPalette.borderAccentNonOpaque }
    var borderAccentPrivate: UIColor { fallbackPalette.borderAccentPrivate }
    var borderToolbarDivider: UIColor { fallbackPalette.borderToolbarDivider }

    var faviconLetterColorSet: FaviconLetterColorSet = NovaFaviconColorSet()
}
