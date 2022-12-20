// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension String {
    /// Handles logic to make part of string bold
    /// - Parameters:
    ///     - boldString: the portion of the string that should be bold. Current string must already include this string.
    ///     - font: font for entire string, part of string will be converted to bold version of this font
    func attributedText(boldString: String, font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self,
                                                         attributes: [NSAttributedString.Key.font: font])

        var boldFont = UIFont.boldSystemFont(ofSize: font.pointSize)

        // if we have a text style, we are using dynamic text so the attributed text should do too
        if let textStyle = font.fontDescriptor.fontAttributes[.textStyle] as? UIFont.TextStyle {
            boldFont = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: textStyle,
                                                                         size: font.pointSize)
        }

        let boldFontAttribute = [NSAttributedString.Key.font: boldFont]
        let range = (self as NSString).range(of: boldString)
        attributedString.addAttributes(boldFontAttribute, range: range)
        return attributedString
    }
}
