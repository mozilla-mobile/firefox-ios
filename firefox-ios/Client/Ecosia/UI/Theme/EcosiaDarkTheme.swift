// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Ecosia

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
    var backgroundNeutralInverse: UIColor = EcosiaColor.White
    var backgroundFeatured: UIColor = EcosiaColor.Grellow100
    var backgroundPrimary: UIColor = EcosiaColor.Gray90
    var backgroundPrimaryDecorative: UIColor = EcosiaColor.Gray90
    var backgroundRoleNegative: UIColor = EcosiaColor.Claret800
    var backgroundSecondary: UIColor = EcosiaColor.Gray80
    var backgroundTertiary: UIColor = EcosiaColor.Gray70
    var backgroundQuaternary: UIColor = EcosiaColor.Gray70
    var backgroundElevation1: UIColor = EcosiaColor.Gray80
    var backgroundElevation2: UIColor = EcosiaColor.Gray70
    var borderDecorative: UIColor = EcosiaColor.Gray60
    var borderNegative: UIColor = EcosiaColor.Claret600
    var brandFeatured: UIColor = EcosiaColor.Grellow100
    var brandImpact: UIColor = EcosiaColor.Yellow40
    var brandPrimary: UIColor = EcosiaColor.White
    var buttonBackgroundFeatured: UIColor = EcosiaColor.Grellow100
    var buttonBackgroundFeaturedActive: UIColor = EcosiaColor.Grellow300
    var buttonBackgroundFeaturedHover: UIColor = EcosiaColor.Grellow200
    var buttonBackgroundPrimary: UIColor = EcosiaColor.White
    var buttonBackgroundPrimaryActive: UIColor = EcosiaColor.Gray40
    var buttonBackgroundSecondary: UIColor = EcosiaColor.Gray90
    var buttonBackgroundSecondaryActive: UIColor = EcosiaColor.Gray50
    var buttonBackgroundSecondaryHover: UIColor = EcosiaColor.Gray70
    var buttonContentSecondary: UIColor = EcosiaColor.White
    var buttonContentSecondaryStatic: UIColor = EcosiaColor.Gray70
    var highlighter: UIColor = EcosiaColor.Grellow100.withAlphaComponent(0.32)
    var linkPrimary: UIColor = EcosiaColor.White
    var iconDecorative: UIColor = EcosiaColor.White
    var iconInverseStrong: UIColor = EcosiaColor.Black
    var segmentedControlBackgroundActive: UIColor = EcosiaColor.Gray60
    var segmentedControlBackgroundRest: UIColor = EcosiaColor.Gray80
    var stateDisabled: UIColor = EcosiaColor.Gray50
    var stateError: UIColor = EcosiaColor.Red30
    var switchKnobActive: UIColor = EcosiaColor.Gray70
    var switchKnobDisabled: UIColor = EcosiaColor.White
    var textPrimary: UIColor = EcosiaColor.White
    var textInversePrimary: UIColor = EcosiaColor.Gray90
    var textSecondary: UIColor = EcosiaColor.Gray30
    var textStaticDark: UIColor = EcosiaColor.Gray70
}
