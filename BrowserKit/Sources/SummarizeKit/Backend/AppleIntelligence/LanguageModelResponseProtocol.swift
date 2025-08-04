// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// We need these compile time checks so the app can be built with pre‑iOS 26 SDKs.
/// Once our BR workflow switches to 26, we can remove them,
/// as the runtime @available checks will be enough.
#if canImport(FoundationModels)
import FoundationModels
import Foundation

/// Defines the response interface for language model outputs.
/// This used because `LanguageModelSession.Response` lacks a public initializer.
/// The protocol exposes `content` and `transcriptEntries` for mocking and testing.
@available(iOS 26, *)
protocol LanguageModelResponseProtocol {
    var content: String { get }
    var transcriptEntries: ArraySlice<Transcript.Entry> { get }
}

@available(iOS 26, *)
extension LanguageModelSession.Response: LanguageModelResponseProtocol
    where Content == String {}

#endif
