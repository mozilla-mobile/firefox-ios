// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import ComponentLibrary
import Common
@testable import SummarizeKit

final class MockSummarizeNavigationHandler: SummarizeNavigationHandler {
    var openURLCalled = 0
    var lastOpenedURL: URL?
    var acceptToSConsentCalled = 0
    var denyToSConsentCalled = 0
    var dismissSummaryCalled = 0

    func openURL(url: URL) {
        openURLCalled += 1
        lastOpenedURL = url
    }

    func acceptToSConsent() {
        acceptToSConsentCalled += 1
    }

    func denyToSConsent() {
        denyToSConsentCalled += 1
    }

    func dismissSummary() {
        dismissSummaryCalled += 1
    }
}

@MainActor
final class SummarizeControllerTests: XCTestCase {
    private var summarizer: MockSummarizer!
    private var navigationHandler: MockSummarizeNavigationHandler!
    private var webView: MockWebView!
    private var viewModel: MockSummarizeViewModel!
    private var animationController: MockAnimationController!
    private var snapshotLayoutCalculator: MockSnapshotLayoutCalculator!
    private let configuration = SummarizeViewConfiguration(
        titleLabelA11yId: "",
        compactTitleLabelA11yId: "",
        summaryFootnote: "Footnote",
        summarizeViewA11yId: "",
        tabSnapshot: TabSnapshotViewConfiguration(
            tabSnapshotA11yLabel: "",
            tabSnapshotA11yId: "",
            tabSnapshot: .add,
            tabSnapshotTopOffset: 0
        ),
        loadingLabel: LoadingLabelViewConfiguration(
            loadingLabel: "loading",
            loadingA11yLabel: "",
            loadingA11yId: ""
        ),
        brandView: BrandViewConfiguration(
            brandLabel: "",
            brandLabelA11yId: "",
            brandImage: nil,
            brandImageA11yId: ""
        ),
        closeButton: CloseButtonViewModel(a11yLabel: "", a11yIdentifier: ""),
        errorMessages: LocalizedErrorsViewConfiguration(
            rateLimitedMessage: "",
            unsafeContentMessage: "",
            summarizationNotAvailableMessage: "",
            pageStillLoadingMessage: "",
            genericErrorMessage: "",
            errorContentA11yId: "",
            retryButtonLabel: "",
            retryButtonA11yLabel: "",
            retryButtonA11yId: "",
            closeButtonLabel: "",
            closeButtonA11yLabel: "",
            closeButtonA11yId: ""
        ),
        termOfService: TermOfServiceViewConfiguration(
            titleLabel: "",
            descriptionText: "",
            linkButtonLabel: "",
            linkButtonURL: nil,
            allowButtonTitle: "",
            allowButtonA11yId: "",
            allowButtonA11yLabel: ""
        )
    )

    override func setUp() async throws {
        try await super.setUp()
        summarizer = MockSummarizer(shouldRespond: ["Response"], shouldThrowError: nil)
        navigationHandler = MockSummarizeNavigationHandler()
        webView = MockWebView(URL(string: "https://www.example.com")!)
        viewModel = MockSummarizeViewModel()
        animationController = MockAnimationController()
        snapshotLayoutCalculator = MockSnapshotLayoutCalculator()
        AppContainer.shared.register(service: DefaultThemeManager(sharedContainerIdentifier: "") as ThemeManager)
    }

    override func tearDown() async throws {
        summarizer = nil
        navigationHandler = nil
        webView = nil
        viewModel = nil
        animationController = nil
        snapshotLayoutCalculator = nil
        AppContainer.shared.reset()
        try await super.tearDown()
    }

    func test_viewDidLoad_whenShowToSError() {
        var onSummarizeDisplayCalled = false
        let subject = createSubject {
            onSummarizeDisplayCalled = true
        }
        viewModel.injectedSummarizeResult = .failure(.tosConsentMissing)

        _ = subject.view

        XCTAssertEqual(viewModel.summarizeCalled, 1)
        XCTAssertEqual(viewModel.setTosScreenShownCalled, 1)
        XCTAssertEqual(animationController.animateToInfoCalled, 1)
        XCTAssertEqual(animationController.animateToSummaryCalled, 0)
        XCTAssertEqual(snapshotLayoutCalculator.didCallCalculateInfoTransform, 1)
        XCTAssertTrue(onSummarizeDisplayCalled)
    }

    func test_viewDidLoad_whenSummarizeSucceeds() {
        var onSummarizeDisplayCalled = false
        let subject = createSubject {
            onSummarizeDisplayCalled = true
        }
        viewModel.injectedSummarizeResult = .success("Test")

        _ = subject.view

        XCTAssertEqual(viewModel.summarizeCalled, 1)
        XCTAssertEqual(animationController.animateToSummaryCalled, 1)
        XCTAssertEqual(animationController.animateToInfoCalled, 0)
        XCTAssertEqual(snapshotLayoutCalculator.didCallCalculateSummaryTransform, 1)
        XCTAssertTrue(onSummarizeDisplayCalled)
    }

    func test_viewDidAppear() {
        let subject = createSubject()

        subject.viewDidAppear(false)

        XCTAssertEqual(viewModel.unblockSummarizationCalled, 1)
        XCTAssertEqual(animationController.animateViewDidAppearCalled, 1)
        XCTAssertEqual(snapshotLayoutCalculator.didCallCalculateViewDidAppearTransform, 1)
    }

    func test_viewWillTransition() {
        let subject = createSubject()

        subject.viewWillTransition(to: .zero, with: MockUIViewControllerTransitionCoordinator())

        XCTAssertTrue(snapshotLayoutCalculator.didRotateInterface)
        XCTAssertEqual(snapshotLayoutCalculator.didCallCalculateDidRotateTransform, 1)
    }

    func test_dismiss() {
        let subject = createSubject()

        subject.dismiss(animated: false)

        XCTAssertEqual(navigationHandler.dismissSummaryCalled, 1)
        XCTAssertEqual(viewModel.closeSummariationCalled, 1)
        XCTAssertEqual(viewModel.logTosStatusCalled, 1)
    }

    private func createSubject(
        isTosAccepted: Bool = false,
        onSummaryDisplayed: @escaping () -> Void = {}
    ) -> SummarizeController {
        let controller = SummarizeController(
            windowUUID: .XCTestDefaultUUID,
            configuration: configuration,
            viewModel: viewModel,
            navigationHandler: navigationHandler,
            webView: webView,
            onSummaryDisplayed: onSummaryDisplayed
        )
        controller.animationController = animationController
        controller.snapshotLayoutCalculator = snapshotLayoutCalculator
        trackForMemoryLeaks(controller)
        return controller
    }
}
