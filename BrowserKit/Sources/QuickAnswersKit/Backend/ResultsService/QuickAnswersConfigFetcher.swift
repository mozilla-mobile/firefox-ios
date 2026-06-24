// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Fetches the `QuickAnswersConfig` used to drive a Quick Answers request.
protocol QuickAnswersConfigFetcher: Sendable {
    func fetch() async throws -> QuickAnswersConfig
}

/// Default fetcher that builds a `QuickAnswersConfig` for the given model,
/// injecting the model-specific system prompt instructions.
struct DefaultQuickAnswersConfigFetcher: QuickAnswersConfigFetcher {
    // TODO: FXIOS-15123 - Replace with the real Exa system prompt once it is finalized.
    private static let exaInstructions = """
    You are a helpful assistant that provides concise, accurate answers to user questions.
    """.replacingOccurrences(of: "\n", with: " ")

    private let model: QuickAnswersModel

    init(model: QuickAnswersModel) {
        self.model = model
    }

    func fetch() async throws -> QuickAnswersConfig {
        return QuickAnswersConfig(model: model, instructions: instructions(for: model))
    }

    private func instructions(for model: QuickAnswersModel) -> String {
        switch model {
        case .exa: return Self.exaInstructions
        case .liner: return ""
        }
    }
}
