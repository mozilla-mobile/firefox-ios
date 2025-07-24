// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import FoundationModels

/// Defines the streaming interface for language model outputs.
/// This used because `LanguageModelSession.ResponseStream` lacks a public initializer.
/// The protocol exposes only the essential `AsyncSequence<String>` functionality, enabling
/// the test versions to use `AsyncThrowingStream`.
@available(iOS 26, *)
protocol LanguageModelResponseStreamProtocol: AsyncSequence where Element == String {}

@available(iOS 26, *)
extension LanguageModelSession.ResponseStream: LanguageModelResponseStreamProtocol
    where Content == String {}

extension AsyncThrowingStream: LanguageModelResponseStreamProtocol
    where Element == String {}
