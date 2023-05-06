// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct MarkupParsingUtility {
    public func parse(text: String) -> [MarkupNode] {
        var parser = MarkupParser(text: text)
        return parser.parse()
    }

    private var tokenizer: MarkupTokenizer
    private var openingDelimiters: [UnicodeScalar] = []

    private init(text: String) {
        tokenizer = MarkupTokenizer(string: text)
    }

    private mutating func parse() -> [MarkupNode] {
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

    private mutating func close(delimiter: UnicodeScalar, elements: [MarkupNode]) -> MarkupNode? {
        var newElements = elements

        // Convert orphaned opening delimiters to plain text
        while openingDelimiters.count > 0 {
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
