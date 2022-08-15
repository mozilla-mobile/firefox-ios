// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

public struct BottomSheetViewModel {

    public var cornerRadius: CGFloat
    public var animationTransitionDuration: TimeInterval
    public var backgroundColor: UIColor
    public var sheetLightThemeBackgroundColor: UIColor
    public var sheetDarkThemeBackgroundColor: UIColor

    public init() {
        cornerRadius = 8
        animationTransitionDuration = 0.3
        backgroundColor = .clear
        sheetLightThemeBackgroundColor = UIColor.Photon.LightGrey10
        sheetDarkThemeBackgroundColor = UIColor.Photon.DarkGrey40
    }

    public init(cornerRadius: CGFloat,
                animationTransitionDuration: TimeInterval,
                backgroundColor: UIColor,
                sheetLightThemeBackgroundColor: UIColor,
                sheetDarkThemeBackgroundColor: UIColor) {
        self.cornerRadius = cornerRadius
        self.animationTransitionDuration = animationTransitionDuration
        self.backgroundColor = backgroundColor
        self.sheetLightThemeBackgroundColor = sheetLightThemeBackgroundColor
        self.sheetDarkThemeBackgroundColor = sheetDarkThemeBackgroundColor
    }
}
