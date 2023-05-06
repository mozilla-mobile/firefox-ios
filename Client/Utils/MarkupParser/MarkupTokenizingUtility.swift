// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Allows the definiton of a custom set of delimiters for parsing text
private extension CharacterSet {
    static let delimiters = CharacterSet(charactersIn: "*_")
    static let whitespaceAndPunctuation = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet.punctuationCharacters)
        .union(CharacterSet(charactersIn: "~"))
}

private extension UnicodeScalar {
    static let space: UnicodeScalar = " "
}

/// Allows a string to be broken into different markup tokens in order to allow
/// for a string's text to be attributed in different ways.
///
/// ```
/// var tokenizer = MarkupTokenizer(for: "Turnip _says *hello*_")
/// while let token = tokenizer.nextToken() {
///     switch token {
///     case let .text(value): print("text: \(value)"
///     case let .leftDelimiter(value): print("left delimiter: \(value)"
///     case let .rightDelimiter(value): print("right delimiter: \(value)"
///     }
/// }
/// ```
struct MarkupTokenizingUtility {
    // MARK: - Properties
    /// The input string provided
    private let input: String.UnicodeScalarView

    /// The index of the current character during tokenizer's iteration
    private var currentIndex: String.UnicodeScalarView.Index

    /// An array of existing left delimiters.
    ///
    /// Instead of scanning forwards, we can improve perfomance by keeping track
    /// of existing left delimiters and then lookback when we meet right
    /// delimiters to determin if there's a match.
    private var existingLeftDelimiters: [UnicodeScalar] = []

    // MARK: - Public interface
    init(for string: String) {
        input = string.unicodeScalars
        currentIndex = string.unicodeScalars.startIndex
    }

    mutating func nextToken() -> MarkupToken? {
        guard let character = currentCharacter() else { return nil }

        var token: MarkupToken?

        if CharacterSet.delimiters.contains(character) {
            token = scan(delimiter: character)
        } else {
            token = scanText()
        }

        if token == nil {
            token = .text(String(character))
            advanceCurrentIndex()
        }

        return token
    }

    // MARK: - Private methods
    private func currentCharacter() -> UnicodeScalar? {
        guard currentIndex < input.endIndex else { return nil }

        return input[currentIndex]
    }

    /// If this is the first character in the string, this will return a `.space`
    /// so that tokenization may funciton correctly.
    private func previousCharacter() -> UnicodeScalar? {
        guard currentIndex > input.startIndex else { return nil }

        if currentIndex == input.startIndex { return .space }
        return input[input.index(before: currentIndex)]
    }

    /// If this is the last character in the string, this will return a `.space`
    /// so that tokenization may function correctly.
    private func nextCharacter() -> UnicodeScalar? {
        guard currentIndex < input.endIndex else { return nil }

        let index = input.index(after: currentIndex)
        if index == input.endIndex { return .space }

        guard index < input.endIndex else { return nil }

        return input[index]
    }

    private mutating func scan(delimiter: UnicodeScalar) -> MarkupToken? {
        return scanRight(delimiter: delimiter) ?? scanLeft(delimiter: delimiter)
    }

    private mutating func scanLeft(delimiter: UnicodeScalar) -> MarkupToken? {

        guard let previous = previousCharacter(),
              let next = nextCharacter()
        else { return nil }

        // Left delimiters must:
        // - be predeced by whitespace or punctuation
        // - NOT followed by whitespaces or newlines
        guard CharacterSet.whitespaceAndPunctuation.contains(previous) &&
            !CharacterSet.whitespacesAndNewlines.contains(next) &&
            !existingLeftDelimiters.contains(delimiter)
        else { return nil }

        existingLeftDelimiters.append(delimiter)
        advanceCurrentIndex()

        return .leftDelimiter(delimiter)
    }

    private mutating func scanRight(delimiter: UnicodeScalar) -> MarkupToken? {
        guard let previous = previousCharacter(),
              let next = nextCharacter()
        else { return nil }

        // Right delimiters must:
        // - NOT be preceded by whitespace
        // - followed by whitespace or punctuation
        guard !CharacterSet.whitespacesAndNewlines.contains(previous) &&
            CharacterSet.whitespaceAndPunctuation.contains(next) &&
            existingLeftDelimiters.contains(delimiter)
        else { return nil }

        // Check if there's a matching left delimiter, and if there is, remove it
        while !existingLeftDelimiters.isEmpty {
            if existingLeftDelimiters.popLast() == delimiter { break }
        }
        advanceCurrentIndex()

        return .rightDelimiter(delimiter)
    }

    private mutating func scanText() -> MarkupToken? {
        let startIndex = currentIndex
        scanUntil { CharacterSet.delimiters.contains($0) }

        guard currentIndex > startIndex else { return nil }

        return .text(String(input[startIndex ..< currentIndex]))
    }

    private mutating func scanUntil(_ predicate: (UnicodeScalar) -> Bool) {
        while currentIndex < input.endIndex && !predicate(input[currentIndex]) {
            advanceCurrentIndex()
        }
    }

    private mutating func advanceCurrentIndex() {
        currentIndex = input.index(after: currentIndex)
    }
}
