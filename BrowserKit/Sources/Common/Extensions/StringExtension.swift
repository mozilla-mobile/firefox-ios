// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension StringProtocol {
    /// Returns a new string in which all occurrences of a target
    /// string within the receiver are removed.
    public func removingOccurrences<Target>(of target: Target) -> String where Target: StringProtocol {
        return replacingOccurrences(of: target, with: "")
    }
}

public extension String {
    /// Returns a new string made by removing the leading String characters contained
    /// in a given character set.
    func stringByTrimmingLeadingCharactersInSet(_ set: CharacterSet) -> String {
        var trimmed = self
        while trimmed.rangeOfCharacter(from: set)?.lowerBound == trimmed.startIndex {
            trimmed.remove(at: trimmed.startIndex)
        }
        return trimmed
    }

    /// Calculates the approximate number of words in the given string.
    ///
    /// This function splits the input string on whitespace and newline characters,
    /// filters out any empty segments (e.g., from multiple consecutive spaces or line breaks),
    /// and returns the count of the resulting non-empty components as an Int32.
    ///
    /// Note: This simple, whitespace-based approach is only an approximation;
    /// for example, "I'm" is counted as a single word. This is sufficient for our use cases
    /// (search suggestions and summarizer telemetry). If more linguistically accurate
    /// tokenization is ever required (e.g., handling punctuation and contractions),
    /// we can experiment with using NSLinguisticTagger or a regex-based tokenizer.
    var numberOfWords: Int32 {
        let words = components(separatedBy: CharacterSet.whitespacesAndNewlines)
        let filteredWords = words.filter { !$0.isEmpty }
        return Int32(clamping: filteredWords.count)
    }

    /// Encode HTMLStrings
    /// Also used for Strings which are not sanitized for displaying
    /// - Returns: Encoded String
    var htmlEntityEncodedString: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;", options: .literal)
            .replacingOccurrences(of: "\"", with: "&quot;", options: .literal)
            .replacingOccurrences(of: "'", with: "&#39;", options: .literal)
            .replacingOccurrences(of: "<", with: "&lt;", options: .literal)
            .replacingOccurrences(of: ">", with: "&gt;", options: .literal)
            .replacingOccurrences(of: "`", with: "&lsquo;", options: .literal)
    }
}
