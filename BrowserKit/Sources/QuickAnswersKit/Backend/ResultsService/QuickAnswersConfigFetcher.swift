// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Fetches the `QuickAnswersConfig` used to drive a Quick Answers request.
public protocol QuickAnswersConfigFetcher: Sendable {
    /// The feature configuration that backs the request.
    var feature: QuickAnswersFeature { get }
    func fetch() async throws -> QuickAnswersConfig
}

public struct DefaultQuickAnswersConfigFetcher: QuickAnswersConfigFetcher {
    private static let exaInstructions = """
    Answer in 1 sentence. Remove any superscript numbers from the response like [1], [2] and other citations numbers.
    """.replacingOccurrences(of: "\n", with: " ")

    public let feature: QuickAnswersFeature

    public init(feature: QuickAnswersFeature) {
        self.feature = feature
    }

    public func fetch() async throws -> QuickAnswersConfig {
        return QuickAnswersConfig(model: feature.model, instructions: instructions(for: feature.model))
    }

    private func instructions(for model: QuickAnswersModel) -> String {
        switch model {
        case .exa: return Self.exaInstructions
        case .liner: return ""
        }
    }
}
