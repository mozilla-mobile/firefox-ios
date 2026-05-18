// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Testing
import TestKit

@testable import QuickAnswersKit
@Suite
@MainActor
struct SFSpeechRecognizerEngineTests {
    let testHelper = SwiftTestingHelper()
    let audioManager = MockAudioManager()

    @Test
    func test_prepare_microphoneDenied_speechDenied_throwsMicrophoneError() async {
        let authorizer = MockAuthorizer(micAuthorized: false, speechAuthorized: false)
        let subject = createSubject(authorizer: authorizer)

        await #expect(throws: SpeechError.microphonePermissionDenied(isFirstTime: false)) {
            try await subject.prepare()
        }

        #expect(audioManager.configureAudioSessionCallCount == 0)
    }

    @Test
    func test_prepare_microphoneDenied_firstTime_throwsMicrophoneFirstTimeError() async {
        let authorizer = MockAuthorizer(micAuthorized: false, speechAuthorized: false, micUndetermined: true)
        let subject = createSubject(authorizer: authorizer)

        await #expect(throws: SpeechError.microphonePermissionDenied(isFirstTime: true)) {
            try await subject.prepare()
        }

        #expect(audioManager.configureAudioSessionCallCount == 0)
    }

    @Test
    func test_prepare_microphoneDenied_speechGranted_throwsMicrophoneError() async {
        let authorizer = MockAuthorizer(micAuthorized: false, speechAuthorized: true)
        let subject = createSubject(authorizer: authorizer)

        await #expect(throws: SpeechError.microphonePermissionDenied(isFirstTime: false)) {
            try await subject.prepare()
        }

        #expect(audioManager.configureAudioSessionCallCount == 0)
    }

    @Test
    func test_prepare_microphoneGranted_speechDenied_throwsSpeechError() async {
        let authorizer = MockAuthorizer(micAuthorized: true, speechAuthorized: false)
        let subject = createSubject(authorizer: authorizer)

        await #expect(throws: SpeechError.speechRecognitionPermissionDenied(isFirstTime: false)) {
            try await subject.prepare()
        }

        #expect(audioManager.configureAudioSessionCallCount == 0)
    }

    @Test
    func test_prepare_speechDenied_firstTime_throwsSpeechFirstTimeError() async {
        let authorizer = MockAuthorizer(micAuthorized: true, speechAuthorized: false, speechUndetermined: true)
        let subject = createSubject(authorizer: authorizer)

        await #expect(throws: SpeechError.speechRecognitionPermissionDenied(isFirstTime: true)) {
            try await subject.prepare()
        }

        #expect(audioManager.configureAudioSessionCallCount == 0)
    }

    @Test
    func test_prepare_withPermissions_callsConfigureAudioSession() async throws {
        let authorizer = MockAuthorizer(micAuthorized: true, speechAuthorized: true)
        let subject = createSubject(authorizer: authorizer)

        try await subject.prepare()

        #expect(audioManager.configureAudioSessionCallCount == 1)
    }

    @Test
    func test_prepare_withPermissions_throwsError() async throws {
        let authorizer = MockAuthorizer(micAuthorized: true, speechAuthorized: true)
        let subject = createSubject(authorizer: authorizer)
        audioManager.shouldThrowOnConfigure = true

        await #expect(throws: MockAudioManagerError.configureAudioSession) {
            try await subject.prepare()
        }

        #expect(audioManager.configureAudioSessionCallCount == 1)
    }

    @Test
    func test_stop_callsStopEngine() {
        let authorizer = MockAuthorizer(micAuthorized: true, speechAuthorized: true)
        let subject = createSubject(authorizer: authorizer)

        subject.stop()

        #expect(audioManager.stopEngineCallCount == 1)
    }

    private func createSubject(
        authorizer: AuthorizeProvider
    ) -> SFSpeechRecognizerEngine {
        let subject =  SFSpeechRecognizerEngine(audioManager: audioManager, authorizer: authorizer)
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
