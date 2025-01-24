// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/*
 
The purpose of this file is to build an adapter layer and begin to utilize the `ThemeColourPalette` that Firefox provide.
WHY?
In the previous releases of Firefox the theming architecture relied on a protocol approach without any sort of dependency injection as part of the `applyTheme()` function.
 However, since the codebase bigger restructure, the Theming has gone thru a major refactor as well.
 By having this adapter in, we can benefit of the `Theme` object being passed as part of the `func applyTheme(theme: Theme)` function so that all the places having it implemented will receive the new colors.
 The setup of these Dark and Light Ecosia's Colour Palette is definted by the `EcosiaThemeManager`.
 However, the need of a `fallbackDefaultThemeManager` of type `DefaultThemeManager` is crucial as we don't have all the colors defined ourselves and we rely on the Firefox ones we can't get access to as part of the `BrowserKit` package.
 Once and if we'll have all the colors defined, we can remove the `fallbackDefaultThemeManager` variable.
*/

import Common
import UIKit

public struct EcosiaLightTheme: Theme {
    public var type: ThemeType = .light
    public var colors: ThemeColourPalette = EcosiaLightColourPalette()
}

public struct EcosiaDarkTheme: Theme {
    public var type: ThemeType = .dark
    public var colors: ThemeColourPalette = EcosiaDarkColourPalette()
}

private class EcosiaDarkColourPalette: EcosiaLightColourPalette {

    override var fallbackTheme: Theme {
        DarkTheme()
    }

    override var layer1: UIColor { .legacyTheme.ecosia.primaryBackground }
}

private class EcosiaLightColourPalette: ThemeColourPalette {

    // TODO Ecosia Upgrade: Review new colors and older ones that are no longer on the protocol [MOB-3152]
    var layerInformation: UIColor { fallbackTheme.colors.layerInformation }
    var layerSuccess: UIColor { fallbackTheme.colors.layerSuccess }
    var layerCritical: UIColor { fallbackTheme.colors.layerCritical }
    var layerSelectedText: UIColor { fallbackTheme.colors.layerSelectedText }
    var layerAutofillText: UIColor { fallbackTheme.colors.layerAutofillText }
    var actionPrimaryDisabled: UIColor { fallbackTheme.colors.actionPrimaryDisabled }
    var actionSuccess: UIColor { fallbackTheme.colors.actionSuccess }
    var actionCritical: UIColor { fallbackTheme.colors.actionCritical }
    var actionInformation: UIColor { fallbackTheme.colors.actionInformation }
    var textCritical: UIColor { fallbackTheme.colors.textCritical }
    var textInvertedDisabled: UIColor { fallbackTheme.colors.textInvertedDisabled }
    var iconAccent: UIColor { fallbackTheme.colors.iconAccent }
    var iconCritical: UIColor { fallbackTheme.colors.iconCritical }
    var iconRatingNeutral: UIColor { fallbackTheme.colors.iconRatingNeutral }

    /* TODO Ecosia Upgrade: Review if ok to switch to directly linking fallback theme. [MOB-3152]
    // The alternative is receiving window here since `getCurrentTheme` now requires it.
     let fallbackDefaultThemeManager: ThemeManager = DefaultThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)
     */
    var fallbackTheme: Theme {
        LightTheme()
    }

