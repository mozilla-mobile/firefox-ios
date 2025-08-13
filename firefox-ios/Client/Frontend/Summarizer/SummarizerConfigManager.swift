// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SummarizeKit

/// A wrapper to Manage the configuration sources for the summarizer. 
/// This class is responsible for loading and merging configurations from multiple sources.
/// We should never access the sources directly.
class SummarizerConfigManager {
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
        var mergedConfig = SummarizerConfig(instructions: "", options: [:])
        // Merge configs in reverse order (so higher priority overrides lower)
        for source in sources.reversed() {
            if let config = source.load(summarizer, contentType: contentType) {
                mergedConfig = config.merging(with: mergedConfig)
            }
        }
        return mergedConfig
    }
}
