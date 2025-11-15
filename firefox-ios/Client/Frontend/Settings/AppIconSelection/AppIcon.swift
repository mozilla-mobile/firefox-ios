// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum AppIcon: String, CaseIterable {
    // MARK: Default
    /// The default system app icon.
    case regular

    // MARK: Alternative app icons that do NOT adjust to the iOS 18+ light/dark/tinted modes
    /// The old app icon before the iOS 18 light/dark/tinted update. Has a purple dark background in all modes.
    case darkPurple

    // MARK: Alternative app icons which do adjust to the iOS 18+ light/dark/tinted modes.
    // Note: Organized by category (color, gradient, and drawn)

    // MARK: Color icons. Order by Acorn color palette (approximately rainbow ordering)
    /// A red version of the icon.
    case red

    /// A orange version of the icon.
    case orange

    /// A yellow version of the icon.
    case yellow

    /// A green version of the icon.
    case green

    /// A cyan version of the icon.
    case cyan

    /// A blue version of the icon.
    case blue

    /// A purple version of the icon.
    case purple

    /// A pink version of the icon.
    case pink

    // MARK: Gradient icons. Order by time of day (sunrise -> midnight)
    /// A version of the app icon with a gradient background, light blue fading to yellow.
    case sunrise

    /// A version of the app icon with a gradient background, light blue fading to light purple.
    case midday

    /// A version of the app icon with a gradient background, yellow fading to orange.
    case goldenHour

    /// A version of the app icon with a gradient background, purple fading to pink.
    case sunset

    /// A version of the app icon with a gradient background, blue fading to purple.
    case blueHour

    /// A version of the app icon with a gradient background, dark blue fading to light blue.
    case twilight

    /// A version of the app icon with a gradient background, black fading to dark purple.
    case midnight

    /// A version of the app icon with a gradient background, purple fading to blue fading to green.
    case northernLights

    // MARK: Fun
    /// A version of the app icon with a fox outline with sunglasses.
    case cool

    /// A version of the app icon with a fox cuddling a globe.
    case cuddling

    /// A version of the app icon with a fox outline with flames.
    case flaming

    /// A version of the app icon with a one-colored fox outline.
    case minimal

    /// A version of the app icon with a cartoony fox resting on a globe.
    case momo

    /// A version of the app icon with a pixelated fox resting on a globe.
    case pixelated

    /// A version of the app icon with a fox outline in rainbow colors.
    case pride

    /// A version of the app icon with a fox resting on a globe with visible continents.
    case retro2004

    /// A version of the app icon with a fox resting on a stylized globe.
    case retro2017

    /// The name of the asset to display in the app selection.
    var displayName: String {
        switch self {
        case .regular:
            return .Settings.AppIconSelection.AppIconNames.Regular
        case .darkPurple:
            return .Settings.AppIconSelection.AppIconNames.DarkPurple
        // MARK: Colors
        case .red:
            return .Settings.AppIconSelection.AppIconNames.Red
        case .orange:
            return .Settings.AppIconSelection.AppIconNames.Orange
        case .yellow:
            return .Settings.AppIconSelection.AppIconNames.Yellow
        case .green:
            return .Settings.AppIconSelection.AppIconNames.Green
        case .cyan:
            return .Settings.AppIconSelection.AppIconNames.Cyan
        case .blue:
            return .Settings.AppIconSelection.AppIconNames.Blue
        case .purple:
            return .Settings.AppIconSelection.AppIconNames.Purple
        case .pink:
            return .Settings.AppIconSelection.AppIconNames.Pink
        // MARK: Gradients
        case .sunrise:
            return .Settings.AppIconSelection.AppIconNames.Sunrise
        case .midday:
            return .Settings.AppIconSelection.AppIconNames.Midday
        case .goldenHour:
            return .Settings.AppIconSelection.AppIconNames.GoldenHour
        case .sunset:
            return .Settings.AppIconSelection.AppIconNames.Sunset
        case .blueHour:
            return .Settings.AppIconSelection.AppIconNames.BlueHour
        case .twilight:
            return .Settings.AppIconSelection.AppIconNames.Twilight
        case .midnight:
            return .Settings.AppIconSelection.AppIconNames.Midnight
        case .northernLights:
            return .Settings.AppIconSelection.AppIconNames.NorthernLights
        // MARK: Fun
        case .cool:
            return .Settings.AppIconSelection.AppIconNames.Fun.Cool
        case .cuddling:
            return .Settings.AppIconSelection.AppIconNames.Fun.Cuddling
        case .flaming:
            return .Settings.AppIconSelection.AppIconNames.Fun.Flaming
        case .minimal:
            return .Settings.AppIconSelection.AppIconNames.Minimal
        case .momo:
            return .Settings.AppIconSelection.AppIconNames.FromContributors.Momo
        case .pixelated:
            return .Settings.AppIconSelection.AppIconNames.Pixelated
        case .pride:
            return .Settings.AppIconSelection.AppIconNames.Pride
        case .retro2004:
            return .Settings.AppIconSelection.AppIconNames.Retro2004
        case .retro2017:
            return .Settings.AppIconSelection.AppIconNames.Retro2017
        }
    }

    var telemetryName: String {
        return self.rawValue
    }

    /// The name of the image set asset type. `UIImage`s can only be rendered from image sets, not app icon sets.
    var imageSetAssetName: String {
        switch self {
        case .regular:
            return "appIconAlternate_default"
        case .darkPurple:
            return "appIconAlternate_darkPurple"
        // MARK: Colors
        case .red:
            return "appIconAlternate_color_red"
        case .orange:
            return "appIconAlternate_color_orange"
        case .yellow:
            return "appIconAlternate_color_yellow"
        case .green:
            return "appIconAlternate_color_green"
        case .cyan:
            return "appIconAlternate_color_cyan"
        case .blue:
            return "appIconAlternate_color_blue"
        case .purple:
            return "appIconAlternate_color_purple"
        case .pink:
            return "appIconAlternate_color_pink"
        // MARK: Gradients
        case .sunrise:
            return "appIconAlternate_gradient_sunrise"
        case .midday:
            return "appIconAlternate_gradient_midday"
        case .goldenHour:
            return "appIconAlternate_gradient_goldenHour"
        case .sunset:
            return "appIconAlternate_gradient_sunset"
        case .blueHour:
            return "appIconAlternate_gradient_blueHour"
        case .twilight:
            return "appIconAlternate_gradient_twilight"
        case .midnight:
            return "appIconAlternate_gradient_midnight"
        case .northernLights:
            return "appIconAlternate_gradient_northernLights"
        // MARK: Fun
        case .cool:
            return "appIconAlternate_fun_cool"
        case .cuddling:
            return "appIconAlternate_fun_cuddling"
        case .flaming:
            return "appIconAlternate_fun_flaming"
        case .minimal:
            return "appIconAlternate_fun_minimal"
        case .momo:
            return "appIconAlternate_fun_momo"
        case .pixelated:
            return "appIconAlternate_fun_pixelated"
        case .pride:
            return "appIconAlternate_fun_pride"
        case .retro2004:
            return "appIconAlternate_fun_retro2004"
        case .retro2017:
            return "appIconAlternate_fun_retro2017"
        }
    }

    /// The name of the App Icon asset type. `UIImage`s can only be rendered from image sets, not app icon sets.
    var appIconAssetName: String? {
        switch self {
        case .regular:
            return nil // Setting the alternative app icon to nil will restore the default app icon asset
        case .darkPurple:
            return "AppIcon_Alt_DarkPurple"
        // MARK: Colors
        case .red:
            return "AppIcon_Alt_Color_Red"
        case .orange:
            return "AppIcon_Alt_Color_Orange"
        case .yellow:
            return "AppIcon_Alt_Color_Yellow"
        case .green:
            return "AppIcon_Alt_Color_Green"
        case .cyan:
            return "AppIcon_Alt_Color_Cyan"
        case .blue:
            return "AppIcon_Alt_Color_Blue"
        case .purple:
            return "AppIcon_Alt_Color_Purple"
        case .pink:
            return "AppIcon_Alt_Color_Pink"
        // MARK: Gradients
        case .sunrise:
            return "AppIcon_Alt_Gradient_Sunrise"
        case .midday:
            return "AppIcon_Alt_Gradient_Midday"
        case .goldenHour:
            return "AppIcon_Alt_Gradient_GoldenHour"
        case .sunset:
            return "AppIcon_Alt_Gradient_Sunset"
        case .blueHour:
            return "AppIcon_Alt_Gradient_BlueHour"
        case .twilight:
            return "AppIcon_Alt_Gradient_Twilight"
        case .midnight:
            return "AppIcon_Alt_Gradient_Midnight"
        case .northernLights:
            return "AppIcon_Alt_Gradient_NorthernLights"
        // MARK: Fun
        case .cool:
            return "AppIcon_Alt_Fun_Cool"
        case .cuddling:
            return "AppIcon_Alt_Fun_Cuddling"
        case .flaming:
            return "AppIcon_Alt_Fun_Flaming"
        case .minimal:
            return "AppIcon_Alt_Fun_Minimal"
        case .momo:
            return "AppIcon_Alt_Fun_Momo"
        case .pixelated:
            return "AppIcon_Alt_Fun_Pixelated"
        case .pride:
            return "AppIcon_Alt_Fun_Pride"
        case .retro2004:
            return "AppIcon_Alt_Fun_Retro2004"
        case .retro2017:
            return "AppIcon_Alt_Fun_Retro2017"
        }
    }

    /// Determines whether the icon belongs to the fun icon set behind a feature flag.
    var isFunIcon: Bool {
        switch self {
        case .cool, .cuddling, .flaming:
            return true
        default:
            return false
        }
    }

    /// Initialize an `AppIcon` from the current `UIApplication.shared.alternateIconName` setting. If the icon cannot be
    /// identified, returns `nil`. This might happen if an old asset is renamed or removed from the asset catalog.
    @MainActor
    static func initFromSystem() -> AppIcon? {
        if let currentAlternativeIcon = UIApplication.shared.alternateIconName {
            let matchingAppIcons = AppIcon.allCases.filter({ $0.appIconAssetName == currentAlternativeIcon })
            guard let alternateAppIcon = matchingAppIcons.first else {
                return nil
            }

            return alternateAppIcon
        } else {
            return .regular
        }
    }
}
