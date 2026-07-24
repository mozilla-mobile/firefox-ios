// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct NovaPrivateTheme: Theme {
    public var type: ThemeType = .privateMode
    private let palette = NovaPrivateColourPalette()
    public var colors: ThemeColourPalette { palette }
    public var isNova = true

    public init() {}
}

private struct NovaPrivateColourPalette: ThemeColourPalette {
    // MARK: - Layer

    var layer1: UIColor = NovaColors.VioletDesaturated90
    var layer2: UIColor = NovaColors.VioletDesaturated70
    var layer3: UIColor = NovaColors.VioletDesaturated70
    var layer4: UIColor = NovaColors.VioletDesaturated80
    var layerSurfaceLow = NovaColors.VioletDesaturated90
    var layerSurfaceMedium = NovaColors.VioletDesaturated80
    var layerSurfaceMediumAlpha = NovaColors.VioletDesaturated80.withAlphaComponent(0.4)
    var layerAccentSubtle: UIColor = NovaColors.Violet70
    var layerInverse: UIColor = NovaColors.Gray30.withAlphaComponent(0.9)
    var layerWarning: UIColor = NovaColors.Yellow70
    var layerSuccess: UIColor = NovaColors.Green70
    var layerCritical: UIColor = NovaColors.Red70
    var layerInformation: UIColor = NovaColors.Blue70
    var layerSepia: UIColor = NovaColors.Yellow0
    var layerAutofillText: UIColor = NovaColors.VioletDesaturated30.withAlphaComponent(0.55)
    var layerSelectedText: UIColor = NovaColors.Gray45.withAlphaComponent(0.81)
    var layerGlassTintNova: UIColor = .clear
    var layerAccentPrivateNonOpaque: UIColor { layerAccentSubtle }

    // MARK: - Action

    var actionPrimary: UIColor = NovaColors.Violet30
    var actionPrimaryHover: UIColor = NovaColors.Violet40
    var actionPrimaryDisabled: UIColor = NovaColors.Violet30.withAlphaComponent(0.4)
    var actionSecondary: UIColor = NovaColors.Gray55
    var actionSecondaryHover: UIColor = NovaColors.Gray60
    var actionSecondaryDisabled: UIColor = NovaColors.Gray55.withAlphaComponent(0.5)
    var actionWarning: UIColor = NovaColors.Yellow30
    var actionSuccess: UIColor = NovaColors.Green30
    var actionCritical: UIColor = NovaColors.Red30
    var actionInformation: UIColor = NovaColors.Blue30
    var formKnob: UIColor = NovaColors.White
    var formSurfaceOff: UIColor = NovaColors.Gray55
    var actionTabActive: UIColor = NovaColors.VioletDesaturated80
    var actionTabInactive: UIColor = NovaColors.VioletDesaturated90
    var actionCloseButton: UIColor = NovaColors.VioletDesaturated80

    // MARK: - Text

