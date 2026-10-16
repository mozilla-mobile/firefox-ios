// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct NovaDarkTheme: Theme {
    public var type: ThemeType = .dark
    private let palette = NovaDarkColourPalette()
    public var colors: ThemeColourPalette { palette }
    public var isNova = true

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
    public var isNova = true

    public init() {}
}

private struct NovaDarkColourPalette: ThemeColourPalette {
    private let fallbackPalette: ThemeColourPalette = DarkTheme().colors

    // MARK: - Layer

    var layer1: UIColor = NovaColors.Gray75
    var layer2: UIColor = NovaColors.Gray55
    var layer3: UIColor = NovaColors.Gray55
    var layer4: UIColor = NovaColors.Gray65
    var layerSurfaceLow = NovaColors.Gray75
    var layerSurfaceMedium = NovaColors.Gray65
    var layerSurfaceMediumAlt: UIColor = NovaColors.Gray60
    var layerSurfaceMediumAltGlass = NovaColors.Gray85
    var layerSurfaceMediumAlpha = NovaColors.Gray65.withAlphaComponent(0.4)
    var layerAccentSubtle: UIColor = NovaColors.VioletDesaturated70
    var layerInverse: UIColor = NovaColors.Gray30
    var layerWarning: UIColor = NovaColors.Yellow70
    var layerSuccess: UIColor = NovaColors.Green70
    var layerCritical: UIColor = NovaColors.Red70
    var layerInformation: UIColor = NovaColors.Blue70
    var layerSepia: UIColor = NovaColors.Yellow0
    var layerAutofillText: UIColor = NovaColors.VioletDesaturated30.withAlphaComponent(0.55)
    var layerSelectedText: UIColor = NovaColors.VioletDesaturated30.withAlphaComponent(0.55)
    var layerGlassTintNova: UIColor = NovaColors.Violet90.withAlphaComponent(0.58)
    var layerGlassSelectedFill: UIColor = NovaColors.Gray90
    var layerAccentPrivateNonOpaque: UIColor { layerAccentSubtle }
    var layerToolbarGlass: UIColor = NovaColors.Gray75

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

    // MARK: - Border

    var borderPrimary: UIColor = NovaColors.Gray60
    var borderStrong: UIColor = NovaColors.Gray55
    var borderInverted: UIColor = NovaColors.Gray15
    var borderAccentToast: UIColor = NovaColors.Violet70
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
    var gradientWidgetSurface = Gradient(colors: [NovaColors.Gray70, NovaColors.Gray90])
    var gradientWidgetSurfaceStandard = Gradient(colors: [NovaColors.Gray60, NovaColors.Gray65])
    var gradientWidgetSurfacePrivate = Gradient(colors: [NovaColors.VioletDesaturated70, NovaColors.VioletDesaturated60])
    var gradientAIStrongStop1: UIColor = NovaColors.Violet50
    var gradientAIStrongStop2: UIColor = NovaColors.Pink40
    var gradientAIStrongStop3: UIColor = NovaColors.Orange30

    // Default values from DarkTheme
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
