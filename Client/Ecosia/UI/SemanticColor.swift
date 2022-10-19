/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UIColor {
    struct Light {
        struct Background {
            static let primary = UIColor.white
            static let secondary = UIColor(red: 0.973, green: 0.973, blue: 0.965, alpha: 1)
            static let tertiary = UIColor(red: 0.941, green: 0.941, blue: 0.922, alpha: 1)
            static let quarternary = UIColor(red: 0.153, green: 0.322, blue: 0.263, alpha: 1)
            static let highlighted = UIColor(rgb: 0xCFF2D0)
        }
        
        struct Button {
            static let primary = UIColor(red: 0, green: 0.5, blue: 0.033, alpha: 1)
            static let primaryActive = UIColor(rgb: 0x006600)
            static let secondary = UIColor.white
            static let secondaryActive = UIColor(rgb: 0xF8F8F6)
        }
        
        struct Text {
            static let primary = UIColor(red: 0.059, green: 0.059, blue: 0.059, alpha: 1)
            static let secondary = UIColor(red: 0.424, green: 0.424, blue: 0.424, alpha: 1)
        }

        struct State {
            static let warning = UIColor(red: 0.992, green: 0.259, blue: 0.337, alpha: 1)
            static let information = UIColor(red: 0, green: 0.494, blue: 0.659, alpha: 1)
            static let disabled = UIColor(rgb: 0xDEDED9)
        }
        
        struct Icon {
            static let primary = UIColor(red: 0.059, green: 0.059, blue: 0.059, alpha: 1)
            static let decorative = UIColor(red: 0.424, green: 0.424, blue: 0.424, alpha: 1)
        }
        
        struct Brand {
            static let primary = UIColor(red: 0, green: 0.5, blue: 0.033, alpha: 1)
        }
        
        static let border = UIColor(rgb: 0xDEDED9)
    }
    
    struct Dark {
        struct Background {
            static let primary = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            static let secondary = UIColor(rgb: 0x252525)
            static let tertiary = UIColor(rgb: 0x333333)
            static let quarternary = UIColor(rgb: 0xAFE9B0)
            static let highlighted = UIColor(rgb: 0x577568)
        }
        
        struct Button {
            static let primary = UIColor(red: 0.365, green: 0.824, blue: 0.369, alpha: 1)
            static let primaryActive = UIColor(rgb: 0x008009)
            static let secondary = UIColor(rgb: 0x333333)
        }
        
        struct Text {
            static let primary = UIColor.white
            static let secondary = UIColor(red: 0.871, green: 0.871, blue: 0.851, alpha: 1)
        }

        struct State {
            static let warning = UIColor(red: 1.0, green: 0.541, blue: 0.549, alpha: 1)
            static let information = UIColor(red: 0.589, green: 0.839, blue: 0.973, alpha: 1)
            static let disabled = UIColor(rgb: 0x6C6C6C)
        }
        
        struct Brand {
            static let primary = UIColor(red: 0.365, green: 0.824, blue: 0.369, alpha: 1)
        }
        
        struct Icon {
            static let primary = UIColor.white
            static let decorative = UIColor(red: 0.871, green: 0.871, blue: 0.871, alpha: 1)
        }
        
        static let border = UIColor(rgb: 0x4C4C4C)
    }

    struct Grey {
        static let fifty = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
    }
}
