// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// An interface that defines the contract for loading summarizer configurations from various sources.
public protocol SummarizerConfigSourceProtocol: Sendable {
    func load(_ summarizer: SummarizerModel, contentType: SummarizationContentType) -> SummarizerConfig?
}
