// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// A default implementation of the SummarizerConfigSourceProtocol that provides hardcoded configurations.
/// This will mostly be used as a fallback when no other configuration is available.
public struct DefaultSummarizerConfigSource: SummarizerConfigSourceProtocol {
    public init() {}

    public func load(_ summarizer: SummarizerModel, contentType: SummarizationContentType) async -> SummarizerConfig? {
        return SummarizerConfig(
            instructions: "Inst 1",
            options: ["temperature": 0.1, "maxTokens": 1]
        )
    }
}
