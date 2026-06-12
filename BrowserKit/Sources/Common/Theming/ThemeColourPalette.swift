// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The colour palette for a theme.
/// Based on the official themes in https://www.figma.com/file/pEyGeE4KV5ytYHeXMfLcEr/Mobile-Styles?node-id=889%3A46413
/// Do not add any named colours in here unless it's part of the official theme
public protocol ThemeColourPalette {
    // MARK: - Layers
    var layer1: UIColor { get }
    var layer2: UIColor { get }
    var layer3: UIColor { get }
    var layer4: UIColor { get }
    var layer5: UIColor { get }
    var layer5Hover: UIColor { get }
    var layerScrim: UIColor { get }
    var layerGradient: Gradient { get }
    var layerGradientOverlay: Gradient { get }
    var layerAccentNonOpaque: UIColor { get }
    var layerAccentPrivate: UIColor { get }
    var layerAccentPrivateNonOpaque: UIColor { get }
    var layerSepia: UIColor { get }
    var layerHomepage: Gradient { get }
    var layerInformation: UIColor { get }
    var layerSuccess: UIColor { get }
    var layerWarning: UIColor { get }
    var layerCritical: UIColor { get }
    var layerCriticalSubdued: UIColor { get }
    var layerSelectedText: UIColor { get }
    var layerAutofillText: UIColor { get }
    var layerEmphasis: UIColor { get }
    var layerGradientURL: Gradient { get }
    var layerSurfaceLow: UIColor { get }
    var layerSurfaceMedium: UIColor { get }
    var layerSurfaceMediumAlpha: UIColor { get }
    var layerSurfaceMediumAlt: UIColor { get }
    var layerGradientSummary: Gradient { get }

    // MARK: - Actions
    var actionPrimary: UIColor { get }
    var actionPrimaryHover: UIColor { get }
    var actionPrimaryDisabled: UIColor { get }
    var actionSecondary: UIColor { get }
    var actionSecondaryDisabled: UIColor { get }
    var actionSecondaryHover: UIColor { get }
    var formSurfaceOff: UIColor { get }
    var formKnob: UIColor { get }
    var indicatorActive: UIColor { get }
    var indicatorInactive: UIColor { get }
    var actionSuccess: UIColor { get }
    var actionWarning: UIColor { get }
    var actionCritical: UIColor { get }
    var actionInformation: UIColor { get }
    var actionTabActive: UIColor { get }
    var actionTabInactive: UIColor { get }
    var actionCloseButton: UIColor { get }

    // MARK: - Text
    var textPrimary: UIColor { get }
    var textSecondary: UIColor { get }
    var textDisabled: UIColor { get }
    var textCritical: UIColor { get }
    var textAccent: UIColor { get }
    var textOnDark: UIColor { get }
    var textOnLight: UIColor { get }
    var textInverted: UIColor { get }
    var textInvertedDisabled: UIColor { get }

    // MARK: - Icons
    var iconPrimary: UIColor { get }
    var iconSecondary: UIColor { get }
    var iconDisabled: UIColor { get }
    var iconAccent: UIColor { get }
    var iconOnColor: UIColor { get }
    var iconCritical: UIColor { get }
    var iconSpinner: UIColor { get }
    var iconAccentViolet: UIColor { get }
    var iconAccentBlue: UIColor { get }
    var iconAccentPink: UIColor { get }
    var iconAccentGreen: UIColor { get }
    var iconAccentYellow: UIColor { get }
    var iconRatingNeutral: UIColor { get }
    var iconAccentGreen1: UIColor { get }
    var iconAccentGreen2: UIColor { get }
    var iconAccentGreen3: UIColor { get }
    var iconAccentGreen4: UIColor { get }
    var iconAccentGreen5: UIColor { get }
    var iconAccentGreen6: UIColor { get }
    var iconAccentGreen7: UIColor { get }
    var iconAccentCyan1: UIColor { get }
    var iconAccentCyan2: UIColor { get }
    var iconAccentCyan3: UIColor { get }
    var iconAccentCyan4: UIColor { get }
    var iconAccentCyan5: UIColor { get }
    var iconAccentCyan6: UIColor { get }
    var iconAccentCyan7: UIColor { get }
    var iconAccentBlue1: UIColor { get }
    var iconAccentBlue2: UIColor { get }
    var iconAccentBlue3: UIColor { get }
    var iconAccentBlue4: UIColor { get }
    var iconAccentBlue5: UIColor { get }
    var iconAccentBlue6: UIColor { get }
    var iconAccentBlue7: UIColor { get }
    var iconAccentYellow1: UIColor { get }
    var iconAccentYellow2: UIColor { get }
    var iconAccentYellow3: UIColor { get }
    var iconAccentYellow4: UIColor { get }
    var iconAccentYellow5: UIColor { get }
    var iconAccentYellow6: UIColor { get }
    var iconAccentYellow7: UIColor { get }
    var iconAccentOrange1: UIColor { get }
    var iconAccentOrange2: UIColor { get }
    var iconAccentOrange3: UIColor { get }
    var iconAccentOrange4: UIColor { get }
    var iconAccentOrange5: UIColor { get }
    var iconAccentOrange6: UIColor { get }
    var iconAccentOrange7: UIColor { get }
    var iconAccentRed1: UIColor { get }
    var iconAccentRed2: UIColor { get }
    var iconAccentRed3: UIColor { get }
    var iconAccentRed4: UIColor { get }
    var iconAccentRed5: UIColor { get }
    var iconAccentRed6: UIColor { get }
    var iconAccentRed7: UIColor { get }

