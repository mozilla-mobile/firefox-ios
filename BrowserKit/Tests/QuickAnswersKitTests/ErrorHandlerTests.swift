// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Testing
import TestKit

@testable import QuickAnswersKit

@Suite
@MainActor
struct ErrorHandlerTests {
    let testHelper = SwiftTestingHelper()
    let presenter = MockPresenter()
    let dismisser = MockDismissable()

    // MARK: - Microphone Permission Denied
    @Test
    func test_handleSpeechError_microphoneDenied_firstTime_dismisses() {
        let subject = createSubject()

        subject.handleSpeechError(.microphonePermissionDenied(isFirstTime: true))

        #expect(dismisser.dismissCallCount == 1)
        #expect(dismisser.lastURL == nil)
        #expect(presenter.presentCallCount == 0)
    }

    @Test
    func test_handleSpeechError_microphoneDenied_notFirstTime_presentsAlert() {
        let subject = createSubject()

        subject.handleSpeechError(.microphonePermissionDenied(isFirstTime: false))

        #expect(presenter.presentCallCount == 1)
        #expect(dismisser.dismissCallCount == 0)
    }

    // MARK: - Speech Recognition Permission Denied
    @Test
    func test_handleSpeechError_speechDenied_firstTime_dismisses() {
        let subject = createSubject()

        subject.handleSpeechError(.speechRecognitionPermissionDenied(isFirstTime: true))

        #expect(dismisser.dismissCallCount == 1)
        #expect(dismisser.lastURL == nil)
        #expect(presenter.presentCallCount == 0)
    }

    @Test
    func test_handleSpeechError_speechDenied_notFirstTime_presentsAlert() {
        let subject = createSubject()

        subject.handleSpeechError(.speechRecognitionPermissionDenied(isFirstTime: false))

        #expect(presenter.presentCallCount == 1)
        #expect(dismisser.dismissCallCount == 0)
    }

    // MARK: - Helper
    private func createSubject() -> ErrorHandler {
        let subject = ErrorHandler(presenter: presenter, dismisser: dismisser)
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
