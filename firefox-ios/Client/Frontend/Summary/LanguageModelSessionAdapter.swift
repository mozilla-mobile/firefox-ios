// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import FoundationModels

/// Adapter bridging Apple's `LanguageModelSession` to `LanguageModelSessionProtocol`.
/// This is needed because `LanguageModelSession.respond()` returns a concrete type `LanguageModelSession.Response`
/// whereas `LanguageModelSessionProtocol.respond() returns `any ResponseProtocol`. 
/// Eventhough `LanguageModelSession.Response` conforms to `ResponseProtocol`, the compiler treats them as different types.
/// In tests, this will use `MockLanguageModelSession` instead.
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
            try await realSession.respond(to: prompt, options: options, isolation: isolation)
        return realResponse
    }

    func streamResponse(
        to prompt: Prompt,
        options: GenerationOptions
    ) -> any LanguageModelResponseStreamProtocol {
        realSession.streamResponse(to: prompt, options: options)
    }
}
