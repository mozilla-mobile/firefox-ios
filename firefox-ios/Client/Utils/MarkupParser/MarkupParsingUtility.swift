// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class MarkupParsingUtility {
    private var tokenizer: MarkupTokenizingUtility
    private var openingDelimiters: [UnicodeScalar] = []

    init() {
        tokenizer = MarkupTokenizingUtility(for: "")
    }

    public func parse(text: String) -> [MarkupNode] {
        tokenizer = MarkupTokenizingUtility(for: text)
        return parse()
    }

    private func parse() -> [MarkupNode] {
        var elements: [MarkupNode] = []

        while let token = tokenizer.nextToken() {
            switch token {
            case .text(let text):
                elements.append(.text(text))

            case .leftDelimiter(let delimiter):
                // Recursively parse all the tokens following the delimiter
                openingDelimiters.append(delimiter)
                elements.append(contentsOf: parse())

            case .rightDelimiter(let delimiter) where openingDelimiters.contains(delimiter):
                guard let containerNode = close(delimiter: delimiter, elements: elements) else {
                    fatalError("There is no MarkupNode for \(delimiter)")
                }
                return [containerNode]
            default:
                elements.append(.text(token.description))
            }
        }

        // Convert orphaned opening delimiters to plain text
        let textElements: [MarkupNode] = openingDelimiters.map { .text(String($0)) }
        elements.insert(contentsOf: textElements, at: 0)
        openingDelimiters.removeAll()

        return elements
    }

    private func close(
        delimiter: UnicodeScalar,
        elements: [MarkupNode]
    ) -> MarkupNode? {
        var newElements = elements

        // Convert orphaned opening delimiters to plain text
        while !openingDelimiters.isEmpty {
            let openingDelimiter = openingDelimiters.popLast()!

            if openingDelimiter == delimiter {
                break
            } else {
                newElements.insert(.text(String(openingDelimiter)), at: 0)
            }
        }

        return MarkupNode(delimiter: delimiter, children: newElements)
    }
}
