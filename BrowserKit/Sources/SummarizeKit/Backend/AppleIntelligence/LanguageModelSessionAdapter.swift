// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// We need these compile time checks so the app can be built with pre‑iOS 26 SDKs.
/// Once our BR workflow switches to 26, we can remove them,
/// as the runtime @available checks will be enough.
#if canImport(FoundationModels)
import FoundationModels
import Foundation

/// Adapter bridging Apple's `LanguageModelSession` to `LanguageModelSessionProtocol`.
/// This is needed because `LanguageModelSession.respond()` returns a concrete type `LanguageModelSession.Response`
/// whereas `LanguageModelSessionProtocol.respond() returns `any ResponseProtocol`. 
/// Eventhough `LanguageModelSession.Response` conforms to `ResponseProtocol`, the compiler treats them as different types.
/// In tests, `MockLanguageModelSession` will be used instead of this.
@available(iOS 26, *)
final class LanguageModelSessionAdapter: LanguageModelSessionProtocol {
    private let realSession: LanguageModelSession

    init(instructions: String) {
        self.realSession = LanguageModelSession(instructions: instructions)
    }

    func respond(
        to prompt: Prompt,
        options: GenerationOptions,
        isolation: isolated (any Actor)?
    ) async throws -> any LanguageModelResponseProtocol {
        let realResponse: LanguageModelSession.Response<String> =
            try await realSession.respond(to: prompt, options: options)
        return realResponse
    }

    func streamResponse(
        to prompt: Prompt,
        options: GenerationOptions
    ) -> any LanguageModelResponseStreamProtocol {
        // TODO(FXIOS-13088): The API changed between beta 4 and 5, so this now breaks when building.
        // To avoid any future issues, this is commented out until we get the stable API.
        // This is unused in the current implementation. We only use non-streaming responses.
        // realSession.streamResponse(to: prompt, options: options)
        assertionFailure(
        """
        streaming is disabled until we get a stable API for
        `LanguageModelSession.ResponseStream`.
        """
        )
        return AsyncThrowingStream<String, Error> { $0.finish() }
    }
}

#endif
