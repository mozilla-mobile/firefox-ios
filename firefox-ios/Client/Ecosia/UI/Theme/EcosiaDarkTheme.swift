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
    var backgroundPrimaryDecorative: UIColor = EcosiaColor.Gray90
    var backgroundSecondary: UIColor = EcosiaColor.Gray80
    var backgroundTertiary: UIColor = EcosiaColor.Gray70
    var backgroundQuaternary: UIColor = EcosiaColor.Gray70
    var backgroundElevation1: UIColor = EcosiaColor.Gray80
    var backgroundElevation2: UIColor = EcosiaColor.Gray70
    var backgroundBrandSecondaryAlt: UIColor = EcosiaColor.Gray80
    var borderDecorative: UIColor = EcosiaColor.Gray60
    var brandPrimary: UIColor = EcosiaColor.Green30
    var buttonBackgroundPrimary: UIColor = EcosiaColor.Green30
    var buttonBackgroundPrimaryActive: UIColor = EcosiaColor.Green20
    var buttonBackgroundSecondary: UIColor = EcosiaColor.Gray90
    var buttonBackgroundSecondaryHover: UIColor = EcosiaColor.Gray70
    var buttonContentSecondary: UIColor = EcosiaColor.White
    var buttonBackgroundTransparentActive: UIColor = EcosiaColor.Gray30.withAlphaComponent(0.32)
    var iconSecondary: UIColor = EcosiaColor.Green30
    var iconDecorative: UIColor = EcosiaColor.White
    var iconInverseStrong: UIColor = EcosiaColor.Black
    var segmentedControlBackgroundActive: UIColor = EcosiaColor.Gray60
    var segmentedControlBackgroundRest: UIColor = EcosiaColor.Gray80
    var stateDisabled: UIColor = EcosiaColor.Gray50
    var stateError: UIColor = EcosiaColor.Red30
    var stateLoading: UIColor = EcosiaColor.DarkGreen30
    var textPrimary: UIColor = EcosiaColor.White
    var textInversePrimary: UIColor = EcosiaColor.Gray90
    var textSecondary: UIColor = EcosiaColor.Gray30
}
