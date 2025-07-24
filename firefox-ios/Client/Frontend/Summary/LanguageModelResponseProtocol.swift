// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import FoundationModels

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
