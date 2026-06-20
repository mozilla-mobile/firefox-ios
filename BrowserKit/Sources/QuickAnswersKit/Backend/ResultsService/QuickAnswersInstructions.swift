// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// System prompt instructions injected into Quick Answers requests for models that support them.
public enum QuickAnswersInstructions {
    // TODO: FXIOS-15123 - Replace with the real Exa system prompt once it is finalized.
    static let exaInstructions = """
    You are a helpful assistant that provides concise, accurate answers to user questions.
    """.replacingOccurrences(of: "\n", with: " ")
}
