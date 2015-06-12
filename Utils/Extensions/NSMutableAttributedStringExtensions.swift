/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension NSMutableAttributedString {
    public func colorSubstring(substring: String, withColor color: UIColor){
        let nsString = self.string as NSString
        let range = nsString.rangeOfString(substring)
        self.addAttribute(NSForegroundColorAttributeName, value: color, range: range)
    }
}
