// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

protocol TranscriptionEngine: Sendable {
    /// Prepares the engine by validating permissions and configuring the audio session.
    func prepare() async throws

    /// Starts speech recognition and streams results via the provided continuation.
    func start(continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation) async throws

    /// Stops speech recognition and releases audio resources.
    func stop() async throws
}
