// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SummarizeKit

extension Result {
    func failure() -> Failure? {
        if case let .failure(error) = self {
            return error
        }
        return nil
    }
}

class MockDateProvider: DateProvider {
    var returnedDates: [Date] = []

    func currentDate() -> Date {
        let date = Date()
        returnedDates.append(date)
        return date
    }
}

@MainActor
final class SummarizeViewModelTests: XCTestCase {
    private var tosAcceptor: MockSummarizeToSAcceptor!
    private var summarizerService: MockSummarizerService!
    private var webView: MockWebView!
    private var dateProvider: MockDateProvider!
    private let maxWords = 5000
    private let url = URL(string: "https://example.com")!

    override func setUp() {
        super.setUp()
        webView = MockWebView(url)
        dateProvider = MockDateProvider()
        summarizerService = MockSummarizerService()
        tosAcceptor = MockSummarizeToSAcceptor()
    }

    override func tearDown() {
        tosAcceptor = nil
        dateProvider = nil
        summarizerService = nil
        webView = nil
        super.tearDown()
    }

    func test_summarize_whenTosNotAccepted() {
        let newDataExpectation = expectation(description: "summarize closure should be called")
        let subject = createSubject(isTosAccepted: false)

        subject.unblockSummarization()

        subject.summarize(webView: webView, footNoteLabel: "", dateProvider: dateProvider) { result in
            let error = try? XCTUnwrap(result.failure())

            XCTAssertEqual(error, .tosConsentMissing)
            newDataExpectation.fulfill()
        }
        wait(for: [newDataExpectation], timeout: 0.5)
    }

    func test_summarize_withNotEnoughStartingWords() {
        let newDataExpectation = expectation(description: "summarize closure should be called")
        let chunk = "This is the max words to proceed"
        let footnote = "Footnote"
        summarizerService.mockChunchedResponse = [chunk]
        let responseWithNote = """
        \(chunk)

        ##### \(footnote)
        """
        let subject = createSubject(minWordsAcceptToShow: chunk.count + 1)

        subject.unblockSummarization()

        subject.summarize(webView: webView, footNoteLabel: footnote, dateProvider: dateProvider) { result in
            let response = try? XCTUnwrap(result.get())

            // The first time is called the closure it responds just with summary
            // then it fires again with the note appended.
            if response == chunk {
                XCTAssertEqual(self.summarizerService.summarizeStreamedCalled, 1)
                return
            }
            XCTAssertEqual(response, responseWithNote)
            newDataExpectation.fulfill()
        }
        wait(for: [newDataExpectation], timeout: 0.5)
    }

    func test_summarize_withEnoughStartingWords() {
        let newDataExpectation = expectation(description: "summarize closure should be called")
        let chunk = "This is the max words to proceed"
        let footnote = "Footnote"
        summarizerService.mockChunchedResponse = [chunk]
        let responseWithNote = """
        \(chunk)

        ##### \(footnote)
        """
        let subject = createSubject(minWordsAcceptToShow: chunk.count - 1)

        subject.unblockSummarization()

        subject.summarize(webView: webView, footNoteLabel: footnote, dateProvider: dateProvider) { result in
            let response = try? XCTUnwrap(result.get())

            // The first time is called the closure it responds just with summary
            // then it fires again with the note appended.
            if response == chunk {
                XCTAssertEqual(self.summarizerService.summarizeStreamedCalled, 1)
                return
            }
            XCTAssertEqual(response, responseWithNote)
            newDataExpectation.fulfill()
        }
        wait(for: [newDataExpectation], timeout: 0.5)
    }

    func test_summarize_waitsForInitialDelay() {
        let newDataExpectation = expectation(description: "summarize closure should be called")
        let chunk = "This is the max words to proceed"
        let delay = 2.0
        summarizerService.mockChunchedResponse = [chunk]
        summarizerService.delayStreamResultInSeconds = delay
        // make sure enough words is false
        let subject = createSubject(minDelayToShowSummary: delay, minWordsAcceptToShow: chunk.count + 1)

        subject.unblockSummarization()

        subject.summarize(webView: webView, footNoteLabel: "Footnote", dateProvider: dateProvider) { result in
            let result = try? result.get()
            // don't fulfill untill the footnote is passed
            guard result != chunk else { return }
            newDataExpectation.fulfill()
        }

        wait(for: [newDataExpectation], timeout: delay + 1)

        XCTAssertEqual(dateProvider.returnedDates.count, 2)
        XCTAssertGreaterThanOrEqual(dateProvider.returnedDates[1], dateProvider.returnedDates[0].addingTimeInterval(delay))
    }

    func test_summarize_whenPassRandomError_throwsUnkownSummarizerError() {
        let newDataExpectation = expectation(description: "summarize closure should be called")
        let error = NSError(domain: "", code: 0)
        summarizerService.mockError = error
        let subject = createSubject()

        subject.unblockSummarization()

        subject.summarize(webView: webView, footNoteLabel: "", dateProvider: dateProvider) { result in
            let response = try? XCTUnwrap(result.failure())

            XCTAssertEqual(response, .unknown(error))
            newDataExpectation.fulfill()
        }
        wait(for: [newDataExpectation], timeout: 0.5)
    }

    func test_summarize_throwsSummarizeError() {
        let newDataExpectation = expectation(description: "summarize closure should be called")
        let error = SummarizerError.cancelled
        summarizerService.mockError = error
        let subject = createSubject()

        subject.unblockSummarization()

        subject.summarize(webView: webView, footNoteLabel: "", dateProvider: dateProvider) { result in
            let response = try? XCTUnwrap(result.failure())

            XCTAssertEqual(response, error)
            newDataExpectation.fulfill()
        }
        wait(for: [newDataExpectation], timeout: 0.5)
    }

    func test_setTosConsentAccepted_callsTosAcceptorAllowConsent() {
        let subject = createSubject()

        subject.setConsentAccepted()

        XCTAssertEqual(tosAcceptor.acceptTosConsentCalled, 1)
    }

    func test_logTosStatus_callTosAcceptorDenyConsent() {
        let subject = createSubject(isTosAccepted: false)
        subject.setConsentScreenShown()

        subject.logConsentStatus()

        XCTAssertEqual(tosAcceptor.denyTosConsentCalled, 1)
        XCTAssertEqual(tosAcceptor.acceptTosConsentCalled, 0)
    }

    func test_logTosStatus_doesntToSAcceptorDenyConsent() {
        let subject = createSubject()
        subject.setConsentScreenShown()
        subject.setConsentAccepted()

        subject.logConsentStatus()

        XCTAssertEqual(tosAcceptor.denyTosConsentCalled, 0)
        XCTAssertEqual(tosAcceptor.acceptTosConsentCalled, 1)
    }

    func test_closeSummarization() {
        let subject = createSubject()

        subject.closeSummarization()

        XCTAssertEqual(summarizerService.closeCurrentStreamedSessionCalled, 1)
    }

    private func createSubject(isTosAccepted: Bool = true,
                               minDelayToShowSummary: TimeInterval? = nil,
                               minWordsAcceptToShow: Int? = nil) -> DefaultSummarizeViewModel {
        let viewModel = DefaultSummarizeViewModel(
            summarizerService: summarizerService,
            tosAcceptor: tosAcceptor,
            minWordsAcceptedToShow: minWordsAcceptToShow,
            minDelayToShowSummary: minDelayToShowSummary,
            isTosAcceppted: isTosAccepted
        )
        trackForMemoryLeaks(viewModel)
        return viewModel
    }
}
