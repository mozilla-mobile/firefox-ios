// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SummarizeKit
import WebKit

// TODO: - FXIOS-15016 move SummarizerConfigProvider and default implementation to SummarizeKit
protocol SummarizerConfigProvider {
    /// Returns the configuration for the summarizer fetching it from the sources.
    func getConfig(
        from sources: [any SummarizerConfigSourceProtocol],
        summarizerModel: SummarizerModel,
        contentType: SummarizationContentType,
        locale: Locale?
    ) -> SummarizerConfig
}

struct DefaultSummarizerConfigProvider: SummarizerConfigProvider {
    /// Returns the configuration for the Summarizer by merging the config loaded from the `sources`.
    /// First sources have highest priority when the configuration are merged into one.
    func getConfig(
        from sources: [any SummarizerConfigSourceProtocol],
        summarizerModel: SummarizerModel,
        contentType: SummarizationContentType,
        locale: Locale?
    ) -> SummarizerConfig {
        let initialConfig = SummarizerConfig(instructions: "", options: [:])
        // Merge configs in reverse order (so higher priority overrides lower)
        // $0.merging(with: $1) means "merge $0 into $1" so the result will prioritize $0's values.
        let config = sources
            .compactMap { $0.load(summarizerModel, contentType: contentType) }
            .reduce(initialConfig) { $0.merging(with: $1) }
        if let locale {
            return config.injecting(locale: locale)
        }
        return config
    }
}
