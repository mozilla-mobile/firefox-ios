// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import SummarizeKit
import Shared
import ComponentLibrary
@testable import Client

final class MockSummarizer: SummarizerProtocol, @unchecked Sendable {
    var modelName: SummarizerModel = .appleSummarizer

    func summarize(_ contentToSummarize: String) async throws -> String {
        return ""
    }

    func summarizeStreamed(_ contentToSummarize: String) -> AsyncThrowingStream<String, any Error> {
        return .init { _ in }
    }
}

class MockSummarizerServiceFactory: SummarizerServiceFactory {
    weak var lifecycleDelegate: SummarizerServiceLifecycle?

    func make(isAppleSummarizerEnabled: Bool,
              isHostedSummarizerEnabled: Bool,
              isAppAttestAuthEnabled: Bool,
              config: SummarizerConfig?) -> SummarizerService? {
        return DefaultSummarizerService(summarizer: MockSummarizer(), lifecycleDelegate: lifecycleDelegate, maxWords: 10)
    }

    func maxWords(isAppleSummarizerEnabled: Bool, isHostedSummarizerEnabled: Bool) -> Int {
        return 0
    }
}

@MainActor
final class SummarizeCoordinatorTests: XCTestCase {
    private var browserViewController: MockBrowserViewController!
    private var router: MockRouter!
    private var parentCoordinator: MockParentCoordinator!
    private var prefs: MockProfilePrefs!
    private var gleanWrapper: MockGleanWrapper!
    private let url = URL(string: "https://example.com")!

    override func setUp() async throws {
        try await super.setUp()
        setIsHostedSummarizerEnabled(true)
        DependencyHelperMock().bootstrapDependencies()
        browserViewController = MockBrowserViewController(profile: MockProfile(), tabManager: MockTabManager())
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
        prefs = MockProfilePrefs()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        browserViewController = nil
        router = nil
        prefs = nil
        parentCoordinator = nil
        gleanWrapper = nil
        try await super.tearDown()
    }

    func test_start_showsSummarizeController() throws {
        let subject = createSubject()

        subject.start()

        let presentedController = try XCTUnwrap(router.presentedViewController as? UINavigationController)

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(presentedController.viewControllers.first is SummarizeController)
    }

    func test_openURL() {
        let expectation = XCTestExpectation(description: "the open url callback should be called")
        let subject = createSubject { url in
            XCTAssertEqual(url, self.url)
            expectation.fulfill()
        }
        subject.openURL(url: url)
        wait(for: [expectation], timeout: 0.5)
    }

    func test_acceptConsent() throws {
        let subject = createSubject()
        subject.acceptConsent()

        let isConsentAccepted = try XCTUnwrap(prefs.boolForKey(PrefsKeys.Summarizer.didAgreeTermsOfService))
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertTrue(isConsentAccepted)
    }

    func test_denyConsent_recordsTelemetry() {
        let subject = createSubject()
        subject.denyConsent()

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
    }

    func test_dismissSummary() {
        let subject = createSubject()

        subject.dismissSummary()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
    }

    func test_summarizeServiceDidStart_recordsTelemetry() {
        let subject = createSubject()

        subject.summarizerServiceDidStart("")

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
    }

    func test_summarizeServiceDidComplete_recordsTelemetry() {
        let subject = createSubject()

        subject.summarizerServiceDidComplete("", modelName: .appleSummarizer)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
    }

    func test_summarizeServiceDidFail_recordsTelemetry() {
        let subject = createSubject()

        subject.summarizerServiceDidFail(.busy, modelName: .appleSummarizer)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
    }

    private func setIsHostedSummarizerEnabled(_ isEnabled: Bool) {
        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isEnabled)
        }
    }

    private func createSubject(
        onRequestOpenURL: ((URL?) -> Void)? = nil,
        trigger: SummarizerTrigger = .mainMenu) -> SummarizeCoordinator {
        let subject = SummarizeCoordinator(browserSnapshot: UIImage(),
                                           browserSnapshotTopOffset: 0.0,
                                           webView: MockTabWebView(tab: MockTab(profile: MockProfile(),
                                                                                windowUUID: .XCTestDefaultUUID)),
                                           summarizerServiceFactory: MockSummarizerServiceFactory(),
                                           parentCoordinatorDelegate: parentCoordinator,
                                           trigger: trigger,
                                           prefs: prefs,
                                           windowUUID: .XCTestDefaultUUID,
                                           router: router,
                                           gleanWrapper: gleanWrapper,
                                           onRequestOpenURL: onRequestOpenURL)
        trackForMemoryLeaks(subject)
        return subject
    }
}
