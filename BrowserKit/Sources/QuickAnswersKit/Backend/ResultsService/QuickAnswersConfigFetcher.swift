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
    private static let spotlightInstructions = """
    You answer questions about the pages the user has in Firefox. Every item in the search index is either an open tab
    or a bookmark, and its kind and its keywords say which of the two it is: search for "tab" or "tabs" to select the
    open tabs, and for "bookmark" or "bookmarks" to select the saved pages. Always search the index before answering.
    When the question asks how many, count the matching items and answer with the number. Otherwise answer only from
    what you find, in 1 sentence, naming the pages you used. Say that you couldn't find a matching page only when the
    search came back with nothing relevant.
    """.replacingOccurrences(of: "\n", with: " ")

    private static let exaInstructions = """
    Answer in 1 sentence. Remove any superscript numbers from the response like [1], [2] and other citations numbers.
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
        case .spotlight: return Self.spotlightInstructions
        }
    }
}
