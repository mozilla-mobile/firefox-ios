// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SummarizeKit

/// A wrapper to Manage the configuration sources for the summarizer. 
/// This class is responsible for loading and merging configurations from multiple sources.
/// We should never access the sources directly.
final class SummarizerConfigManager {
    /// The order of sources determines their priority.
    /// User overrides take precedence, followed by remote config, and then defaults.
    static let defaultSources: [SummarizerConfigSourceProtocol] = [
        UserSummarizerConfigSource(),
        RemoteSummarizerConfigSource(),
        DefaultSummarizerConfigSource()
    ]

    private let sources: [SummarizerConfigSourceProtocol]

    init(sources: [SummarizerConfigSourceProtocol] = SummarizerConfigManager.defaultSources) {
        self.sources = sources
    }

    func getConfig(_ summarizer: SummarizerModel, contentType: SummarizationContentType) -> SummarizerConfig {
        let initialConfig = SummarizerConfig(instructions: "", options: [:])
        // Merge configs in reverse order (so higher priority overrides lower)
        // $0.merging(with: $1) means "merge $0 into $1" so the result will prioritize $0's values.
        return sources
            .compactMap { $0.load(summarizer, contentType: contentType) }
            .reduce(initialConfig) { $0.merging(with: $1) }
    }
}
