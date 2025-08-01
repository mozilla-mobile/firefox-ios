// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// We need these compile time checks so the app can be built with pre‑iOS 26 SDKs.
/// Once our BR workflow switches to 26, we can remove them,
/// as the runtime @available checks will be enough.
#if canImport(FoundationModels)
import FoundationModels
import Foundation

/// Interface for a language model inference session for both streamed and non-streamed responses.
/// This used because we want to be able to replace the real `LanguageModelSession` with a mock during testing.
@available(iOS 26, *)
protocol LanguageModelSessionProtocol {
    func respond(
        to prompt: Prompt,
        options: GenerationOptions,
        isolation: isolated (any Actor)?
    ) async throws -> any LanguageModelResponseProtocol

    func streamResponse(
        to prompt: Prompt,
        options: GenerationOptions
    ) -> any LanguageModelResponseStreamProtocol
}

/// Convenience methods with defaults set
@available(iOS 26, *)
extension LanguageModelSessionProtocol {
    @discardableResult
    func respond(to prompt: Prompt) async throws -> any LanguageModelResponseProtocol {
        try await respond(to: prompt, options: .init(), isolation: #isolation)
    }

    func streamResponse(to prompt: Prompt) -> any LanguageModelResponseStreamProtocol {
        streamResponse(to: prompt, options: .init())
    }
}

#endif
