/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation

struct Theme {
    var URLFontColor: UIColor?
    var hostFontColor: UIColor?
    var backgroundColor: UIColor?
    var textColor: UIColor?
    var highlightColor: UIColor?
    var tintColor: UIColor?
    var buttonTintColor: UIColor?
    var activeBorderColor: UIColor?
    var borderColor: UIColor?
    var borderWidth: CGFloat?
    var font: UIFont?
    var insets: UIEdgeInsets?
    var highlightButtonColor: UIColor?
    var highlightBorderColor: UIColor?
    var highlightTextColor: UIColor?

    static let PrivateMode = "Private"
    static let NormalMode = "Normal"
}