    // MARK: - Border
    var borderPrimary: UIColor { get }
    var borderSecondary: UIColor { get }
    var borderAccent: UIColor { get }
    var borderAccentNonOpaque: UIColor { get }
    var borderAccentPrivate: UIColor { get }
    var borderInverted: UIColor { get }
    var borderToolbarDivider: UIColor { get }

    // MARK: - Shadow
    var shadowSubtle: UIColor { get }
    var shadowDefault: UIColor { get }
    var shadowStrong: UIColor { get }
    var shadowBorder: UIColor { get }

    // MARK: - Gradient
    var gradientOnboardingStop1: UIColor { get }
    var gradientOnboardingStop2: UIColor { get }
    var gradientOnboardingStop3: UIColor { get }
    var gradientOnboardingStop4: UIColor { get }
    var gradientAIStrongStop1: UIColor { get }
    var gradientAIStrongStop2: UIColor { get }
    var gradientAIStrongStop3: UIColor { get }
}

public extension ThemeColourPalette {
    var iconAccentGreen1: UIColor { iconAccentGreen }
    var iconAccentGreen2: UIColor { iconAccentGreen }
    var iconAccentGreen3: UIColor { iconAccentGreen }
    var iconAccentGreen4: UIColor { iconAccentGreen }
    var iconAccentGreen5: UIColor { iconAccentGreen }
    var iconAccentGreen6: UIColor { iconAccentGreen }
    var iconAccentGreen7: UIColor { iconAccentGreen }
    var iconAccentCyan1: UIColor { iconAccentBlue }
    var iconAccentCyan2: UIColor { iconAccentBlue }
    var iconAccentCyan3: UIColor { iconAccentBlue }
    var iconAccentCyan4: UIColor { iconAccentBlue }
    var iconAccentCyan5: UIColor { iconAccentBlue }
    var iconAccentCyan6: UIColor { iconAccentBlue }
    var iconAccentCyan7: UIColor { iconAccentBlue }
    var iconAccentBlue1: UIColor { iconAccentBlue }
    var iconAccentBlue2: UIColor { iconAccentBlue }
    var iconAccentBlue3: UIColor { iconAccentBlue }
    var iconAccentBlue4: UIColor { iconAccentBlue }
    var iconAccentBlue5: UIColor { iconAccentBlue }
    var iconAccentBlue6: UIColor { iconAccentBlue }
    var iconAccentBlue7: UIColor { iconAccentBlue }
    var iconAccentYellow1: UIColor { iconAccentYellow }
    var iconAccentYellow2: UIColor { iconAccentYellow }
    var iconAccentYellow3: UIColor { iconAccentYellow }
    var iconAccentYellow4: UIColor { iconAccentYellow }
    var iconAccentYellow5: UIColor { iconAccentYellow }
    var iconAccentYellow6: UIColor { iconAccentYellow }
    var iconAccentYellow7: UIColor { iconAccentYellow }
    var iconAccentOrange1: UIColor { actionWarning }
    var iconAccentOrange2: UIColor { actionWarning }
    var iconAccentOrange3: UIColor { actionWarning }
    var iconAccentOrange4: UIColor { actionWarning }
    var iconAccentOrange5: UIColor { actionWarning }
    var iconAccentOrange6: UIColor { actionWarning }
    var iconAccentOrange7: UIColor { actionWarning }
    var iconAccentRed1: UIColor { iconCritical }
    var iconAccentRed2: UIColor { iconCritical }
    var iconAccentRed3: UIColor { iconCritical }
    var iconAccentRed4: UIColor { iconCritical }
    var iconAccentRed5: UIColor { iconCritical }
    var iconAccentRed6: UIColor { iconCritical }
    var iconAccentRed7: UIColor { iconCritical }
}
