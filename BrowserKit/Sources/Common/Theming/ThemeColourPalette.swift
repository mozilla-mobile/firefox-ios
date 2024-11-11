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
    var layerSelectedText: UIColor { get }
    var layerAutofillText: UIColor { get }
    var layerSearch: UIColor { get }
    var layerGradientURL: Gradient { get }

    // MARK: - Ratings
    var layerRatingA: UIColor { get }
    var layerRatingASubdued: UIColor { get }
    var layerRatingB: UIColor { get }
    var layerRatingBSubdued: UIColor { get }
    var layerRatingC: UIColor { get }
    var layerRatingCSubdued: UIColor { get }
    var layerRatingD: UIColor { get }
    var layerRatingDSubdued: UIColor { get }
    var layerRatingF: UIColor { get }
    var layerRatingFSubdued: UIColor { get }

    // MARK: - Actions
    var actionPrimary: UIColor { get }
    var actionPrimaryHover: UIColor { get }
    var actionPrimaryDisabled: UIColor { get }
    var actionSecondary: UIColor { get }
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

    // MARK: - Border
    var borderPrimary: UIColor { get }
    var borderAccent: UIColor { get }
    var borderAccentNonOpaque: UIColor { get }
    var borderAccentPrivate: UIColor { get }
    var borderInverted: UIColor { get }
    var borderToolbarDivider: UIColor { get }

    // MARK: - Shadow
    var shadowDefault: UIColor { get }
}
