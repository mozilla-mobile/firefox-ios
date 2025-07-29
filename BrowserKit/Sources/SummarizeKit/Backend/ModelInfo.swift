// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// A dummy SummarizerService stub to unblock UI development.
/// TODO(FXIOS-12964): Final SummarizerService class will be merged in this ticket and this will be removed.
/// This is mainly done to ublock the UI work.
/// A dummy SummarizerService stub to unblock UI development.
final class SummarizerService {
    /// Returns a dummy summary string.
    func summarize(from webView: WKWebView) async throws -> String {
        return "This is a dummy summary."
    }

    /// Streams a dummy summary in chunks.
    func summarizeStreamed(from webView: WKWebView) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield("This is ")
            continuation.yield("a dummy ")
            continuation.yield("streamed summary.")
            continuation.finish()
        }
    }
}

/// Enum for available models. This is mainly added so that the UI layer knows which model it's using
/// and if need be present different UI depeding on the model ( e.g. ToS modals, ... )
enum AvailableModels {
    case appleModel, hostedModel
}

/// Main entry point for the UI layer. This is where all the integration should ideally happen.
/// TODO(FXIOS-12964): Once the final SummarizerService is merged. This will also be responsible for creating the summarizers
struct ModelInfo {
    let model: AvailableModels
    let service: SummarizerService

    /// Returns a configured ModelInfo based on feature flags.
    /// - Parameters:
    ///   - useAppleModel: Feature flag to determine if the apple model should be used.
    ///   - useHostedModel: Feature flag to determine if the hosted model should be used.
    /// - Returns: A ModelInfo for the first enabled flag, or nil if none.
    static func getEnabledModel(useAppleModel: Bool, useHostedModel: Bool) -> ModelInfo? {
        switch (useAppleModel, useHostedModel) {
        case (true, _):
            return ModelInfo(model: .appleModel, service: SummarizerService())
        case (_, true):
            return ModelInfo(model: .hostedModel, service: SummarizerService())
        default:
            return nil
        }
    }

    /// Private initializer to enforce factory use
    private init(model: AvailableModels, service: SummarizerService) {
        self.model = model
        self.service = service
    }
}
