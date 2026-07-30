// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import QuickAnswersKit

/// A `QuickAnswersConfigFetcher` implementation that loads the model prompt from Remote Settings,
/// falling back to `defaultFetcher` when Remote Settings has no instructions for the model.
struct RemoteQuickAnswersConfigFetcher: QuickAnswersConfigFetcher {
    let model: QuickAnswersKit.QuickAnswersModel
    private let remoteConfig: ASAIRemoteConfig
    private let defaultFetcher: QuickAnswersConfigFetcher

    init(model: QuickAnswersKit.QuickAnswersModel,
         remoteConfig: ASAIRemoteConfig = ASAIRemoteConfig(),
         defaultFetcher: QuickAnswersConfigFetcher? = nil) {
        self.model = model
        self.remoteConfig = remoteConfig
        self.defaultFetcher = defaultFetcher ?? DefaultQuickAnswersConfigFetcher(model: model)
    }

    func fetch() async throws -> QuickAnswersConfig {
        guard let instructions = remoteConfig.fetchQuickAnswersInstruction(model) else {
            return try await defaultFetcher.fetch()
        }
        return QuickAnswersConfig(model: model, instructions: instructions)
    }
}
