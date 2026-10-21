// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import QuickAnswersKit

/// A `QuickAnswersConfigFetcher` implementation that loads the model prompt from Remote Settings,
/// falling back to `defaultFetcher` when Remote Settings has no instructions for the model.
struct RemoteQuickAnswersConfigFetcher: QuickAnswersConfigFetcher {
    let feature: QuickAnswersKit.QuickAnswersFeature
    private let remoteConfig: ASAIRemoteConfig
    private let defaultFetcher: QuickAnswersConfigFetcher

    init(feature: QuickAnswersKit.QuickAnswersFeature,
         remoteConfig: ASAIRemoteConfig = ASAIRemoteConfig(),
         defaultFetcher: QuickAnswersConfigFetcher? = nil) {
        self.feature = feature
        self.remoteConfig = remoteConfig
        self.defaultFetcher = defaultFetcher ?? DefaultQuickAnswersConfigFetcher(feature: feature)
    }

    func fetch() async throws -> QuickAnswersConfig {
        guard let instructions = remoteConfig.fetchQuickAnswersInstruction(feature.model) else {
            return try await defaultFetcher.fetch()
        }
        return QuickAnswersConfig(model: feature.model, instructions: instructions)
    }
}
