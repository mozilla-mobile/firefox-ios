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
    let navigationHandler = MockNavigationHandler()

    // MARK: - Microphone Permission Denied
    @Test
    func test_handleSpeechError_microphoneDenied_firstTime_dismisses() {
        let subject = createSubject()

        subject.handleSpeechError(.microphonePermissionDenied(isFirstTime: true))

        #expect(navigationHandler.dismissCallCount == 1)
        #expect(navigationHandler.lastNavigationType == nil)
        #expect(presenter.presentCallCount == 0)
    }

    @Test
    func test_handleSpeechError_microphoneDenied_notFirstTime_presentsAlert() {
        let subject = createSubject()

        subject.handleSpeechError(.microphonePermissionDenied(isFirstTime: false))

        #expect(presenter.presentCallCount == 1)
        #expect(navigationHandler.dismissCallCount == 0)
    }

    // MARK: - Speech Recognition Permission Denied
    @Test
    func test_handleSpeechError_speechDenied_firstTime_dismisses() {
        let subject = createSubject()

        subject.handleSpeechError(.speechRecognitionPermissionDenied(isFirstTime: true))

        #expect(navigationHandler.dismissCallCount == 1)
        #expect(navigationHandler.lastNavigationType == nil)
        #expect(presenter.presentCallCount == 0)
    }

    @Test
    func test_handleSpeechError_speechDenied_notFirstTime_presentsAlert() {
        let subject = createSubject()

        subject.handleSpeechError(.speechRecognitionPermissionDenied(isFirstTime: false))

        #expect(presenter.presentCallCount == 1)
        #expect(navigationHandler.dismissCallCount == 0)
    }

    // MARK: - Generic Errors
    @Test
    func test_handleSearchError_presentsGenericAlert() throws {
        let subject = createSubject()

        subject.handleSearchError(.unknown("boom"))

        #expect(presenter.presentCallCount == 1)
        #expect(navigationHandler.dismissCallCount == 0)

        let alert = try #require(presenter.lastPresentedViewController as? UIAlertController)
        #expect(alert.actions.count == 1)
    }

    @Test
    func test_handleInitializationError_presentsGenericAlert() throws {
        let subject = createSubject()

        subject.handleInitializationError()

        #expect(presenter.presentCallCount == 1)
        #expect(navigationHandler.dismissCallCount == 0)

        let alert = try #require(presenter.lastPresentedViewController as? UIAlertController)
        #expect(alert.actions.count == 1)
    }

    @Test
    func test_handleSpeechError_nonPermission_presentsGenericAlert() throws {
        let subject = createSubject()

        subject.handleSpeechError(.recognizerNotAvailable)

        #expect(presenter.presentCallCount == 1)
        #expect(navigationHandler.dismissCallCount == 0)

        let alert = try #require(presenter.lastPresentedViewController as? UIAlertController)
        #expect(alert.actions.count == 1)
    }

    @Test
    func test_genericAlertAction_dismissesViaNavigationHandler() throws {
        let subject = createSubject()

        subject.handleInitializationError()

        let alert = try #require(presenter.lastPresentedViewController as? UIAlertController)
        let action = try #require(alert.actions.first)

        let handler = try #require(action.value(forKey: "handler"))
        let block = unsafeBitCast(handler as AnyObject, to: (@convention(block) (UIAlertAction) -> Void).self)
        block(action)

        #expect(navigationHandler.dismissCallCount == 1)
        #expect(navigationHandler.lastNavigationType == nil)
    }

    // MARK: - Helper
    private func createSubject() -> ErrorHandler {
        let subject = ErrorHandler(presenter: presenter, navigationHandler: navigationHandler)
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
