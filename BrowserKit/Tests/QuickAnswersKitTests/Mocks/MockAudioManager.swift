// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import AVFoundation
@testable import QuickAnswersKit

enum MockAudioManagerError: Error {
    case configureAudioSession
    case prepareAndStart
    case startCapture
}

final class MockAudioManager: AudioManagerProtocol {
    private(set) var configureAudioSessionCallCount = 0
    private(set) var prepareAndStartEngineCallCount = 0
    private(set) var stopEngineCallCount = 0
    private(set) var startCaptureSimpleCallCount = 0
    private(set) var startCaptureWithFormatCallCount = 0

    var shouldThrowOnConfigure = false
    var shouldThrowOnStart = false
    var shouldThrowOnCapture = false

    func configureAudioSession() throws {
        configureAudioSessionCallCount += 1
        if shouldThrowOnConfigure {
            throw MockAudioManagerError.configureAudioSession
        }
    }

    func prepareAndStartEngine() throws {
        prepareAndStartEngineCallCount += 1
        if shouldThrowOnStart {
            throw MockAudioManagerError.prepareAndStart
        }
    }

    func stopEngine() {
        stopEngineCallCount += 1
    }

    func startCapture(
        bufferSize: AVAudioFrameCount = 4096,
        handler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void
    ) throws {
        startCaptureSimpleCallCount += 1
        if shouldThrowOnCapture {
            throw MockAudioManagerError.startCapture
        }
    }

    func startCapture(
        targetFormat: AVAudioFormat,
        bufferSize: AVAudioFrameCount = 4096,
        handler: @escaping @Sendable (AVAudioPCMBuffer) -> Void
    ) throws {
        startCaptureWithFormatCallCount += 1
        if shouldThrowOnCapture {
            throw MockAudioManagerError.startCapture
        }
    }
}
