/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension NSMutableAttributedString {
    public func colorSubstring(substring: String, withColor color: UIColor){
        self.attributeSubstring(substring, forAttribute: NSForegroundColorAttributeName, withValue: color)
    }

    public func pitchSubstring(substring: String, withPitch pitch: Double){
        let pitchValue = NSNumber(double: pitch)
        self.attributeSubstring(substring, forAttribute: UIAccessibilitySpeechAttributePitch, withValue: pitchValue)
    }

    private func attributeSubstring(substring: String, forAttribute attribute: String, withValue value: AnyObject) {
        let nsString = self.string as NSString
        let range = nsString.rangeOfString(substring)
        self.addAttribute(attribute, value: value, range: range)
    }
}
