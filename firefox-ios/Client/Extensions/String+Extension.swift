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

    /// Creates an attributed string with specified parts of the original string bolded.
    ///
    /// - Parameters:
    ///   - boldPartsOfString: An array of strings to be bolded within the original string.
    ///   - initialFont: The initial font to be used for the non-bold parts of the attributed string.
    ///   - boldFont: The font to be used for the bolded parts of the attributed string.
    /// - Returns: An `NSAttributedString` with the specified parts bolded.
    ///
    /// - Note: This method takes an array of strings (`boldPartsOfString`) and makes those parts
    ///         bold within the original string. It returns an attributed string with the specified
    ///         parts bolded, using the `boldFont` for those parts and the `initialFont` for the non-bold parts.
    ///
    /// - Example:
    ///   ```
    ///   let originalString = "This is an example."
    ///   let boldParts = ["example"]
    ///   let initialFont = UIFont.systemFont(ofSize: 16)
    ///   let boldFont = UIFont.boldSystemFont(ofSize: 16)
    ///   let attributedString = originalString.attributedText(boldPartsOfString: boldParts,
    ///                                                        initialFont: initialFont,
    ///                                                        boldFont: boldFont)
    ///   ```
    func attributedText(boldPartsOfString: [String],
                        initialFont: UIFont,
                        boldFont: UIFont) -> NSAttributedString {
        let nsString = self as NSString
        let boldString = NSMutableAttributedString(string: self,
                                                   attributes: [NSAttributedString.Key.font: initialFont])
        for i in 0 ..< boldPartsOfString.count {
            boldString.addAttributes([NSAttributedString.Key.font: boldFont],
                                     range: nsString.range(of: boldPartsOfString[i] as String))
        }
        return boldString
    }

    /// Creates an attributed string with a base style and highlights a specific part of the 
    /// string with a different style.
    ///
    /// - Parameters:
    ///   - style: The dictionary of attributes applied to the entire string. Defaults to `nil`.
    ///   - highlightedText: The substring to be highlighted with a different style.
    ///   - highlightedTextStyle: The dictionary of attributes applied specifically to the highlighted text. 
    ///   Defaults to `nil`.
    /// - Returns: An `NSAttributedString` with the specified parts styled differently.
    ///
    /// - Note: If the highlighted text does not exist in the original string, no highlighted style is applied.
    func attributedText(with style: [NSAttributedString.Key: Any]? = nil,
                        and highlightedText: String,
                        with highlightedTextStyle: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString {
        // Apply base style to the entire string
        let formattedString = NSMutableAttributedString(string: self, attributes: style)

        // Find the range of the highlighted text
        let highlightedTextRange = (self as NSString).range(of: highlightedText)

        // Check if the highlighted text exists in the string
        if highlightedTextRange.location != NSNotFound {
            // Apply the highlighted style to the specified range
            formattedString.addAttributes(highlightedTextStyle ?? [:], range: highlightedTextRange)
        }
        return formattedString
    }
}
