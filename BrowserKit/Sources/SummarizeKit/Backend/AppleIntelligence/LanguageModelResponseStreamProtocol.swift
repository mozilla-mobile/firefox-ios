// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import FoundationModels
import Foundation

/// A tiny abstraction over Apple's streaming snapshot type.
/// In production, `LanguageModelSession.ResponseStream<String>.Snapshot` conforms to this.
/// In tests, we define a `MockLanguageModelResponseSnapshot` that also conforms to this.
@available(iOS 26, *)
protocol LanguageModelResponseSnapshotProtocol {
    var content: String { get }
}

/// Defines the streaming interface for language model outputs.
/// This used because `LanguageModelSession.ResponseStream` lacks a public initializer.
/// The protocol exposes only the essential `AsyncSequence<String>` functionality, enabling
/// the test versions to use `AsyncThrowingStream`.
@available(iOS 26, *)
protocol LanguageModelResponseStreamProtocol: AsyncSequence
    where Element: LanguageModelResponseSnapshotProtocol {}

@available(iOS 26, *)
extension LanguageModelSession.ResponseStream: LanguageModelResponseStreamProtocol
    where Content == String {}

@available(iOS 26, *)
extension AsyncThrowingStream: LanguageModelResponseStreamProtocol
    where Element: LanguageModelResponseSnapshotProtocol {}

@available(iOS 26, *)
extension LanguageModelSession.ResponseStream<String>.Snapshot: LanguageModelResponseSnapshotProtocol {}
