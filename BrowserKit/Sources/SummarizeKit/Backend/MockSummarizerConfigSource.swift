// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

public final class MockSummarizerConfigSource: SummarizerConfigSourceProtocol {
    var configToReturn: SummarizerConfig

    init(configToReturn: SummarizerConfig) {
        self.configToReturn = configToReturn
    }

    public func load(_ summarizer: SummarizerModel, contentType: SummarizationContentType) async -> SummarizerConfig? {
        return configToReturn
    }
}
