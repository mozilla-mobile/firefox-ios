// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// This file is owned by Ecosia, it is only part of BrowserKit.Common since it needs to be used inside it.
// It contains all of Ecosia official semantic color tokens referenced in the link below. Do not add a color that is not mapped there!
// https://www.figma.com/design/8T2rTBVwynJKSdY6MQo5PQ/%E2%9A%9B%EF%B8%8F--Foundations?node-id=2237-3418&t=UKHtrxcc9UtOihsm-0
// They are adopted by `EcosiaLightTheme` and `EcosiaDarkTheme` and should use `EcosiaColorPrimitive`.
public protocol EcosiaSemanticColors {
    // MARK: - Background
    var backgroundPrimary: UIColor { get }
    var backgroundSecondary: UIColor { get }
    var backgroundTertiary: UIColor { get }
    var backgroundQuaternary: UIColor { get }

    // MARK: - Border
    var borderDecorative: UIColor { get }

    // MARK: - Brand
    var brandPrimary: UIColor { get }

    // MARK: - Button
    var buttonBackgroundPrimary: UIColor { get }
    var buttonBackgroundPrimaryActive: UIColor { get }
    var buttonBackgroundSecondary: UIColor { get }
    var buttonBackgroundSecondaryHover: UIColor { get }
    var buttonContentSecondary: UIColor { get }
    var buttonBackgroundTransparentActive: UIColor { get }

    // MARK: - State
    var stateInformation: UIColor { get }
    var stateDisabled: UIColor { get }

    // MARK: - Text
    var textPrimary: UIColor { get }
    var textInversePrimary: UIColor { get }
    var textSecondary: UIColor { get }
    var textTertiary: UIColor { get }

    // MARK: - Snowflakes ⚠️ to be assessed ⚠️
    var iconPrimary: UIColor { get }
    var iconSecondary: UIColor { get }
    var iconDecorative: UIColor { get }
    var stateError: UIColor { get }
    var backgroundHighlighted: UIColor { get } // Mapped as "loading"

    // MARK: Unmapped Snowflakes
    var barBackground: UIColor { get } // Light.backgroundPrimary + Dark.backgroundSecondary
    var barSeparator: UIColor { get }
    var ntpCellBackground: UIColor { get }
    var ntpBackground: UIColor { get } // Light.backgroundTertiary + Dark.backgroundPrimary
    var ntpIntroBackground: UIColor { get } // == barBackground
    var impactMultiplyCardBackground: UIColor { get } // == ntpCellBackground
    var newsPlaceholder: UIColor { get }
    var modalBackground: UIColor { get } // Light.backgroundTertiary + Dark.backgroundSecondary
    var secondarySelectedBackground: UIColor { get }
    var buttonBackgroundNTPCustomization: UIColor { get }
    var privateButtonBackground: UIColor { get }
    var tabSelectedPrivateBackground: UIColor { get }
    var toastImageTint: UIColor { get }
    var newSeedCollectedCircle: UIColor { get }
    var tabTrayScreenshotBackground: UIColor { get }
    var tableViewRowText: UIColor { get }
    var impactNavigationBarTitleBackground: UIColor { get }
}

public protocol EcosiaThemeColourPalette: ThemeColourPalette {
    var ecosia: EcosiaSemanticColors { get }
}

/// Serves to make Firefox themes conform the new protocol.
/// Should never end up in production UI!
class FakeEcosiaSemanticColors: EcosiaSemanticColors {
    var backgroundPrimary: UIColor = .systemGray
    var backgroundSecondary: UIColor = .systemGray
    var backgroundTertiary: UIColor = .systemGray
    var backgroundQuaternary: UIColor = .systemGray
    var borderDecorative: UIColor = .systemGray
    var brandPrimary: UIColor = .systemGray
    var buttonBackgroundPrimary: UIColor = .systemGray
    var buttonBackgroundPrimaryActive: UIColor = .systemGray
    var buttonBackgroundSecondary: UIColor = .systemGray
    var buttonBackgroundSecondaryHover: UIColor = .systemGray
    var buttonContentSecondary: UIColor = .systemGray
    var buttonBackgroundTransparentActive: UIColor = .systemGray
    var iconPrimary: UIColor = .systemGray
    var iconSecondary: UIColor = .systemGray
    var iconDecorative: UIColor = .systemGray
    var stateError: UIColor = .systemGray
    var stateInformation: UIColor = .systemGray
    var stateDisabled: UIColor = .systemGray
    var textPrimary: UIColor = .systemGray
    var textInversePrimary: UIColor = .systemGray
    var textSecondary: UIColor = .systemGray
    var textTertiary: UIColor = .systemGray
    var backgroundHighlighted: UIColor = .systemGray
    var barBackground: UIColor = .systemGray
    var barSeparator: UIColor = .systemGray
    var ntpCellBackground: UIColor = .systemGray
    var ntpBackground: UIColor = .systemGray
    var ntpIntroBackground: UIColor = .systemGray
    var impactMultiplyCardBackground: UIColor = .systemGray
    var newsPlaceholder: UIColor = .systemGray
    var modalBackground: UIColor = .systemGray
    var secondarySelectedBackground: UIColor = .systemGray
    var buttonBackgroundNTPCustomization: UIColor = .systemGray
    var privateButtonBackground: UIColor = .systemGray
    var tabSelectedPrivateBackground: UIColor = .systemGray
    var toastImageTint: UIColor = .systemGray
    var newSeedCollectedCircle: UIColor = .systemGray
    var tabTrayScreenshotBackground: UIColor = .systemGray
    var tableViewRowText: UIColor = .systemGray
    var impactNavigationBarTitleBackground: UIColor = .systemGray
}
