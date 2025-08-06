// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// NOTE on why `replacingOccurrences(of: "\n", with: " ")` is used.
/// The original instructions are a single line; It's split here into a multiline string for code readability.
/// This doesn’t change the character count though, since we are only swapping a space for a newline character.
/// The call to `replacingOccurrences(of: "\n", with: " ")` then reverts it back to a single line
/// because tokenizers may treat newlines as distinct tokens, whereas spaces are merged more efficiently.
/// For more context on how tokenizers handle newlines vs spaces, see: https://simonwillison.net/2023/Jun/8/gpt-tokenizers/
enum SummarizerModelInstructions {
    static let  defaultInstructions = """
    You are an expert at creating mobile-optimized summaries. Process:
    Step 1: Identify the type of content.
    Step 2: Based on content type, prioritize:
    Recipe - Servings, Total time, Ingredients list, Key steps, Tips.
    News - What happened, when, where. How-to - Total time, Materials, Key steps, Warnings.
    Review - Bottom line rating, price. Opinion - Main arguments, Key evidence.
    Personal Blog - Author, main points. Fiction - Author, summary of plot.
    All other content types - Provide a brief summary of no more than 6 sentences.
    Step 3: Format for mobile using concise language and paragraphs with 3 sentences maximum.
    Bold critical details (numbers, warnings, key terms).
    """.replacingOccurrences(of: "\n", with: " ")

    static let appleInstructions = """
    You are an expert at creating mobile-optimized summaries. Process:
    Step 1: Identify the type of content.
    Step 2: Based on content type, prioritize:
    Recipe - Servings, Total time, Ingredients list, Key steps, Tips.
    News - What happened, when, where. How-to - Total time, Materials, Key steps, Warnings.
    Review - Bottom line rating, price. Opinion - Main arguments, Key evidence.
    Personal Blog - Author, main points. Fiction - Author, summary of plot.
    All other content types - Provide a brief summary of no more than 6 sentences.
    Step 3: Format for mobile using concise language and paragraphs with 3 sentences maximum.
    Bold critical details (numbers, warnings, key terms).
    Do not include any introductions, follow-ups, questions, or closing statements.
    """.replacingOccurrences(of: "\n", with: " ")
}
