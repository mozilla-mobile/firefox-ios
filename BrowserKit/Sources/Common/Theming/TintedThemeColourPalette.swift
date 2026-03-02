// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A colour palette that wraps a base `ThemeColourPalette` and overrides
/// accent-related properties with the user's chosen accent colour.
/// All non-accent properties delegate directly to the underlying base palette.
public struct TintedThemeColourPalette: ThemeColourPalette {
    private let base: ThemeColourPalette
    private let accent: UIColor
    private let backgroundTint: UIColor?
    private let isLight: Bool

    /// - Parameters:
    ///   - base: The underlying palette (e.g. LightTheme or DarkTheme colours).
    ///   - accent: The resolved accent UIColor for the current theme type.
    ///   - themeType: The base theme type, used for light/dark branching.
    ///   - backgroundTint: Optional tint for background layers (layer1, layer3, layerHomepage).
    public init(
        base: ThemeColourPalette,
        accent: UIColor,
        themeType: ThemeType,
        backgroundTint: UIColor? = nil
    ) {
        self.base = base
        self.accent = accent
        self.backgroundTint = backgroundTint
        self.isLight = (themeType == .light)
    }

    // MARK: - Overridden Accent Properties

    // Actions
    public var actionPrimary: UIColor { accent }
    public var actionPrimaryHover: UIColor { accent.accentDarker(by: 0.1) }
    public var actionPrimaryDisabled: UIColor { accent.withAlphaComponent(0.5) }
    public var indicatorActive: UIColor { accent }
    public var actionInformation: UIColor { accent }

    // Text
    public var textAccent: UIColor { accent }

    // Icons
    public var iconAccent: UIColor { accent }

    // Border
    public var borderAccent: UIColor { accent }
    public var borderAccentNonOpaque: UIColor { accent.withAlphaComponent(0.1) }

    // Layers
    public var layerAccentNonOpaque: UIColor {
        accent.withAlphaComponent(isLight ? 0.3 : 0.2)
    }
    public var layerSelectedText: UIColor { accent }
    public var layerInformation: UIColor { accent.withAlphaComponent(0.44) }
    public var layerGradient: Gradient {
        Gradient(colors: [accent.accentLighter(by: 0.15), accent])
    }

    // MARK: - Background Tint Layer Overrides

    public var layer1: UIColor { backgroundTint ?? base.layer1 }
    public var layer2: UIColor { base.layer2 }
    public var layer3: UIColor { backgroundTint ?? base.layer3 }
    public var layer4: UIColor { base.layer4 }
    public var layer5: UIColor { base.layer5 }
    public var layer5Hover: UIColor { base.layer5Hover }
    public var layerScrim: UIColor { base.layerScrim }
    public var layerGradientOverlay: Gradient { base.layerGradientOverlay }
    public var layerAccentPrivate: UIColor { base.layerAccentPrivate }
    public var layerAccentPrivateNonOpaque: UIColor { base.layerAccentPrivateNonOpaque }
    public var layerSepia: UIColor { base.layerSepia }
    public var layerHomepage: Gradient {
        if let bg = backgroundTint {
            let lighter = bg.accentLighter(by: 0.1)
            return Gradient(colors: [lighter, bg])
        }
        return base.layerHomepage
    }
    public var layerSuccess: UIColor { base.layerSuccess }
    public var layerWarning: UIColor { base.layerWarning }
    public var layerCritical: UIColor { base.layerCritical }
    public var layerCriticalSubdued: UIColor { base.layerCriticalSubdued }
    public var layerAutofillText: UIColor { base.layerAutofillText }
    public var layerEmphasis: UIColor { base.layerEmphasis }
    public var layerGradientURL: Gradient { base.layerGradientURL }
    public var layerSurfaceLow: UIColor { base.layerSurfaceLow }
    public var layerSurfaceMedium: UIColor { base.layerSurfaceMedium }
    public var layerSurfaceMediumAlt: UIColor { base.layerSurfaceMediumAlt }
    public var layerGradientSummary: Gradient { base.layerGradientSummary }

    // MARK: - Delegated Action Properties

    public var actionSecondary: UIColor { base.actionSecondary }
    public var actionSecondaryDisabled: UIColor { base.actionSecondaryDisabled }
    public var actionSecondaryHover: UIColor { base.actionSecondaryHover }
    public var formSurfaceOff: UIColor { base.formSurfaceOff }
    public var formKnob: UIColor { base.formKnob }
    public var indicatorInactive: UIColor { base.indicatorInactive }
    public var actionSuccess: UIColor { base.actionSuccess }
    public var actionWarning: UIColor { base.actionWarning }
    public var actionCritical: UIColor { base.actionCritical }
    public var actionTabActive: UIColor { base.actionTabActive }
    public var actionTabInactive: UIColor { base.actionTabInactive }
    public var actionCloseButton: UIColor { base.actionCloseButton }

    // MARK: - Delegated Text Properties

    public var textPrimary: UIColor { base.textPrimary }
    public var textSecondary: UIColor { base.textSecondary }
    public var textDisabled: UIColor { base.textDisabled }
    public var textCritical: UIColor { base.textCritical }
    public var textOnDark: UIColor { base.textOnDark }
    public var textOnLight: UIColor { base.textOnLight }
    public var textInverted: UIColor { base.textInverted }
    public var textInvertedDisabled: UIColor { base.textInvertedDisabled }

    // MARK: - Delegated Icon Properties

    public var iconPrimary: UIColor { base.iconPrimary }
    public var iconSecondary: UIColor { base.iconSecondary }
    public var iconDisabled: UIColor { base.iconDisabled }
    public var iconOnColor: UIColor { base.iconOnColor }
    public var iconCritical: UIColor { base.iconCritical }
    public var iconSpinner: UIColor { base.iconSpinner }
    public var iconAccentViolet: UIColor { base.iconAccentViolet }
    public var iconAccentBlue: UIColor { base.iconAccentBlue }
    public var iconAccentPink: UIColor { base.iconAccentPink }
    public var iconAccentGreen: UIColor { base.iconAccentGreen }
    public var iconAccentYellow: UIColor { base.iconAccentYellow }
    public var iconRatingNeutral: UIColor { base.iconRatingNeutral }

    // MARK: - Delegated Border Properties

    public var borderPrimary: UIColor { base.borderPrimary }
    public var borderAccentPrivate: UIColor { base.borderAccentPrivate }
    public var borderInverted: UIColor { base.borderInverted }
    public var borderToolbarDivider: UIColor { base.borderToolbarDivider }

    // MARK: - Delegated Shadow Properties

    public var shadowSubtle: UIColor { base.shadowSubtle }
    public var shadowDefault: UIColor { base.shadowDefault }
    public var shadowStrong: UIColor { base.shadowStrong }
    public var shadowBorder: UIColor { base.shadowBorder }

    // MARK: - Delegated Gradient Properties

    public var gradientOnboardingStop1: UIColor { base.gradientOnboardingStop1 }
    public var gradientOnboardingStop2: UIColor { base.gradientOnboardingStop2 }
    public var gradientOnboardingStop3: UIColor { base.gradientOnboardingStop3 }
    public var gradientOnboardingStop4: UIColor { base.gradientOnboardingStop4 }
}
