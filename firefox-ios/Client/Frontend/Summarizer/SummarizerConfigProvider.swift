// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SummarizeKit
import WebKit

protocol SummarizerConfigProvider {
    func getConfig(
        from sources: [any SummarizerConfigSourceProtocol],
        summarizerModel: SummarizerModel,
        contentType: SummarizationContentType,
        locale: Locale?
    ) -> SummarizerConfig
}

extension SummarizerConfigProvider {
    /// The order of sources determines their priority.
    /// User overrides take precedence, followed by remote config, and then defaults.
    var defaultSources: [SummarizerConfigSourceProtocol] {
        return [
            UserSummarizerConfigSource(),
            RemoteSummarizerConfigSource(),
            DefaultSummarizerConfigSource()
        ]
    }

    func getConfig(
        summarizerModel: SummarizerModel,
        contentType: SummarizationContentType,
        locale: Locale?
    ) -> SummarizerConfig {
        return getConfig(
            from: defaultSources,
            summarizerModel: summarizerModel,
            contentType: contentType,
            locale: locale
        )
    }
}

/// A wrapper to Manage the configuration sources for the summarizer.
/// This class is responsible for loading and merging configurations from multiple sources.
/// We should never access the sources directly.
final class DefaultSummarizerConfigProvider: SummarizerConfigProvider {
    func getConfig(
        from sources: [any SummarizerConfigSourceProtocol],
        summarizerModel: SummarizeKit.SummarizerModel,
        contentType: SummarizeKit.SummarizationContentType,
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