    // MARK: - Layers
    var layer1: UIColor { .legacyTheme.ecosia.tertiaryBackground }
    var layer2: UIColor { fallbackTheme.colors.layer2 }
    var layer3: UIColor { .legacyTheme.ecosia.ntpBackground }
    var layer4: UIColor { fallbackTheme.colors.layer4 }
    var layer5: UIColor { .legacyTheme.ecosia.secondaryBackground }
    var layer6: UIColor { .legacyTheme.ecosia.homePanelBackground }
    var layer5Hover: UIColor { .legacyTheme.ecosia.secondarySelectedBackground }
    var layerScrim: UIColor { fallbackTheme.colors.layerScrim }
    var layerGradient: Common.Gradient { fallbackTheme.colors.layerGradient }
    var layerGradientOverlay: Common.Gradient { fallbackTheme.colors.layerGradientOverlay }
    var layerAccentNonOpaque: UIColor { .legacyTheme.ecosia.primaryButton }
    var layerAccentPrivate: UIColor { fallbackTheme.colors.layerAccentPrivate }
    var layerAccentPrivateNonOpaque: UIColor { .legacyTheme.ecosia.primaryText }
    var layerSepia: UIColor { fallbackTheme.colors.layerSepia }
    var layerWarning: UIColor { .legacyTheme.ecosia.warning }
    var layerRatingA: UIColor { fallbackTheme.colors.layerRatingA }
    var layerRatingASubdued: UIColor { fallbackTheme.colors.layerRatingASubdued }
    var layerRatingB: UIColor { fallbackTheme.colors.layerRatingB }
    var layerRatingBSubdued: UIColor { fallbackTheme.colors.layerRatingBSubdued }
    var layerRatingC: UIColor { fallbackTheme.colors.layerRatingC }
    var layerRatingCSubdued: UIColor { fallbackTheme.colors.layerRatingCSubdued }
    var layerRatingD: UIColor { fallbackTheme.colors.layerRatingD }
    var layerRatingDSubdued: UIColor { fallbackTheme.colors.layerRatingDSubdued }
    var layerRatingF: UIColor { fallbackTheme.colors.layerRatingF }
    var layerRatingFSubdued: UIColor { fallbackTheme.colors.layerRatingFSubdued }
    var layerHomepage: Common.Gradient { fallbackTheme.colors.layerHomepage }
    var layerSearch: UIColor { fallbackTheme.colors.layerSearch }
    var layerGradientURL: Common.Gradient { fallbackTheme.colors.layerGradientURL }
    var actionTabActive: UIColor { fallbackTheme.colors.actionTabActive }
    var actionTabInactive: UIColor { fallbackTheme.colors.actionTabInactive }
    var borderToolbarDivider: UIColor { fallbackTheme.colors.borderToolbarDivider }

    // MARK: - Actions
    var actionPrimary: UIColor { .legacyTheme.ecosia.primaryButton }
    var actionPrimaryHover: UIColor { .legacyTheme.ecosia.primaryButtonActive }
    var actionSecondary: UIColor { .legacyTheme.ecosia.secondaryButton }
    var actionSecondaryHover: UIColor { fallbackTheme.colors.actionSecondaryHover }
    var formSurfaceOff: UIColor { fallbackTheme.colors.formSurfaceOff }
    var formKnob: UIColor { fallbackTheme.colors.formKnob }
    var indicatorActive: UIColor { fallbackTheme.colors.indicatorActive }
    var indicatorInactive: UIColor { fallbackTheme.colors.indicatorInactive }
    var actionWarning: UIColor { .legacyTheme.ecosia.warning }

    // MARK: - Text
    var textPrimary: UIColor { .legacyTheme.ecosia.primaryText }
    var textSecondary: UIColor { .legacyTheme.ecosia.secondaryText }
    var textDisabled: UIColor { fallbackTheme.colors.textDisabled }
    var textAccent: UIColor { .legacyTheme.ecosia.primaryButton }
    var textOnDark: UIColor { fallbackTheme.colors.textOnDark }
    var textOnLight: UIColor { fallbackTheme.colors.textOnLight }
    var textInverted: UIColor { .legacyTheme.ecosia.primaryTextInverted }

    // MARK: - Icons
    var iconPrimary: UIColor { .legacyTheme.ecosia.primaryIcon }
    var iconSecondary: UIColor { .legacyTheme.ecosia.secondaryIcon }
    var iconDisabled: UIColor { fallbackTheme.colors.iconDisabled }
    var iconOnColor: UIColor { fallbackTheme.colors.iconOnColor }
    var iconWarning: UIColor { .legacyTheme.ecosia.warning }
    var iconSpinner: UIColor { fallbackTheme.colors.iconSpinner }
    var iconAccentViolet: UIColor { fallbackTheme.colors.iconAccentViolet }
    var iconAccentBlue: UIColor { fallbackTheme.colors.iconAccentBlue }
    var iconAccentPink: UIColor { fallbackTheme.colors.iconAccentPink }
    var iconAccentGreen: UIColor { fallbackTheme.colors.iconAccentGreen }
    var iconAccentYellow: UIColor { fallbackTheme.colors.iconAccentYellow }

    // MARK: - Border
    var borderPrimary: UIColor { .legacyTheme.ecosia.barSeparator }
    var borderAccent: UIColor { actionPrimary }
    var borderAccentNonOpaque: UIColor { actionPrimary }
    var borderAccentPrivate: UIColor { actionPrimary }
    var borderInverted: UIColor { fallbackTheme.colors.borderInverted }

    // MARK: - Shadow
    var shadowDefault: UIColor { fallbackTheme.colors.shadowDefault }
}
