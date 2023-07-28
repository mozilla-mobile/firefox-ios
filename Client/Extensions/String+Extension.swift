// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

extension String {
    /// Returns an attributed string in which the first occurrence of the given
    /// substring is bold.
    /// - Parameters:
    ///     - boldString: the substring that should be bold
    ///     - font: font for entire string, part of string will be converted to bold version of this font
    func attributedText(boldString: String, font: UIFont) -> NSAttributedString {
        guard let range = self.range(of: boldString) else {
            return NSAttributedString(string: self)
        }
        return self.attributedText(boldIn: range, font: font)
    }

    /// Returns an attributed string in which the characters in the given range
    /// are bold.
    /// - Parameters:
    ///     - boldIn: the character range in the string that should be bold
    ///     - font: font for entire string, part of string will be converted to bold version of this font
    func attributedText(boldIn range: Range<String.Index>, font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self,
                                                         attributes: [NSAttributedString.Key.font: font])

        var boldFont = UIFont.boldSystemFont(ofSize: font.pointSize)

        // if we have a text style, we are using dynamic text so the attributed text should do too
        if let textStyle = font.fontDescriptor.fontAttributes[.textStyle] as? UIFont.TextStyle {
            boldFont = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: textStyle,
                                                                  size: font.pointSize)
        }

        let boldFontAttribute = [NSAttributedString.Key.font: boldFont]
        attributedString.addAttributes(boldFontAttribute, range: NSRange(range, in: self))
        return attributedString
    }
}
