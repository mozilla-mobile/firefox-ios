// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// A protocol defining the lifecycle events for a text summarization service.
public protocol SummarizerServiceLifecycle: AnyObject, Sendable {
    /// Called once before summarization starts.
    @MainActor
    func summarizerServiceDidStart(_ text: String)
    /// Called on success, with the summary text.
    @MainActor
    func summarizerServiceDidComplete(_ summary: String, modelName: SummarizerModel)
    /// Called on failure, with the error that occurred.
    @MainActor
    func summarizerServiceDidFail(_ error: SummarizerError, modelName: SummarizerModel)
}
