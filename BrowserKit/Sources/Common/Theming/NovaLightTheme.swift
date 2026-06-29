// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct NovaLightTheme: Theme {
    public var type: ThemeType = .light
    private let palette = NovaLightColourPalette()
    public var colors: ThemeColourPalette { palette }
    public var novaColors: NovaThemeColourPalette { palette }

    public init() {}
}

private struct NovaLightColourPalette: NovaThemeColourPalette {
    // MARK: - Layer

    var layer1: UIColor = NovaColors.Gray5
    var layer2: UIColor = NovaColors.White
    var layer3: UIColor = NovaColors.Gray10
    var layer4: UIColor = NovaColors.Gray15
    var layerSurfaceLow = NovaColors.Gray10
    var layerSurfaceMedium = NovaColors.White
    var layerSurfaceMediumAlpha = NovaColors.White.withAlphaComponent(0.4)
    var layerAccentSubtle: UIColor = NovaColors.VioletDesaturated10
    var layerInverse: UIColor = NovaColors.Gray70.withAlphaComponent(0.8)
    var layerWarning: UIColor = NovaColors.Yellow10
    var layerSuccess: UIColor = NovaColors.Green10
    var layerCritical: UIColor = NovaColors.Red10
    var layerInformation: UIColor = NovaColors.Blue10
    var layerSepia: UIColor = NovaColors.Yellow0
    var layerAutofillText: UIColor = NovaColors.VioletDesaturated30
    var layerSelectedText: UIColor = NovaColors.Gray35
    var layerGlassTintNova: UIColor = NovaColors.VioletDesaturated10.withAlphaComponent(0.45)

    // TODO: Check if layerAccentPrivateNonOpaque should be renamed
    var layerAccentPrivateNonOpaque: UIColor { layerAccentSubtle }

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
    var textToast: UIColor = NovaColors.Violet50

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
    var iconPrivateOutline: UIColor = NovaColors.VioletDesaturated80

    // MARK: - Border

    var borderPrimary: UIColor = NovaColors.Gray15
    var borderStrong: UIColor = NovaColors.Gray20
    var borderOnColor: UIColor = NovaColors.Gray15
    var borderInverted: UIColor = NovaColors.Gray60
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
    var gradientAISubtle = Gradient(colors: [
        NovaColors.Gray5,
        NovaColors.Violet20,
        NovaColors.Orange10
    ])
    var gradientBorder = Gradient(colors: [NovaColors.Violet30, NovaColors.Violet50])
    var gradientPrivacy = Gradient(colors: [
        NovaColors.Purple40,
        NovaColors.VioletDesaturated90
    ])
    var gradientPrivacyMask = Gradient(colors: [NovaColors.White, NovaColors.Violet20])
    var gradientAIStrongStop1: UIColor = NovaColors.Violet50
    var gradientAIStrongStop2: UIColor = NovaColors.Pink40
    var gradientAIStrongStop3: UIColor = NovaColors.Orange30

    // TODO: FXIOS - 16130 Map gradient properties to Nova gradient tokens.
    var layerGradient: Gradient = LightTheme().colors.layerGradient
    var layerGradientOverlay: Gradient = LightTheme().colors.layerGradientOverlay
    var layerGradientURL: Gradient = LightTheme().colors.layerGradientURL
    var layerGradientSummary: Gradient = LightTheme().colors.layerGradientSummary
    var layerHomepage: Gradient = LightTheme().colors.layerHomepage
    var gradientOnboardingStop1: UIColor = LightTheme().colors.gradientOnboardingStop1
    var gradientOnboardingStop2: UIColor = LightTheme().colors.gradientOnboardingStop2
    var gradientOnboardingStop3: UIColor = LightTheme().colors.gradientOnboardingStop3
    var gradientOnboardingStop4: UIColor = LightTheme().colors.gradientOnboardingStop4

    // MARK: - Light theme defaults
    // TODO: Check if some tokens should be replaced by Nova tokens or deprecated
    var layerScrim: UIColor = LightTheme().colors.layerScrim
    var layerAccentNonOpaque: UIColor = LightTheme().colors.layerAccentNonOpaque
    var layerAccentPrivate: UIColor = LightTheme().colors.layerAccentPrivate
    var layerCriticalSubdued: UIColor = LightTheme().colors.layerCriticalSubdued
    var layerEmphasis: UIColor = LightTheme().colors.layerEmphasis
    var layer5: UIColor = LightTheme().colors.layer5
    var layer5Hover: UIColor = LightTheme().colors.layer5Hover
    var layerSurfaceMediumAlt: UIColor = LightTheme().colors.layerSurfaceMediumAlt

    var indicatorActive: UIColor = LightTheme().colors.indicatorActive
    var indicatorInactive: UIColor = LightTheme().colors.indicatorInactive
    var iconRatingNeutral: UIColor = LightTheme().colors.iconRatingNeutral
    var iconAccentViolet: UIColor = LightTheme().colors.iconAccentViolet
    var iconAccentBlue: UIColor = LightTheme().colors.iconAccentBlue
    var iconAccentPink: UIColor = LightTheme().colors.iconAccentPink
    var iconAccentGreen: UIColor = LightTheme().colors.iconAccentGreen
    var iconAccentYellow: UIColor = LightTheme().colors.iconAccentYellow

    var borderSecondary: UIColor = LightTheme().colors.borderSecondary
    var borderAccent: UIColor = LightTheme().colors.borderAccent
    var borderAccentNonOpaque: UIColor = LightTheme().colors.borderAccentNonOpaque
    var borderAccentPrivate: UIColor = LightTheme().colors.borderAccentPrivate
    var borderToolbarDivider: UIColor = LightTheme().colors.borderToolbarDivider
}
