// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
@testable import VoiceSearchKit

final class MockAudioEngine: AudioEngineProvider, @unchecked Sendable {
    let mockInputNode = MockAudioInputNode()

    private(set) var prepareCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    var audioInputNode: AudioInputNodeProvider {
        mockInputNode
    }

    func prepare() {
        prepareCallCount += 1
    }

    func start() throws {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }
}

final class MockAudioInputNode: AudioInputNodeProvider, @unchecked Sendable {
    private let nativeFormat: AVAudioFormat
    private var tapHandler: AVAudioNodeTapBlock?

    private(set) var installTapCallCount = 0
    private(set) var removeTapCallCount = 0
    private(set) var outputFormatCallCount = 0

    init(sampleRate: Double = 44100, channels: UInt32 = 1) {
        self.nativeFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels)!
    }

    func installTap(
        onBus bus: AVAudioNodeBus,
        bufferSize: AVAudioFrameCount,
        format: AVAudioFormat?,
        block: @escaping @Sendable AVAudioNodeTapBlock
    ) {
        installTapCallCount += 1
        tapHandler = block
    }

    func removeTap(onBus bus: AVAudioNodeBus) {
        removeTapCallCount += 1
        tapHandler = nil
    }

    func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat {
        outputFormatCallCount += 1
        return nativeFormat
    }

    func simulateAudioInput(frameCount: AVAudioFrameCount = 1024) {
        guard let handler = tapHandler,
              let buffer = AVAudioPCMBuffer(pcmFormat: nativeFormat, frameCapacity: frameCount) else {
            return
        }
        buffer.frameLength = frameCount
        let time = AVAudioTime()
        handler(buffer, time)
    }
}
