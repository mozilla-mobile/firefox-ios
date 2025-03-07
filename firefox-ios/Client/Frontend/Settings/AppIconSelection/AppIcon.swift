// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum AppIcon: String, CaseIterable {
    /// The default system app icon.
    case regular

    /// The old app icon before the iOS 18 light/dark/tinted update. Has a purple dark background in all modes.
    case darkPurple

    /// An artsy app icon of a person hugging the Firefox logo. Has a light orange background in all modes.
    case hug

    /// The name of the asset to display in the app selection.
    var displayName: String {
        switch self {
        case .regular:
            return .Settings.AppIconSelection.AppIconNames.Regular
        case .darkPurple:
            return .Settings.AppIconSelection.AppIconNames.DarkPurple
        case .hug:
            return .Settings.AppIconSelection.AppIconNames.Hug
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
        case .hug:
            return "appIconAlternate_hug"
        }
    }

    /// The name of the App Icon asset type. `UIImage`s can only be rendered from image sets, not app icon sets.
    var appIconAssetName: String? {
        switch self {
        case .regular:
            return nil // Setting the alternative app icon to nil will restore the default app icon asset
        case .darkPurple:
            return "AppIcon_Alt_DarkPurple"
        case .hug:
            return "AppIcon_Alt_Hug"
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
