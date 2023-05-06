// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class MarkupAttributeUtility {
    private let baseFont: UIFont

    init(baseFont: UIFont) {
        self.baseFont = baseFont
    }

    func addAttributesTo(text: String) -> NSAttributedString {
        let elements = MarkupParsingUtility().parse(text: text)
        let attributes = [NSAttributedString.Key.font: baseFont]

        return elements.map { render(node: $0, withAttributes: attributes) }.joined()
    }

    /// Will
    private func render(
        node: MarkupNode,
        withAttributes attributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        guard let currentFont = attributes[NSAttributedString.Key.font] as? UIFont else {
            fatalError("Missing font attribute in \(attributes)")
        }

        switch node {
        case .text(let text):
            return NSAttributedString(string: text, attributes: attributes)

        case .bold(let elements):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.font] = currentFont.bolded()
            return elements.map { render(node: $0, withAttributes: newAttributes) }.joined()

        case .italics(let elements):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.font] = currentFont.italicized()
            return elements.map { render(node: $0, withAttributes: newAttributes) }.joined()
        }
    }
}
