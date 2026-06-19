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
    
    // MARK: - Layers
    var layer1: UIColor = NovaColors.Gray5
    var layer2: UIColor = NovaColors.White
    var layer3: UIColor = NovaColors.Gray10
    var layer4: UIColor = NovaColors.Gray15
    var layer5: UIColor = NovaColors.White
    var layer5Hover: UIColor = NovaColors.Gray10
    var layerScrim: UIColor = NovaColors.Gray80.withAlphaComponent(0.95)
    var layerGradient: Gradient { gradient }
    var layerGradientOverlay: Gradient { gradientAccentSubtle }
    var layerAccentNonOpaque: UIColor = NovaColors.VioletDesaturated10
    var layerAccentPrivate: UIColor = NovaColors.Violet70
    var layerAccentPrivateNonOpaque: UIColor { layerAccentSubtle }
    var layerSepia: UIColor = NovaColors.Yellow0
    var layerHomepage: Gradient { gradientPrivacy }
    var layerInformation: UIColor = NovaColors.Blue10
    var layerSuccess: UIColor = NovaColors.Green10
    var layerWarning: UIColor = NovaColors.Yellow10
    var layerCritical: UIColor = NovaColors.Red10
    var layerCriticalSubdued: UIColor = NovaColors.Red10.withAlphaComponent(0.7)
    var layerSelectedText: UIColor = NovaColors.Gray15
    var layerAutofillText: UIColor = NovaColors.VioletDesaturated10
    var layerEmphasis: UIColor = NovaColors.Gray15
    var layerGradientURL: Gradient { gradientTabBorder }
    var layerSurfaceLow = NovaColors.Gray10
    var layerSurfaceMedium = NovaColors.White
    var layerSurfaceMediumAlpha = NovaColors.White.withAlphaComponent(0.4)
    var layerSurfaceMediumAlt = NovaColors.Gray15
    var layerGradientSummary: Gradient { gradientAIStrong }

    // MARK: - Actions
    var actionPrimary: UIColor = NovaColors.Violet50
    var actionPrimaryHover: UIColor = NovaColors.Violet60
    var actionPrimaryDisabled: UIColor = NovaColors.Violet50.withAlphaComponent(0.4)
    var actionSecondary: UIColor = NovaColors.Gray15
    var actionSecondaryDisabled: UIColor = NovaColors.Gray15.withAlphaComponent(0.4)
    var actionSecondaryHover: UIColor = NovaColors.Gray20
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

    // MARK: - Text
    var textPrimary: UIColor = NovaColors.VioletDesaturated90
    var textSecondary: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.7)
    var textDisabled: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.4)
    var textCritical: UIColor = NovaColors.Red50
    var textAccent: UIColor = NovaColors.Violet50
    var textOnDark: UIColor = NovaColors.VioletDesaturated0
    var textOnLight: UIColor = NovaColors.VioletDesaturated90
    var textInverted: UIColor = NovaColors.VioletDesaturated0
    var textInvertedDisabled: UIColor = NovaColors.VioletDesaturated0.withAlphaComponent(0.4)

    // MARK: - Icons
    var iconPrimary: UIColor = NovaColors.VioletDesaturated90
    var iconSecondary: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.7)
    var iconDisabled: UIColor = NovaColors.VioletDesaturated90.withAlphaComponent(0.4)
    var iconAccent: UIColor = NovaColors.Violet50
    var iconOnColor: UIColor = NovaColors.VioletDesaturated0
    var iconCritical: UIColor = NovaColors.Red50
    var iconSpinner: UIColor = NovaColors.VioletDesaturated90
    var iconAccentViolet: UIColor = NovaColors.Violet50
    var iconAccentBlue: UIColor = NovaColors.Blue50
    var iconAccentPink: UIColor = NovaColors.Pink40
    var iconAccentGreen: UIColor = NovaColors.Green50
    var iconAccentYellow: UIColor = NovaColors.Yellow50
    var iconRatingNeutral: UIColor = NovaColors.Gray30

    // MARK: - Border
    var borderPrimary: UIColor = NovaColors.Gray15
    var borderSecondary: UIColor = NovaColors.Gray20
    var borderAccent: UIColor = NovaColors.Violet50
    var borderAccentNonOpaque: UIColor = NovaColors.Violet30.withAlphaComponent(0.4)
    var borderAccentPrivate: UIColor = NovaColors.Violet70
    var borderInverted: UIColor = NovaColors.Gray60
    var borderToolbarDivider: UIColor = NovaColors.Gray10

    // MARK: - Shadow
    var shadowSubtle: UIColor = NovaColors.Gray60.withAlphaComponent(0.10)
    var shadowDefault: UIColor = NovaColors.Gray60.withAlphaComponent(0.12)
    var shadowStrong: UIColor = NovaColors.Gray60.withAlphaComponent(0.15)
    var shadowBorder: UIColor = NovaColors.VioletDesaturated90

    // MARK: - Nova tokens
    var layerAccentSubtle: UIColor = NovaColors.VioletDesaturated10

    // MARK: - Gradients
    // TODO: Review gradient mapping when updating the UIComponents
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
    var gradientTabBorder = Gradient(colors: [NovaColors.Violet30, NovaColors.Violet50])
    var gradientPrivacy = Gradient(colors: [
        NovaColors.Purple40,
        NovaColors.VioletDesaturated90
    ])
    var gradientPrivacyMask = Gradient(colors: [NovaColors.White, NovaColors.Violet20])

    var gradientAIStrongStop1: UIColor = NovaColors.Violet50
    var gradientAIStrongStop2: UIColor = NovaColors.Pink40
    var gradientAIStrongStop3: UIColor = NovaColors.Orange30

    var gradientOnboardingStop1: UIColor = LightTheme().colors.gradientOnboardingStop1
    var gradientOnboardingStop2: UIColor = LightTheme().colors.gradientOnboardingStop2
    var gradientOnboardingStop3: UIColor = LightTheme().colors.gradientOnboardingStop3
    var gradientOnboardingStop4: UIColor = LightTheme().colors.gradientOnboardingStop4
}
