// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import SummarizeKit
import Shared
import ComponentLibrary
@testable import Client

class MockSummarizer: SummarizerProtocol {
    var modelName: SummarizerModel = .appleSummarizer

    func summarize(_ contentToSummarize: String) async throws -> String {
        return ""
    }

    func summarizeStreamed(_ contentToSummarize: String) -> AsyncThrowingStream<String, any Error> {
        return .init { _ in }
    }
}

class MockSummarizerServiceFactory: SummarizerServiceFactory {
    func make(isAppleSummarizerEnabled: Bool,
              isHostedSummarizerEnabled: Bool,
              config: SummarizerConfig?) -> SummarizerService? {
        return SummarizerService(summarizer: MockSummarizer(), maxWords: 10)
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
    private let url = URL(string: "https://example.com")!

    override func setUp() {
        super.setUp()
        setIsHostedSummarizerEnabled(true)
        DependencyHelperMock().bootstrapDependencies()
        browserViewController = MockBrowserViewController(profile: MockProfile(), tabManager: MockTabManager())
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
        prefs = MockProfilePrefs()
        prefs.setBool(false, forKey: PrefsKeys.Summarizer.didAgreeTermsOfService)
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        browserViewController = nil
        router = nil
        prefs = nil
        parentCoordinator = nil
        super.tearDown()
    }

    func testStart_showsToSPanel_whenTermsOfServiceMissing() {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is BottomSheetViewController)
    }

    func testStart_showsSummarizeController_whenTermsOfServiceAgreed() {
        prefs.setBool(true, forKey: PrefsKeys.Summarizer.didAgreeTermsOfService)
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is SummarizeController)
    }

    func testStart_whenPressLearnMoreLink_onToSBottomSheet() throws {
        let expectation = XCTestExpectation(description: "open URL should be called when ToS text view link is tapped")
        let subject = createSubject { url in
            XCTAssertEqual(url, self.url)
            expectation.fulfill()
        }

        subject.start()

        let bottomSheetViewController = try XCTUnwrap(router.presentedViewController as? BottomSheetViewController)
        bottomSheetViewController.loadViewIfNeeded()
        let tosController = try XCTUnwrap(bottomSheetViewController.children.first as? ToSBottomSheetViewController)

        _ = tosController.textView(UITextView(), shouldInteractWith: url, in: .init())

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        wait(for: [expectation], timeout: 1.0)
    }

    func testStart_dismissCoordinator_whenTermsOfServiceMissing() throws {
        let subject = createSubject()

        subject.start()
        let bottomSheet = try XCTUnwrap(router.presentedViewController as? BottomSheetViewController)
        bottomSheet.dismissSheetViewController()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func testStart_dismissCoordinator_whenToSBottomSheetCallsWillDismiss() throws {
        let subject = createSubject()

        subject.start()

        let bottomSheetViewController = try XCTUnwrap(router.presentedViewController as? BottomSheetViewController)
        bottomSheetViewController.loadViewIfNeeded()
        let tosController = try XCTUnwrap(bottomSheetViewController.children.first as? ToSBottomSheetViewController)
        tosController.willDismiss()

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func testStart_dismissCoordinator_whenTermsOfServiceAgreed() {
        prefs.setBool(true, forKey: PrefsKeys.Summarizer.didAgreeTermsOfService)
        let subject = createSubject()

        subject.start()
        router.presentedViewController?.dismiss(animated: false)

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
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
                                           browserContentHiding: browserViewController,
                                           parentCoordinatorDelegate: parentCoordinator,
                                           trigger: trigger,
                                           prefs: prefs,
                                           windowUUID: .XCTestDefaultUUID,
                                           router: router,
                                           onRequestOpenURL: onRequestOpenURL)
        trackForMemoryLeaks(subject)
        return subject
    }
}
