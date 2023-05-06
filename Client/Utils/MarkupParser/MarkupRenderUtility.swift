// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class MarkupAttributeUtility {
    private let baseFont: UIFont

    init(baseFont: UIFont) {
        self.baseFont = baseFont
    }

    func render(text: String) -> NSAttributedString {
        let elements = MarkupParsingUtility().parse(text: text)
        let attributes = [NSAttributedString.Key.font: baseFont]

        return elements.map { render(withAttributes: attributes) }.joined()
    }

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
            return elements.map { $0.render(withAttributes: newAttributes) }.joined()

        case .italics(let elements):
            var newAttributes = attributes
            newAttributes[NSAttributedString.Key.font] = currentFont.italicized()
            return elements.map { $0.render(withAttributes: newAttributes) }.joined()
        }
    }
}

private extension Array where Element: NSAttributedString {
    func joined() -> NSAttributedString {
        return self.reduce(NSMutableAttributedString()) { result, element in
            result.append(element)
            return result
        }
    }
}

private extension UIFont {
    func bolded() -> UIFont? {
        return add(trait: .traitBold)
    }

    func italicized() -> UIFont? {
        return add(trait: .traitItalic)
    }

    func add(trait: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        guard let descriptor = fontDescriptor
            .withSymbolicTraits(fontDescriptor.symbolicTraits.union(traits))
        else { return nil }

        return UIFont(descriptor: descriptor, size: 0)
    }
}
