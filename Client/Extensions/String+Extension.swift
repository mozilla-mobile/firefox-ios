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

    /// Returns an attributed string in which the first occurrence of the given
    /// substrings is bold.
    /// - Parameters:
    ///     - boldStrings: the substrings that should be bold
    ///     - font: font for entire string, part of string will be converted to bold version of this font
    func attributedText(boldStrings: [String], font: UIFont) -> NSAttributedString {
        let wordRanges = boldStrings.compactMap { self.range(of: $0) }
        guard !wordRanges.isEmpty else {
            return NSAttributedString(string: self)
        }
        return self.attributedText(boldInRanges: wordRanges, font: font)
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

    /// Returns an attributed string in which the characters in the given ranges
    /// are bold.
    /// - Parameters:
    ///     - boldInRanges: an array of character ranges in the string that should be bold
    ///     - font: font for entire string, parts of the string will be converted to the bold version of this font
    func attributedText(boldInRanges ranges: [Range<String.Index>], font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self,
                                                         attributes: [NSAttributedString.Key.font: font])

        var boldFont = UIFont.boldSystemFont(ofSize: font.pointSize)

        // if we have a text style, we are using dynamic text so the attributed text should do too
        if let textStyle = font.fontDescriptor.fontAttributes[.textStyle] as? UIFont.TextStyle {
            boldFont = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: textStyle,
                                                                  size: font.pointSize)
        }

        let boldFontAttribute = [NSAttributedString.Key.font: boldFont]

        for range in ranges {
            attributedString.addAttributes(boldFontAttribute, range: NSRange(range, in: self))
        }

        return attributedString
    }
}
