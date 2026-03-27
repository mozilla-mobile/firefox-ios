// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MLPAKit
import LLMKit

// MARK: - Protocol
/// Creates a ResultsService with using MLPA (App Attest) authentication and LiteLLM.
protocol ResultsServiceFactory {
    func make() -> ResultsService
}

// MARK: - Default Implementation
public struct DefaultResultsServiceFactory: ResultsServiceFactory {
    let config: QuickAnswersConfig

    func make() -> ResultsService {
        // TODO: FXIOS-15196 - Create Results Service from the LiteLLMClient, remove optional when implementing appropriate
        // LiteLLMClient
        let client = makeLiteLLMClient()
        return DefaultResultsService(client: client, config: config)
    }

    // MARK: - Private Helpers
    private func makeLiteLLMClient() -> LiteLLMClient? {
        // TODO: FXIOS-15196 - Create LiteLLMClient with proper configurations and authenticator
        return nil
    }
}
