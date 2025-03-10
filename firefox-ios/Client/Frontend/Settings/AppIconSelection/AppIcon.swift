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

    // MARK: Alternative app icons which do adjust to the iOS 18+ light/dark/tinted modes. Add alphabetically.
    /// A blue version of the icon.
    case blue

    /// A blue version of the icon with a gradient background.
    case blueGradient

    /// A green version of the icon.
    case green

    /// An artsy app icon of a person hugging the Firefox logo. Has a light orange background in all modes.
    case hug

    /// An artsy app icon which has a fox sleeping on the globe.
    case lazy

    /// An orange version of the icon with a gradient background.
    case orangeGradient

    /// A pink version of the icon.
    case pink

    /// A pixelated version of the regular app icon.
    case pixelated

    /// A pride fox logo.
    case pride

    /// A red version of the icon with a gradient background.
    case redGradient

    /// The retro Firefox app icon.
    case retro

    /// The name of the asset to display in the app selection.
    var displayName: String {
        switch self {
        case .regular:
            return .Settings.AppIconSelection.AppIconNames.Regular
        case .darkPurple:
            return .Settings.AppIconSelection.AppIconNames.DarkPurple
        case .blue:
            return .Settings.AppIconSelection.AppIconNames.Blue
        case .blueGradient:
            return .Settings.AppIconSelection.AppIconNames.BlueGradient
        case .green:
            return .Settings.AppIconSelection.AppIconNames.Green
        case .hug:
            return .Settings.AppIconSelection.AppIconNames.Hug
        case .lazy:
            return .Settings.AppIconSelection.AppIconNames.Lazy
        case .orangeGradient:
            return .Settings.AppIconSelection.AppIconNames.OrangeGradient
        case .pink:
            return .Settings.AppIconSelection.AppIconNames.Pink
        case .pixelated:
            return .Settings.AppIconSelection.AppIconNames.Pixelated
        case .pride:
            return .Settings.AppIconSelection.AppIconNames.Pride
        case .redGradient:
            return .Settings.AppIconSelection.AppIconNames.RedGradient
        case .retro:
            return .Settings.AppIconSelection.AppIconNames.Retro
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
        case .blue:
            return "appIconAlternate_blue"
        case .blueGradient:
            return "appIconAlternate_blueGradient"
        case .green:
            return "appIconAlternate_green"
        case .hug:
            return "appIconAlternate_hug"
        case .lazy:
            return "appIconAlternate_lazy"
        case .orangeGradient:
            return "appIconAlternate_orangeGradient"
        case .pink:
            return "appIconAlternate_pink"
        case .pixelated:
            return "appIconAlternate_pixelated"
        case .pride:
            return "appIconAlternate_pride"
        case .redGradient:
            return "appIconAlternate_redGradient"
        case .retro:
            return "appIconAlternate_retro"
        }
    }

    /// The name of the App Icon asset type. `UIImage`s can only be rendered from image sets, not app icon sets.
    var appIconAssetName: String? {
        switch self {
        case .regular:
            return nil // Setting the alternative app icon to nil will restore the default app icon asset
        case .darkPurple:
            return "AppIcon_Alt_DarkPurple"
        case .blue:
            return "AppIcon_Alt_Blue"
        case .blueGradient:
            return "AppIcon_Alt_BlueGradient"
        case .green:
            return "AppIcon_Alt_Green"
        case .hug:
            return "AppIcon_Alt_Hug"
        case .lazy:
            return "AppIcon_Alt_Lazy"
        case .orangeGradient:
            return "AppIcon_Alt_OrangeGradient"
        case .pink:
            return "AppIcon_Alt_Pink"
        case .pixelated:
            return "AppIcon_Alt_Pixelated"
        case .pride:
            return "AppIcon_Alt_Pride"
        case .redGradient:
            return "AppIcon_Alt_RedGradient"
        case .retro:
            return "AppIcon_Alt_Retro"
        }
    }

    /// Initialize an `AppIcon` from the current `UIApplication.shared.alternateIconName` setting. If the icon cannot be
    /// identified, returns `nil`. This might happen if an old asset is renamed or removed from the asset catalog.
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
