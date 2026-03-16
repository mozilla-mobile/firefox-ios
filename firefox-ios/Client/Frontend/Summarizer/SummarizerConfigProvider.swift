// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SummarizeKit
import WebKit

protocol SummarizerConfigProvider {
    func getConfig(
        summarizerModel: SummarizerModel,
        contentType: SummarizationContentType,
        locale: Locale
    ) -> SummarizerConfig
}

struct DefaultSummarizerConfigProvider: SummarizerConfigProvider {
    private enum Constants {
        static let languageTag = "**{lang}**"
        static let enLocale = Locale(identifier: "en")
        static let englishLanguage = "English"
        static let defaultSources: [any SummarizerConfigSourceProtocol] = [
            UserSummarizerConfigSource(),
            RemoteSummarizerConfigSource(),
            DefaultSummarizerConfigSource(),
        ]
    }
    private let sources: [any SummarizerConfigSourceProtocol]

    init(sources: [any SummarizerConfigSourceProtocol] = Constants.defaultSources) {
        self.sources = sources
    }

    /// Returns the configuration for the Summarizer by merging the config loaded from the `sources`.
    /// First sources in the array have highest priority when the configuration are merged into one.
    func getConfig(
        summarizerModel: SummarizerModel,
        contentType: SummarizationContentType,
        locale: Locale
    ) -> SummarizerConfig {
        let initialConfig = SummarizerConfig(instructions: "", options: [:])
        // Merge configs in reverse order (so higher priority overrides lower)
        // $0.merging(with: $1) means "merge $0 into $1" so the result will prioritize $0's values.
        let config = sources
            .compactMap { $0.load(summarizerModel, contentType: contentType) }
            .reduce(initialConfig) { $0.merging(with: $1) }
        // inject the locale into the instructions, use English Locale to get the localized string for the provided locale
        // cause the LLM needs english localized content.
        let instructionsWithLocale = config.instructions
            .replacingOccurrences(
                of: Constants.languageTag,
                with: Constants.enLocale.localizedString(forIdentifier: locale.identifier) ?? Constants.englishLanguage
            )
        return SummarizerConfig(instructions: instructionsWithLocale, options: config.options)
    }
}
