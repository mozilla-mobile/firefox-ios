// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct EcosiaDarkTheme: Theme {
    public var type: ThemeType = .dark
    public var colors: EcosiaThemeColourPalette = EcosiaDarkColourPalette()
}

private class EcosiaDarkColourPalette: EcosiaLightColourPalette {
    override var ecosia: EcosiaSemanticColors {
        EcosiaDarkSemanticColors()
    }

    override var fallbackTheme: Theme {
        DarkTheme()
    }
}

private struct EcosiaDarkSemanticColors: EcosiaSemanticColors {
    var backgroundPrimary: UIColor = EcosiaColor.Gray90
    var backgroundSecondary: UIColor = EcosiaColor.Gray80
    var backgroundTertiary: UIColor = EcosiaColor.Gray70
    var backgroundQuaternary: UIColor = EcosiaColor.Green20
    var borderDecorative: UIColor = EcosiaColor.Gray60
    var brandPrimary: UIColor = EcosiaColor.Green30
    var buttonBackgroundPrimary: UIColor = EcosiaColor.Green30
    var buttonBackgroundPrimaryActive: UIColor = EcosiaColor.Green50 // ⚠️ Mismatch
    var buttonBackgroundSecondary: UIColor = EcosiaColor.Gray70 // ⚠️ Mismatch
    var buttonBackgroundSecondaryHover: UIColor = EcosiaColor.Gray70
    var buttonContentSecondary: UIColor = EcosiaColor.White
    var buttonBackgroundTransparentActive: UIColor = EcosiaColor.Gray30.withAlphaComponent(0.32)
    var backgroundHighlighted: UIColor = EcosiaColor.DarkGreen30
    var iconPrimary: UIColor = EcosiaColor.White
    var iconSecondary: UIColor = EcosiaColor.Green30
    var iconDecorative: UIColor = EcosiaColor.Gray40 // ⚠️ Mismatch
    var stateError: UIColor = EcosiaColor.Red30
    var stateInformation: UIColor = EcosiaColor.Blue30 // ⚠️ No match
    var stateDisabled: UIColor = EcosiaColor.Gray50
    var textPrimary: UIColor = EcosiaColor.White
    var textInversePrimary: UIColor = EcosiaColor.Black // ⚠️ Mismatch
    var textSecondary: UIColor = EcosiaColor.Gray30
    var textTertiary: UIColor = EcosiaColor.Gray70 // ⚠️ Mismatch

    // MARK: Unmapped Snowflakes
    var barBackground: UIColor = EcosiaColor.Gray80
    var barSeparator: UIColor = .Photon.Grey60
    var ntpCellBackground: UIColor = EcosiaColor.Gray70
    var ntpBackground: UIColor = EcosiaColor.Gray90
    var ntpIntroBackground: UIColor = EcosiaColor.Gray80
    var impactMultiplyCardBackground: UIColor = EcosiaColor.Gray70
    var newsPlaceholder: UIColor = EcosiaColor.Gray50
    var modalBackground: UIColor = EcosiaColor.Gray80
    var secondarySelectedBackground: UIColor = .init(rgb: 0x3A3A3A)
    var buttonBackgroundNTPCustomization: UIColor = EcosiaColor.Gray80
    var privateButtonBackground: UIColor = EcosiaColor.White
    var tabSelectedPrivateBackground: UIColor = EcosiaColor.White
    var toastImageTint: UIColor = EcosiaColor.DarkGreen50
    var newSeedCollectedCircle: UIColor = .init(rgb: 0xCC7722)
    var tabTrayScreenshotBackground: UIColor = .Photon.DarkGrey30
    var tableViewRowText: UIColor = .Photon.Grey10
    var impactNavigationBarTitleBackground: UIColor = EcosiaColor.Gray70
}
