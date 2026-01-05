// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct TabTrayPanelSwipePalette: ThemeColourPalette {
    private let base: ThemeColourPalette
    private let partialOverrides: PartialOverrides

    // MARK: Overridden colors
    var layer1: UIColor {
        return partialOverrides.layer1
    }

    var iconPrimary: UIColor {
        return partialOverrides.iconPrimary
    }

    var textPrimary: UIColor {
        return partialOverrides.textPrimary
    }

    var actionSecondary: UIColor {
        return partialOverrides.actionSecondary
    }

    var layerScrim: UIColor {
        return partialOverrides.layerScrim
    }

    var layer3: UIColor {
        return partialOverrides.layer3
    }

    var layerEmphasis: UIColor {
        return partialOverrides.layerEmphasis
    }

    var textOnDark: UIColor {
        return partialOverrides.textOnDark
    }

    var borderPrimary: UIColor {
        return partialOverrides.borderPrimary
    }

    var borderAccent: UIColor {
        return partialOverrides.borderAccent
    }

    var borderAccentPrivate: UIColor {
        return partialOverrides.borderAccentPrivate
    }

    var shadowDefault: UIColor {
        return partialOverrides.shadowDefault
    }

    var iconDisabled: UIColor {
        return partialOverrides.iconDisabled
    }

    struct PartialOverrides {
        var layer1: UIColor
        var iconPrimary: UIColor
        var textPrimary: UIColor
        var actionSecondary: UIColor
        var layerScrim: UIColor
        var layer3: UIColor
        var layerEmphasis: UIColor
        var textOnDark: UIColor
        var borderPrimary: UIColor
        var borderAccent: UIColor
        var borderAccentPrivate: UIColor
        var shadowDefault: UIColor
        var iconDisabled: UIColor
    }

    var layer2: UIColor { base.layer2 }
    var layer4: UIColor { base.layer4 }
    var layer5: UIColor { base.layer5 }
    var layer5Hover: UIColor { base.layer5Hover }
    var layerGradient: Gradient { base.layerGradient }
    var layerGradientOverlay: Gradient { base.layerGradientOverlay }
    var layerAccentNonOpaque: UIColor { base.layerAccentNonOpaque }
    var layerAccentPrivate: UIColor { base.layerAccentPrivate }
    var layerAccentPrivateNonOpaque: UIColor { base.layerAccentPrivateNonOpaque }
    var layerSepia: UIColor { base.layerSepia }
    var layerHomepage: Gradient { base.layerHomepage }
    var layerInformation: UIColor { base.layerInformation }
    var layerSuccess: UIColor { base.layerSuccess }
    var layerWarning: UIColor { base.layerWarning }
    var layerCritical: UIColor { base.layerCritical }
    var layerCriticalSubdued: UIColor { base.layerCriticalSubdued }
    var layerSelectedText: UIColor { base.layerSelectedText }
    var layerAutofillText: UIColor { base.layerAutofillText }
    var layerGradientURL: Gradient { base.layerGradientURL }
    var layerSurfaceLow: UIColor { base.layerSurfaceLow }
    var layerSurfaceMedium: UIColor { base.layerSurfaceMedium }
    var layerSurfaceMediumAlt: UIColor { base.layerSurfaceMediumAlt }
    var layerGradientSummary: Gradient { base.layerGradientSummary }

    var actionPrimary: UIColor { base.actionPrimary }
    var actionPrimaryHover: UIColor { base.actionPrimaryHover }
    var actionPrimaryDisabled: UIColor { base.actionPrimaryDisabled }
    var actionSecondaryDisabled: UIColor { base.actionSecondaryDisabled }
    var actionSecondaryHover: UIColor { base.actionSecondaryHover }
    var formSurfaceOff: UIColor { base.formSurfaceOff }
    var formKnob: UIColor { base.formKnob }
    var indicatorActive: UIColor { base.indicatorActive }
    var indicatorInactive: UIColor { base.indicatorInactive }
    var actionSuccess: UIColor { base.actionSuccess }
    var actionWarning: UIColor { base.actionWarning }
    var actionCritical: UIColor { base.actionCritical }
    var actionInformation: UIColor { base.actionInformation }
    var actionTabActive: UIColor { base.actionTabActive }
    var actionTabInactive: UIColor { base.actionTabInactive }
    var actionCloseButton: UIColor { base.actionCloseButton }

    var textSecondary: UIColor { base.textSecondary }
    var textDisabled: UIColor { base.textDisabled }
    var textCritical: UIColor { base.textCritical }
    var textAccent: UIColor { base.textAccent }
    var textOnLight: UIColor { base.textOnLight }
    var textInverted: UIColor { base.textInverted }
    var textInvertedDisabled: UIColor { base.textInvertedDisabled }

    var iconSecondary: UIColor { base.iconSecondary }
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

    var borderAccentNonOpaque: UIColor { base.borderAccentNonOpaque }
    var borderInverted: UIColor { base.borderInverted }
    var borderToolbarDivider: UIColor { base.borderToolbarDivider }

    var shadowSubtle: UIColor { base.shadowSubtle }
    var shadowStrong: UIColor { base.shadowStrong }
    var shadowBorder: UIColor { base.shadowBorder }

    var gradientOnboardingStop1: UIColor { base.gradientOnboardingStop1 }
    var gradientOnboardingStop2: UIColor { base.gradientOnboardingStop2 }
    var gradientOnboardingStop3: UIColor { base.gradientOnboardingStop3 }
    var gradientOnboardingStop4: UIColor { base.gradientOnboardingStop4 }

    init(base: ThemeColourPalette, overrides: PartialOverrides) {
        self.base = base
        self.partialOverrides = overrides
    }
}
