// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Fetches the `QuickAnswersConfig` used to drive a Quick Answers request.
public protocol QuickAnswersConfigFetcher: Sendable {
    /// The provider model that backs the request, used to surface the model name in the UI.
    var model: QuickAnswersModel { get }
    func fetch() async throws -> QuickAnswersConfig
}

public struct DefaultQuickAnswersConfigFetcher: QuickAnswersConfigFetcher {
    // TODO: FXIOS-15123 - Replace with the real Exa system prompt once it is finalized.
    private static let exaInstructions = """
    Answer in 1 sentence. Remove any superscript numbers from the response.
    """.replacingOccurrences(of: "\n", with: " ")

    public let model: QuickAnswersModel

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
