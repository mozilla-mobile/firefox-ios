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

    public init() {}
}

public struct EcosiaDarkTheme: Theme {
    public var type: ThemeType = .dark
    public var colors: ThemeColourPalette = EcosiaDarkColourPalette()

    public init() {}
}

private class EcosiaDarkColourPalette: EcosiaLightColourPalette {}

private class EcosiaLightColourPalette: ThemeColourPalette {
    
    private static var fallbackDefaultThemeManager: ThemeManager = {
        DefaultThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)
    }()
        
    // MARK: - Layers
    var layer1: UIColor = .legacyTheme.ecosia.primaryBackground
    var layer2: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layer2
    var layer3: UIColor = .legacyTheme.ecosia.primaryBackground
    var layer4: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layer4
    var layer5: UIColor = .legacyTheme.ecosia.secondaryBackground
    var layer6: UIColor = .legacyTheme.ecosia.homePanelBackground
    var layer5Hover: UIColor = .legacyTheme.ecosia.secondarySelectedBackground
    var layerScrim: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerScrim
    var layerGradient = fallbackDefaultThemeManager.currentTheme.colors.layerGradient
    var layerGradientOverlay = fallbackDefaultThemeManager.currentTheme.colors.layerGradientOverlay
    var layerAccentNonOpaque: UIColor = .legacyTheme.ecosia.primaryButton
    var layerAccentPrivate: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerAccentPrivate
    var layerAccentPrivateNonOpaque: UIColor = .legacyTheme.ecosia.primaryText
    var layerLightGrey30: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerLightGrey30
    var layerSepia: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerSepia
    var layerInfo: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerInfo
    var layerConfirmation: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerConfirmation
    var layerWarning: UIColor = .legacyTheme.ecosia.warning
    var layerError: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerError
    var layerRatingA: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingA
    var layerRatingASubdued: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingASubdued
    var layerRatingB: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingB
    var layerRatingBSubdued: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingBSubdued
    var layerRatingC: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingC
    var layerRatingCSubdued: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingCSubdued
    var layerRatingD: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingD
    var layerRatingDSubdued: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingDSubdued
    var layerRatingF: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingF
    var layerRatingFSubdued: UIColor = fallbackDefaultThemeManager.currentTheme.colors.layerRatingFSubdued

    // MARK: - Actions
    var actionPrimary: UIColor = .legacyTheme.ecosia.primaryButton
    var actionPrimaryHover: UIColor = .legacyTheme.ecosia.primaryButtonActive
    var actionSecondary: UIColor = .legacyTheme.ecosia.secondaryButton
    var actionSecondaryHover: UIColor = fallbackDefaultThemeManager.currentTheme.colors.actionSecondaryHover
    var formSurfaceOff: UIColor = fallbackDefaultThemeManager.currentTheme.colors.formSurfaceOff
    var formKnob: UIColor = fallbackDefaultThemeManager.currentTheme.colors.formKnob
    var indicatorActive: UIColor = fallbackDefaultThemeManager.currentTheme.colors.indicatorActive
    var indicatorInactive: UIColor = fallbackDefaultThemeManager.currentTheme.colors.indicatorInactive
    var actionConfirmation: UIColor = fallbackDefaultThemeManager.currentTheme.colors.actionConfirmation
    var actionWarning: UIColor = .legacyTheme.ecosia.warning
    var actionError: UIColor = fallbackDefaultThemeManager.currentTheme.colors.actionError

    // MARK: - Text
    var textPrimary: UIColor = .legacyTheme.ecosia.primaryText
    var textSecondary: UIColor = .legacyTheme.ecosia.secondaryText
    var textSecondaryAction: UIColor = fallbackDefaultThemeManager.currentTheme.colors.textSecondaryAction
    var textDisabled: UIColor = fallbackDefaultThemeManager.currentTheme.colors.textDisabled
    var textWarning: UIColor = fallbackDefaultThemeManager.currentTheme.colors.textWarning
    var textAccent: UIColor = .legacyTheme.ecosia.primaryButton
    var textOnDark: UIColor = fallbackDefaultThemeManager.currentTheme.colors.textOnDark
    var textOnLight: UIColor = fallbackDefaultThemeManager.currentTheme.colors.textOnLight
    var textInverted: UIColor = .legacyTheme.ecosia.primaryTextInverted

    // MARK: - Icons
    var iconPrimary: UIColor = .legacyTheme.ecosia.primaryIcon
    var iconSecondary: UIColor = .legacyTheme.ecosia.secondaryIcon
    var iconDisabled: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconDisabled
    var iconAction: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconAction
    var iconOnColor: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconOnColor
    var iconWarning: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconWarning
    var iconSpinner: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconSpinner
    var iconAccentViolet: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconAccentViolet
    var iconAccentBlue: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconAccentBlue
    var iconAccentPink: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconAccentPink
    var iconAccentGreen: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconAccentGreen
    var iconAccentYellow: UIColor = fallbackDefaultThemeManager.currentTheme.colors.iconAccentYellow

    // MARK: - Border
    var borderPrimary: UIColor = .legacyTheme.ecosia.barSeparator
    var borderAccent: UIColor = fallbackDefaultThemeManager.currentTheme.colors.borderAccent
    var borderAccentNonOpaque: UIColor = fallbackDefaultThemeManager.currentTheme.colors.borderAccentNonOpaque
    var borderAccentPrivate: UIColor = fallbackDefaultThemeManager.currentTheme.colors.borderAccentPrivate
    var borderInverted: UIColor = fallbackDefaultThemeManager.currentTheme.colors.borderInverted

    // MARK: - Shadow
    var shadowDefault: UIColor = fallbackDefaultThemeManager.currentTheme.colors.shadowDefault
}

