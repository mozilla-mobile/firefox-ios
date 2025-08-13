// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// A user-specific implementation of the SummarizerConfigSourceProtocol that retrieves configurations from user settings.
/// NOTE: This returns nil for now until we implement a UI in the settings menu for user to customize the summarization options.
public struct UserSummarizerConfigSource: SummarizerConfigSourceProtocol {
    public init() {}

    public func load(_ summarizer: SummarizerModel, contentType: SummarizationContentType) async -> SummarizerConfig? {
        return nil
    }
}
