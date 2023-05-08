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
    /// delimiters to determine if there's a match.
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

    private func previousCharacter() -> UnicodeScalar? {
        guard currentIndex > input.startIndex else { return nil }

        let index = input.index(before: currentIndex)
        return input[index]
    }

    private func nextCharacter() -> UnicodeScalar? {
        guard currentIndex < input.endIndex else { return nil }

        let index = input.index(after: currentIndex)

        guard index < input.endIndex else { return nil }

        return input[index]
    }

    private mutating func scan(delimiter: UnicodeScalar) -> MarkupToken? {
        return scanRight(delimiter: delimiter) ?? scanLeft(delimiter: delimiter)
    }

    private mutating func scanLeft(delimiter: UnicodeScalar) -> MarkupToken? {
        let previous = previousCharacter() ?? .space

        guard let next = nextCharacter(),
              isValidLeftDelimiter(previous: previous, next: next, delimiter: delimiter)
        else { return nil }

        existingLeftDelimiters.append(delimiter)
        advanceCurrentIndex()

        return .leftDelimiter(delimiter)
    }

    /// Left delimiters must:
    /// - be predeced by whitespace or punctuation (or nothing, ie. start of
    ///   the string in which case, we treat that as whitespace)
    /// - NOT followed by whitespaces or newlines
    private func isValidLeftDelimiter(
        previous: UnicodeScalar,
        next: UnicodeScalar,
        delimiter: UnicodeScalar
    ) -> Bool {
        return CharacterSet.whitespaceAndPunctuation.contains(previous) &&
            !CharacterSet.whitespacesAndNewlines.contains(next) &&
            !existingLeftDelimiters.contains(delimiter)
    }

    private mutating func scanRight(delimiter: UnicodeScalar) -> MarkupToken? {
        let next = nextCharacter() ?? .space
        guard let previous = previousCharacter(),
              isValidRightDelimiter(previous: previous, next: next, delimiter: delimiter)
        else { return nil }

        // Check if there's a matching left delimiter, and if there is, remove it
        while !existingLeftDelimiters.isEmpty {
            if existingLeftDelimiters.popLast() == delimiter { break }
        }
        advanceCurrentIndex()

        return .rightDelimiter(delimiter)
    }

    /// Right delimiters must:
    /// - NOT be preceded by whitespace
    /// - followed by whitespace or punctuation (or nothing, ie. end
    ///   of the string in which case, we treat that as whitespace)
    private func isValidRightDelimiter(
        previous: UnicodeScalar,
        next: UnicodeScalar,
        delimiter: UnicodeScalar
    ) -> Bool {
        return !CharacterSet.whitespacesAndNewlines.contains(previous) &&
            CharacterSet.whitespaceAndPunctuation.contains(next) &&
            existingLeftDelimiters.contains(delimiter)
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
