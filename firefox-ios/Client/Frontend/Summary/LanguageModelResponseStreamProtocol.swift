// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// We need these compile time checks so the app can be built with pre‑iOS 26 SDKs.
/// Once our BR workflow switches to 26, we can remove them,
/// as the runtime @available checks will be enough.
#if canImport(FoundationModels)
import FoundationModels
import Foundation

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

#endif
