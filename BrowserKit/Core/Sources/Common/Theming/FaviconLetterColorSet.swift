// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol FaviconLetterColorSet {
    var iconAccentGreen1: UIColor { get }
    var iconAccentGreen2: UIColor { get }
    var iconAccentGreen3: UIColor { get }
    var iconAccentGreen4: UIColor { get }
    var iconAccentGreen5: UIColor { get }
    var iconAccentGreen6: UIColor { get }
    var iconAccentGreen7: UIColor { get }

    var iconAccentRed1: UIColor { get }
    var iconAccentRed2: UIColor { get }
    var iconAccentRed3: UIColor { get }
    var iconAccentRed4: UIColor { get }
    var iconAccentRed5: UIColor { get }
    var iconAccentRed6: UIColor { get }
    var iconAccentRed7: UIColor { get }

    var iconAccentBlue1: UIColor { get }
    var iconAccentBlue2: UIColor { get }
    var iconAccentBlue3: UIColor { get }
    var iconAccentBlue4: UIColor { get }
    var iconAccentBlue5: UIColor { get }
    var iconAccentBlue6: UIColor { get }
    var iconAccentBlue7: UIColor { get }

    var iconAccentCyan1: UIColor { get }
    var iconAccentCyan2: UIColor { get }
    var iconAccentCyan3: UIColor { get }
    var iconAccentCyan4: UIColor { get }
    var iconAccentCyan5: UIColor { get }
    var iconAccentCyan6: UIColor { get }
    var iconAccentCyan7: UIColor { get }

    var iconAccentOrange1: UIColor { get }
    var iconAccentOrange2: UIColor { get }
    var iconAccentOrange3: UIColor { get }
    var iconAccentOrange4: UIColor { get }
    var iconAccentOrange5: UIColor { get }
    var iconAccentOrange6: UIColor { get }
    var iconAccentOrange7: UIColor { get }

    var iconAccentPink1: UIColor { get }
    var iconAccentPink2: UIColor { get }
    var iconAccentPink3: UIColor { get }
    var iconAccentPink4: UIColor { get }
    var iconAccentPink5: UIColor { get }
    var iconAccentPink6: UIColor { get }
    var iconAccentPink7: UIColor { get }

    var iconAccentYellow1: UIColor { get }
    var iconAccentYellow2: UIColor { get }
    var iconAccentYellow3: UIColor { get }
    var iconAccentYellow4: UIColor { get }
    var iconAccentYellow5: UIColor { get }
    var iconAccentYellow6: UIColor { get }
    var iconAccentYellow7: UIColor { get }

    /// The ordered background colours a letter favicon is hashed into
    var backgroundColors: [UIColor] { get }
    /// The letter colour matching each background colour, by index
    var letterColors: [UIColor] { get }
}
