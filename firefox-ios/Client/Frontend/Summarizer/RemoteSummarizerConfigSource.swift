// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SummarizeKit
/// An implementation of the SummarizerConfigSourceProtocol that retrieves configurations from remote settings.
/// NOTE: This file should be under SummarizeKit near the other source implementations.
/// Since all of RS classes are in Client, we can't move it there yet.
/// TODO(FXIOS-13186): Move all the needed RS typedefs to BrowserKit so we can move this file to SummarizeKit.
struct RemoteSummarizerConfigSource: SummarizerConfigSourceProtocol {
    func load(_ summarizer: SummarizerModel, contentType: SummarizationContentType) -> SummarizerConfig? {
        return ASSummarizerRemoteConfig()?.fetchSummarizerConfig(summarizer, for: contentType)
    }
}
