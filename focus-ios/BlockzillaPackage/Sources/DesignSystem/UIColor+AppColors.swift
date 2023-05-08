/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SwiftUI

public extension UIColor {
    convenience init?(named name: String) {
        self.init(named: name, in: Bundle.myModule, compatibleWith: nil)
    }
}

public extension UIColor {

    static let above = UIColor(named: "Above")!
    static let accent = UIColor(named: "Accent")!
    static let defaultFont = UIColor(named: "DefaultFont")!
    static let firstRunTitle = UIColor(named: "FirstRunTitle")!
    static let foundation = UIColor(named: "Foundation")!
    static let gradientBackground = UIColor(named: "GradientBackground")!
    static let gradientFirst = UIColor(named: "GradientFirst")!
    static let gradientSecond = UIColor(named: "GradientSecond")!
    static let gradientThird = UIColor(named: "GradientThird")!
    static let grey10 = UIColor(named: "Grey10")!
    static let grey30 = UIColor(named: "Grey30")!
    static let grey50 = UIColor(named: "Grey50")!
    static let grey70 = UIColor(named: "Grey70")!
    static let grey90 = UIColor(named: "Grey90")!
    static let ink90 = UIColor(named: "Ink90")!
    static let inputPlaceholder = UIColor(named: "InputPlaceholder")!
    static let launchScreenBackground = UIColor(named: "LaunchScreenBackground")!
    static let locationBar = UIColor(named: "LocationBar")!
    static let magenta40 = UIColor(named: "Magenta40")!
    static let magenta70 = UIColor(named: "Magenta70")!
    static let primaryDark = UIColor(named: "PrimaryDark")!
    static let primaryText = UIColor(named: "PrimaryText")!
    static let purple30 = UIColor(named: "Purple30")!
    static let purple50 = UIColor(named: "Purple50")!
    static let purple70 = UIColor(named: "Purple70")!
    static let purple80 = UIColor(named: "Purple80")!
    static let red60 = UIColor(named: "Red60")!
    static let scrim = UIColor(named: "Scrim")!
    static let searchGradientFirst = UIColor(named: "SearchGradientFirst")!
    static let searchGradientSecond = UIColor(named: "SearchGradientSecond")!
    static let searchGradientThird = UIColor(named: "SearchGradientThird")!
    static let searchGradientFourth = UIColor(named: "SearchGradientFourth")!
    static let secondaryText = UIColor(named: "SecondaryText")!
    static let secondaryButton = UIColor(named: "SecondaryButton")!
    static let primaryButton = UIColor(named: "PrimaryButton")!
    static let searchSuggestionButtonHighlight = UIColor(named: "SearchSuggestionButtonHighlight")!
    static let extensionNotEnabled = UIColor(named: "ExtensionNotEnabled")!
    static let actionButton = UIColor(named: "ActionButton")!

    /**
     * Initializes and returns a color object for the given RGB hex integer.
     */
    convenience init(rgb: Int, alpha: Float = 1) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8)  / 255.0,
            blue: CGFloat((rgb & 0x0000FF) >> 0)  / 255.0,
            alpha: CGFloat(alpha))
    }

}

public extension Color {
    static let accent = Color("Accent", bundle: .module)
}
