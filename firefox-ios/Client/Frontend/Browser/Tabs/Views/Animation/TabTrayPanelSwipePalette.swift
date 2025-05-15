// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct TabTrayPanelSwipePalette: ThemeColourPalette {
    private let base: ThemeColourPalette

    // MARK: Overridden colors
    var layer1: UIColor
    var iconPrimary: UIColor
    var textPrimary: UIColor
    var actionSecondary: UIColor
    var layerScrim: UIColor
    var layer3: UIColor
    var textOnDark: UIColor
    var borderPrimary: UIColor
    var borderAccent: UIColor
    var borderAccentPrivate: UIColor
    var shadowDefault: UIColor

    init(base: ThemeColourPalette, overrides: PartialOverrides) {
        self.base = base
        self.layer1 = overrides.layer1
        self.iconPrimary = overrides.iconPrimary
        self.textPrimary = overrides.textPrimary
        self.actionSecondary = overrides.actionSecondary
        self.layerScrim = overrides.layerScrim
        self.layer3 = overrides.layer3
        self.textOnDark = overrides.textOnDark
        self.borderPrimary = overrides.borderPrimary
        self.borderAccent = overrides.borderAccent
        self.borderAccentPrivate = overrides.borderAccentPrivate
        self.shadowDefault = overrides.shadowDefault
    }

    struct PartialOverrides {
        var layer1: UIColor
        var iconPrimary: UIColor
        var textPrimary: UIColor
        var actionSecondary: UIColor
        var layerScrim: UIColor
        var layer3: UIColor
        var textOnDark: UIColor
        var borderPrimary: UIColor
        var borderAccent: UIColor
        var borderAccentPrivate: UIColor
        var shadowDefault: UIColor
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
    var layerSelectedText: UIColor { base.layerSelectedText }
    var layerAutofillText: UIColor { base.layerAutofillText }
    var layerSearch: UIColor { base.layerSearch }
    var layerGradientURL: Gradient { base.layerGradientURL }

    var layerRatingA: UIColor { base.layerRatingA }
    var layerRatingASubdued: UIColor { base.layerRatingASubdued }
    var layerRatingB: UIColor { base.layerRatingB }
    var layerRatingBSubdued: UIColor { base.layerRatingBSubdued }
    var layerRatingC: UIColor { base.layerRatingC }
    var layerRatingCSubdued: UIColor { base.layerRatingCSubdued }
    var layerRatingD: UIColor { base.layerRatingD }
    var layerRatingDSubdued: UIColor { base.layerRatingDSubdued }
    var layerRatingF: UIColor { base.layerRatingF }
    var layerRatingFSubdued: UIColor { base.layerRatingFSubdued }

    var actionPrimary: UIColor { base.actionPrimary }
    var actionPrimaryHover: UIColor { base.actionPrimaryHover }
    var actionPrimaryDisabled: UIColor { base.actionPrimaryDisabled }
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

    var textSecondary: UIColor { base.textSecondary }
    var textDisabled: UIColor { base.textDisabled }
    var textCritical: UIColor { base.textCritical }
    var textAccent: UIColor { base.textAccent }
    var textOnLight: UIColor { base.textOnLight }
    var textInverted: UIColor { base.textInverted }
    var textInvertedDisabled: UIColor { base.textInvertedDisabled }

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

    var borderAccentNonOpaque: UIColor { base.borderAccentNonOpaque }
    var borderInverted: UIColor { base.borderInverted }
    var borderToolbarDivider: UIColor { base.borderToolbarDivider }

    var shadowSubtle: UIColor { base.shadowSubtle }
    var shadowStrong: UIColor { base.shadowStrong }
}
