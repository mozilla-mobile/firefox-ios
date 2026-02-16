// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Testing

@testable import VoiceSearchKit

@Suite
struct SFSpeechRecognizerEngineTests {
    // TODO: FXIOS-14891 Add more test to improve code coverage and check for memory leaks
    let session = MockAudioSession()

    @Test
    func test_prepare_microphoneDenied_speechDenied_throwsError() async {
        let authorizer = MockAuthorizer(micAuthorized: false, speechAuthorized: false)
        let subject = SFSpeechRecognizerEngine(audioSession: session, authorizer: authorizer)

        await #expect(throws: SpeechError.permissionDenied) {
            try await subject.prepare()
        }

        #expect(session.setCategoryCalls.isEmpty)
        #expect(session.setActiveCalls.isEmpty)
    }

    @Test
    func test_prepare_microphoneDenied_speechGranted_throwsError() async {
        let authorizer = MockAuthorizer(micAuthorized: false, speechAuthorized: true)
        let subject = SFSpeechRecognizerEngine(audioSession: session, authorizer: authorizer)

        await #expect(throws: SpeechError.permissionDenied) {
            try await subject.prepare()
        }

        #expect(session.setCategoryCalls.isEmpty)
        #expect(session.setActiveCalls.isEmpty)
    }

    @Test
    func test_prepare_microphoneGranted_speechDenied_throwsError() async {
        let authorizer = MockAuthorizer(micAuthorized: true, speechAuthorized: false)
        let engine = SFSpeechRecognizerEngine(audioSession: session, authorizer: authorizer)

        await #expect(throws: SpeechError.permissionDenied) {
            try await engine.prepare()
        }

        #expect(session.setCategoryCalls.isEmpty)
        #expect(session.setActiveCalls.isEmpty)
    }

    @Test
    func test_prepare_microphoneGranted_speechGranted_returnsExpectedCalls() async throws {
        let authorizer = MockAuthorizer(micAuthorized: true, speechAuthorized: true)
        let subject = SFSpeechRecognizerEngine(audioSession: session, authorizer: authorizer)
        try await subject.prepare()

        #expect(session.setCategoryCalls.count == 1)
        #expect(session.setCategoryCalls[0].category == .record)
        #expect(session.setCategoryCalls[0].mode == .measurement)
        #expect(session.setCategoryCalls[0].options.contains(.duckOthers))

        #expect(session.setActiveCalls.count == 1)
        let (active, activeOptions) = session.setActiveCalls[0]
        #expect(active == true)
        #expect(activeOptions.contains(.notifyOthersOnDeactivation))
    }

    @Test
    func test_stop_returnsExpectedCalls() async throws {
        let authorizer = MockAuthorizer(micAuthorized: true, speechAuthorized: true)
        let subject = SFSpeechRecognizerEngine(audioSession: session, authorizer: authorizer)
        try await subject.prepare()

        #expect(session.setCategoryCalls.count == 1)
        #expect(session.setCategoryCalls[0].category == .record)
        #expect(session.setCategoryCalls[0].mode == .measurement)
        #expect(session.setCategoryCalls[0].options.contains(.duckOthers))

        #expect(session.setActiveCalls.count == 1)
        let (active, activeOptions) = session.setActiveCalls[0]
        #expect(active == true)
        #expect(activeOptions.contains(.notifyOthersOnDeactivation))
    }

    @Test
    func test_stop_createsRecognitionTask() async throws {
        let authorizer = MockAuthorizer(micAuthorized: true, speechAuthorized: true)
        let engine = MockAudioEngine()
        let subject = SFSpeechRecognizerEngine(audioEngine: engine, audioSession: session, authorizer: authorizer)

        await subject.stop()

        #expect(engine.stopCallCount == 1)
    }
}
