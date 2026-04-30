// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import LLMKit
import Shared

@testable import QuickAnswersKit

final class MockLLMClientCreator: LiteLLMCreating {
    var clientToReturn: LiteLLMClientProtocol?
    var shouldReturnNil = false
    var createAppAttestLiteLLMCallCount = 0

    func createAppAttestLiteLLM(using prefs: Prefs) -> LiteLLMClientProtocol? {
        createAppAttestLiteLLMCallCount += 1
        return shouldReturnNil ? nil : clientToReturn
    }
}
