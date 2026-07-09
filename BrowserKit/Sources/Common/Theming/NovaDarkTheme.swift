// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct NovaDarkTheme: Theme {
    public var type: ThemeType = .dark
    private let palette = NovaDarkColourPalette()
    public var colors: ThemeColourPalette { palette }
    public var novaColors: NovaThemeColourPalette { palette }

    public init() {}
}

/// `NovaNightModeTheme` is the same as `NovaDarkTheme` but with a different `type`. This
/// is because we want to be able to change theme types even when night mode
/// is on, so, we have to differentiate between night mode's dark theme
/// and a regular dark theme.
public struct NovaNightModeTheme: Theme {
    public var type: ThemeType = .nightMode
    private let palette = NovaDarkColourPalette()
    public var colors: ThemeColourPalette { palette }
    public var novaColors: NovaThemeColourPalette { palette }

    public init() {}
}

private struct NovaDarkColourPalette: NovaThemeColourPalette {
    // MARK: - Layer

    var layer1: UIColor = NovaColors.Gray75
    var layer2: UIColor = NovaColors.Gray60
    var layer3: UIColor = NovaColors.Gray55
    var layer4: UIColor = NovaColors.Gray65
    var layerSurfaceLow = NovaColors.Gray75
    var layerSurfaceMedium = NovaColors.Gray65
    var layerSurfaceMediumAlpha = NovaColors.Gray65.withAlphaComponent(0.4)
    var layerAccentSubtle: UIColor = NovaColors.VioletDesaturated70
    var layerInverse: UIColor = NovaColors.Gray30.withAlphaComponent(0.9)
    var layerWarning: UIColor = NovaColors.Yellow70
    var layerSuccess: UIColor = NovaColors.Green70
    var layerCritical: UIColor = NovaColors.Red70
    var layerInformation: UIColor = NovaColors.Blue70
    var layerSepia: UIColor = NovaColors.Yellow0
    var layerAutofillText: UIColor = NovaColors.VioletDesaturated30.withAlphaComponent(0.55)
    var layerSelectedText: UIColor = NovaColors.Gray45.withAlphaComponent(0.8)
    var layerGlassTintNova: UIColor = NovaColors.Violet90.withAlphaComponent(0.58)

    // TODO: Check if layerAccentPrivateNonOpaque should be renamed
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
    var actionTabActive: UIColor = NovaColors.Gray65
    var actionTabInactive: UIColor = NovaColors.Gray75
    var actionCloseButton: UIColor = NovaColors.Gray65

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
    var iconPrivateOutline: UIColor = NovaColors.VioletDesaturated80

    // MARK: - Border

    var borderPrimary: UIColor = NovaColors.Gray60
    var borderStrong: UIColor = NovaColors.Gray55
    var borderOnColor: UIColor = NovaColors.Gray15
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
        NovaColors.VioletDesaturated90.withAlphaComponent(0.5),
        NovaColors.Orange70.withAlphaComponent(0.5)
    ])
    var gradientAISubtle = Gradient(colors: [
        NovaColors.Gray45,
        NovaColors.Violet40,
        NovaColors.Orange30
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

    // TODO: FXIOS - 16130 Map gradient properties to Nova gradient tokens.
    var layerGradient: Gradient = DarkTheme().colors.layerGradient
    var layerGradientOverlay: Gradient = DarkTheme().colors.layerGradientOverlay
    var layerGradientURL: Gradient = DarkTheme().colors.layerGradientURL
    var layerGradientSummary: Gradient = DarkTheme().colors.layerGradientSummary
    var layerHomepage: Gradient = DarkTheme().colors.layerHomepage
    var gradientOnboardingStop1: UIColor = DarkTheme().colors.gradientOnboardingStop1
    var gradientOnboardingStop2: UIColor = DarkTheme().colors.gradientOnboardingStop2
    var gradientOnboardingStop3: UIColor = DarkTheme().colors.gradientOnboardingStop3
    var gradientOnboardingStop4: UIColor = DarkTheme().colors.gradientOnboardingStop4

    // MARK: - Dark theme defaults
    // TODO: Check if some tokens should be replaced by Nova tokens or deprecated
    var layerScrim: UIColor = DarkTheme().colors.layerScrim
    var layerAccentNonOpaque: UIColor = DarkTheme().colors.layerAccentNonOpaque
    var layerAccentPrivate: UIColor = DarkTheme().colors.layerAccentPrivate
    var layerCriticalSubdued: UIColor = DarkTheme().colors.layerCriticalSubdued
    var layerEmphasis: UIColor = DarkTheme().colors.layerEmphasis
    var layer5: UIColor = DarkTheme().colors.layer5
    var layer5Hover: UIColor = DarkTheme().colors.layer5Hover
    var layerSurfaceMediumAlt: UIColor = DarkTheme().colors.layerSurfaceMediumAlt

    var indicatorActive: UIColor = DarkTheme().colors.indicatorActive
    var indicatorInactive: UIColor = DarkTheme().colors.indicatorInactive
    var iconRatingNeutral: UIColor = DarkTheme().colors.iconRatingNeutral
    var iconAccentViolet: UIColor = DarkTheme().colors.iconAccentViolet
    var iconAccentBlue: UIColor = DarkTheme().colors.iconAccentBlue
    var iconAccentPink: UIColor = DarkTheme().colors.iconAccentPink
    var iconAccentGreen: UIColor = DarkTheme().colors.iconAccentGreen
    var iconAccentYellow: UIColor = DarkTheme().colors.iconAccentYellow

    var borderSecondary: UIColor = DarkTheme().colors.borderSecondary
    var borderAccent: UIColor = DarkTheme().colors.borderAccent
    var borderAccentNonOpaque: UIColor = DarkTheme().colors.borderAccentNonOpaque
    var borderAccentPrivate: UIColor = DarkTheme().colors.borderAccentPrivate
    var borderToolbarDivider: UIColor = DarkTheme().colors.borderToolbarDivider

    var faviconLetterColorSet: FaviconLetterColorSet = NovaFaviconColorSet()
}
