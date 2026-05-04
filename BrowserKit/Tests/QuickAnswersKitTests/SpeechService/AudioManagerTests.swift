// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Testing
import TestKit

@testable import QuickAnswersKit

@Suite
struct AudioManagerTests {
    let testHelper = SwiftTestingHelper()
    let session = MockAudioSession()
    let engine = MockAudioEngine()

    // MARK: - Audio Session Configuration Tests
    @Test
    func test_configureAudioSession_setsCorrectFields() throws {
        let subject = createSubject()

        try subject.configureAudioSession()

        #expect(session.setCategoryCalls.count == 1)
        #expect(session.setCategoryCalls[0].category == .record)
        #expect(session.setCategoryCalls[0].mode == .measurement)
        #expect(session.setCategoryCalls[0].options.contains(.duckOthers))
    }

    @Test
    func test_configureAudioSession_activatesSessionWithCorrectOptions() throws {
        let subject = createSubject()

        try subject.configureAudioSession()

        #expect(session.setActiveCalls.count == 1)
        #expect(session.setActiveCalls[0].active == true)
        #expect(session.setActiveCalls[0].options.contains(.notifyOthersOnDeactivation))
    }

    // MARK: - Engine Lifecycle Tests
    @Test
    func test_prepareAndStartEngine_callsExpectedEngineMethods() throws {
        let subject = createSubject()

        try subject.prepareAndStartEngine()

        #expect(engine.prepareCallCount == 1)
        #expect(engine.startCallCount == 1)
    }

    @Test
    func test_stopEngine_callsStop() {
        let subject = createSubject()

        subject.stopEngine()

        #expect(engine.stopCallCount == 1)
        #expect(engine.mockInputNode.removeTapCallCount == 1)
    }

    // MARK: - Start Capture Tests
    @Test
    func test_startCapture_installsTapOnBus0() {
        let subject = createSubject()

        subject.startCapture { _, _ in }

        #expect(engine.mockInputNode.removeTapCallCount == 1)
        #expect(engine.mockInputNode.installTapCallCount == 1)
    }

    @Test
    func test_startCapture_usesCorrectBufferSize() {
        let subject = createSubject()
        subject.startCapture(bufferSize: 1024) { _, _ in }

        #expect(engine.mockInputNode.installTapCallCount == 1)
    }

    @Test
    func test_startCapture_withFormatConversion_installsTap() {
        let subject = createSubject()
        let targetFormat = AVAudioFormat(
            standardFormatWithSampleRate: 16000,
            channels: 1
        )!

        subject.startCapture(targetFormat: targetFormat) { _ in }

        #expect(engine.mockInputNode.installTapCallCount == 1)
    }

    // MARK: - Format Conversion Tests
    @Test
    func test_convertIfNeeded_withDifferentSampleRate_convertsBuffer() {
        let subject = createSubject()
        let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!

        subject.startCapture(targetFormat: targetFormat) { buffer in
            #expect(buffer.format.sampleRate == 16000)
            #expect(buffer.format.channelCount == 1)
            // calculated by ratio (target sample rate / buffer sample rate) * buffer.frameLength
            // (16000 / 44100) * 1024
            #expect(buffer.frameLength == 371)
        }

        engine.mockInputNode.simulateAudioInput(frameCount: 1024)

        #expect(engine.mockInputNode.outputFormatCallCount == 1)
        #expect(engine.mockInputNode.removeTapCallCount == 1)
        #expect(engine.mockInputNode.installTapCallCount == 1)
    }

    @Test
    func test_convertIfNeeded_withMatchingSampleRate_passesThroughWithoutConversion() {
        let subject = createSubject()
        let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        subject.startCapture(targetFormat: targetFormat) { buffer in
            #expect(buffer.format.sampleRate == 44100.0)
            #expect(buffer.format.channelCount == 1)
            #expect(buffer.frameLength == 1024)
        }

        engine.mockInputNode.simulateAudioInput(frameCount: 1024)

        #expect(engine.mockInputNode.outputFormatCallCount == 1)
        #expect(engine.mockInputNode.removeTapCallCount == 1)
        #expect(engine.mockInputNode.installTapCallCount == 1)
    }

    private func createSubject() -> AudioManager {
        let subject = AudioManager(audioEngine: engine, audioSession: session)
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
