// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Fetches the `QuickAnswersConfig` used to drive a Quick Answers request.
public protocol QuickAnswersConfigFetcher: Sendable {
    func fetch() async throws -> QuickAnswersConfig
}

/// Default fetcher that builds a `QuickAnswersConfig` for the given model,
/// injecting the model-specific system prompt instructions.
public struct DefaultQuickAnswersConfigFetcher: QuickAnswersConfigFetcher {
    // TODO: FXIOS-15123 - Replace with the real Exa system prompt once it is finalized.
    private static let exaInstructions = """
    Answer in 1 sentence. Remove any superscript numbers from the response.
    """.replacingOccurrences(of: "\n", with: " ")

    private let model: QuickAnswersModel

    public init(model: QuickAnswersModel) {
        self.model = model
    }

    public func fetch() async throws -> QuickAnswersConfig {
        return QuickAnswersConfig(model: model, instructions: instructions(for: model))
    }

    private func instructions(for model: QuickAnswersModel) -> String {
        switch model {
        case .exa: return Self.exaInstructions
        case .liner: return ""
        }
    }
}