    var textPrimary: UIColor = NovaColors.VioletDesaturated0
    var textSecondary: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.7)
    var textDisabled: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.4)
    var textAccent: UIColor = NovaColors.Violet30
    var textCritical: UIColor = NovaColors.Red30
    var textInverted: UIColor = NovaColors.VioletDesaturated90
    var textInvertedDisabled: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.4)
    var textOnDark: UIColor = NovaColors.VioletDesaturated0
    var textOnLight: UIColor = NovaColors.VioletDesaturated90
    var textColorPrimary: UIColor = NovaColors.VioletDesaturated0
    var textToast: UIColor = NovaColors.Violet70

    // MARK: - Icon

    var iconPrimary: UIColor = NovaColors.VioletDesaturated0
    var iconSecondary: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.7)
    var iconDisabled: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.4)
    var iconAccent: UIColor = NovaColors.Violet30
    var iconCritical: UIColor = NovaColors.Red30
    var iconInverted: UIColor = NovaColors.VioletDesaturated90
    var iconOnColor: UIColor = NovaColors.VioletDesaturated0
    var iconOnColorDisabled: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.4)
    var iconSpinner: UIColor = NovaColors.Gray40
    var iconPrivate: UIColor = NovaColors.Violet50

    // MARK: - Border

    var borderPrimary: UIColor = NovaColors.VioletDesaturated70
    var borderStrong: UIColor = NovaColors.VioletDesaturated60
    var borderInverted: UIColor = NovaColors.Gray15
    var borderRadioButtonDefault: UIColor = NovaColors.Gray45

    // MARK: - Shadow

    var shadowSubtle: UIColor = NovaColors.Gray80.withAlphaComponent(0.10)
    var shadowDefault: UIColor = NovaColors.Gray80.withAlphaComponent(0.12)
    var shadowStrong: UIColor = NovaColors.Gray80.withAlphaComponent(0.16)
    var shadowBorder: UIColor = NovaColors.Gray65.withAlphaComponent(0.50)

    // MARK: - Gradients

    var gradient = Gradient(colors: [NovaColors.Violet60, NovaColors.Violet50])
    var gradientAccent = Gradient(colors: [NovaColors.Violet30, NovaColors.Violet50])
    var gradientAccentSubtle = Gradient(colors: [
        NovaColors.VioletDesaturated90,
        NovaColors.VioletDesaturated90
    ])
    var gradientAIStrong = Gradient(colors: [
        NovaColors.Violet50,
        NovaColors.Pink40,
        NovaColors.Orange30
    ])
    var gradientBorder = Gradient(colors: [NovaColors.Violet30, NovaColors.Violet50])
    var gradientPrivacy = Gradient(colors: [
        NovaColors.Purple40,
        NovaColors.Purple20
    ])
    var gradientPrivacyMask = Gradient(colors: [NovaColors.White, NovaColors.Violet20])
    var gradientAIStrongStop1: UIColor = NovaColors.Violet50
    var gradientAIStrongStop2: UIColor = NovaColors.Pink40
    var gradientAIStrongStop3: UIColor = NovaColors.Orange30

    // Default values from PrivateModeTheme
    var layerGradient: Gradient = PrivateModeTheme().colors.layerGradient
    var layerGradientURL: Gradient = PrivateModeTheme().colors.layerGradientURL
    var layerGradientSummary: Gradient = PrivateModeTheme().colors.layerGradientSummary
    var layerScrim: UIColor = PrivateModeTheme().colors.layerScrim
    var layerCriticalSubdued: UIColor = PrivateModeTheme().colors.layerCriticalSubdued
    var layerEmphasis: UIColor = PrivateModeTheme().colors.layerEmphasis
    var layer5Hover: UIColor = PrivateModeTheme().colors.layer5Hover
    var layerSurfaceMediumAlt: UIColor = PrivateModeTheme().colors.layerSurfaceMediumAlt
    var indicatorActive: UIColor = PrivateModeTheme().colors.indicatorActive
    var indicatorInactive: UIColor = PrivateModeTheme().colors.indicatorInactive
    var iconAccentViolet: UIColor = PrivateModeTheme().colors.iconAccentViolet
    var iconAccentBlue: UIColor = PrivateModeTheme().colors.iconAccentBlue
    var iconAccentPink: UIColor = PrivateModeTheme().colors.iconAccentPink
    var iconAccentGreen: UIColor = PrivateModeTheme().colors.iconAccentGreen
    var iconAccentYellow: UIColor = PrivateModeTheme().colors.iconAccentYellow

    // MARK: - Deprecated
    var layer5: UIColor = PrivateModeTheme().colors.layer5
    var layerGradientOverlay: Gradient = PrivateModeTheme().colors.layerGradientOverlay
    var layerHomepage: Gradient = PrivateModeTheme().colors.layerHomepage
    var layerAccentNonOpaque: UIColor = PrivateModeTheme().colors.layerAccentNonOpaque
    var layerAccentPrivate: UIColor = PrivateModeTheme().colors.layerAccentPrivate
    var gradientOnboardingStop1: UIColor = PrivateModeTheme().colors.gradientOnboardingStop1
    var gradientOnboardingStop2: UIColor = PrivateModeTheme().colors.gradientOnboardingStop2
    var gradientOnboardingStop3: UIColor = PrivateModeTheme().colors.gradientOnboardingStop3
    var gradientOnboardingStop4: UIColor = PrivateModeTheme().colors.gradientOnboardingStop4
    var iconRatingNeutral: UIColor = PrivateModeTheme().colors.iconRatingNeutral
    var borderSecondary: UIColor = PrivateModeTheme().colors.borderSecondary
    var borderAccent: UIColor = PrivateModeTheme().colors.borderAccent
    var borderAccentNonOpaque: UIColor = PrivateModeTheme().colors.borderAccentNonOpaque
    var borderAccentPrivate: UIColor = PrivateModeTheme().colors.borderAccentPrivate
    var borderToolbarDivider: UIColor = PrivateModeTheme().colors.borderToolbarDivider

    var faviconLetterColorSet: FaviconLetterColorSet = NovaFaviconColorSet()
}
