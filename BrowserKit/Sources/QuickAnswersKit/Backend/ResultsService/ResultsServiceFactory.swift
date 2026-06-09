// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MLPAKit
import LLMKit
import Shared

// MARK: - Protocol
/// Creates a ResultsService with using MLPA (App Attest) authentication and LiteLLM.
protocol ResultsServiceFactory {
    func make(prefs: Prefs, config: QuickAnswersConfig) throws -> ResultsService
}

// MARK: - Default Implementation
public struct DefaultResultsServiceFactory: ResultsServiceFactory {
    let liteLLMCreator: LiteLLMCreating

    public init(liteLLMCreator: LiteLLMCreating) {
        self.liteLLMCreator = liteLLMCreator
    }

    func make(
        prefs: Prefs,
        config: QuickAnswersConfig
    ) throws -> ResultsService {
        guard let model = config.options["model"] as? String, !model.isEmpty,
              let client = makeLiteLLMClient(prefs: prefs)
        else {
            throw ResultsServiceError.unableToCreateService
        }

        return DefaultResultsService(client: client, config: config)
    }

    // MARK: - Private Helpers
    private func makeLiteLLMClient(prefs: Prefs) -> LiteLLMClientProtocol? {
        return liteLLMCreator.createAppAttestLiteLLM(using: prefs, serviceType: .quickAnswers)
    }
}
