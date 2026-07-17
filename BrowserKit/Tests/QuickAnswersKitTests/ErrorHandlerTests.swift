// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Testing
import TestKit

@testable import QuickAnswersKit

@MainActor
final class DismissSpy {
    var callCount = 0
}

@Suite
@MainActor
struct ErrorHandlerTests {
    let testHelper = SwiftTestingHelper()
    let presenter = MockPresenter()
    let dismissSpy = DismissSpy()

    // MARK: - Microphone Permission Denied
    @Test
    func test_handleSpeechError_microphoneDenied_firstTime_dismisses() {
        let subject = createSubject()

        subject.handleSpeechError(.microphonePermissionDenied(isFirstTime: true))

        #expect(dismissSpy.callCount == 1)
        #expect(presenter.presentCallCount == 0)
    }

    @Test
    func test_handleSpeechError_microphoneDenied_notFirstTime_presentsAlert() {
        let subject = createSubject()

        subject.handleSpeechError(.microphonePermissionDenied(isFirstTime: false))

        #expect(presenter.presentCallCount == 1)
        #expect(dismissSpy.callCount == 0)
    }

    // MARK: - Speech Recognition Permission Denied
    @Test
    func test_handleSpeechError_speechDenied_firstTime_dismisses() {
        let subject = createSubject()

        subject.handleSpeechError(.speechRecognitionPermissionDenied(isFirstTime: true))

        #expect(dismissSpy.callCount == 1)
        #expect(presenter.presentCallCount == 0)
    }

    @Test
    func test_handleSpeechError_speechDenied_notFirstTime_presentsAlert() {
        let subject = createSubject()

        subject.handleSpeechError(.speechRecognitionPermissionDenied(isFirstTime: false))

        #expect(presenter.presentCallCount == 1)
        #expect(dismissSpy.callCount == 0)
    }

    // MARK: - Catch-all Errors
    @Test
    func test_handleSpeechError_nonPermissionError_presentsCatchAllAlert() {
        let subject = createSubject()

        subject.handleSpeechError(.unknown("boom"))

        #expect(presenter.presentCallCount == 1)
        #expect(dismissSpy.callCount == 0)
    }

    @Test
    func test_handleSearchError_presentsCatchAllAlert() {
        let subject = createSubject()

        subject.handleSearchError(.rateLimited)

        #expect(presenter.presentCallCount == 1)
        #expect(dismissSpy.callCount == 0)
    }

    // MARK: - Helper
    private func createSubject() -> ErrorHandler {
        let subject = ErrorHandler(presenter: presenter, onDismiss: { [dismissSpy] in dismissSpy.callCount += 1 })
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
