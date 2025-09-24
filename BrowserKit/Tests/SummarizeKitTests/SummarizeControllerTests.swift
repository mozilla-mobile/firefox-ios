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
            errorLabelA11yId: "",
            errorButtonA11yId: "",
            retryButtonLabel: "",
            closeButtonLabel: "",
            acceptToSButtonLabel: ""
        ),
        termOfService: TermOfServiceViewConfiguration(
            titleLabel: "",
            titleLabelA11yId: "",
            descriptionText: "",
            descriptionTextA11yId: "",
            linkButtonLabel: "",
            linkButtonURL: nil,
            allowButtonTitle: "",
            allowButtonA11yId: "",
            allowButtonA11yLabel: "",
            cancelButtonTitle: "",
            cancelButtonA11yId: "",
            cancelButtonA11yLabel: ""
        )
    )
    private let maxWords = 5000

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
        summarizer = MockSummarizer(shouldRespond: ["Response"], shouldThrowError: nil)
        navigationHandler = MockSummarizeNavigationHandler()
        webView = MockWebView(URL(string: "https://www.example.com")!)
        viewModel = MockSummarizeViewModel()
        AppContainer.shared.register(service: DefaultThemeManager(sharedContainerIdentifier: "") as ThemeManager)
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        summarizer = nil
        navigationHandler = nil
        webView = nil
        viewModel = nil
        AppContainer.shared.reset()
        super.tearDown()
    }

    func test_viewDidLoad_startSummarizing() async {
        let subject = createSubject()

        // Calls view did load just once, instead of calling directly viewDidLoad()
        _ = subject.view

        await MainActor.run {
            XCTAssertEqual(viewModel.summarizeCalled, 1)
        }
    }

    func test_viewDidLoad_whenTosIsNotShown() async {
        let subject = createSubject()
        viewModel.injectedSummarizeResult = .failure(.tosConsentMissing)

        _ = subject.view

        await MainActor.run {
            XCTAssertEqual(viewModel.summarizeCalled, 1)
            XCTAssertEqual(viewModel.setTosScreenShownCalled, 1)
        }
    }

    func test_viewDidAppear_unblocksSummarization() async {
        let subject = createSubject()

        subject.viewDidAppear(false)

        await MainActor.run {
            XCTAssertEqual(viewModel.unblockSummarizationCalled, 1)
        }
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
        trackForMemoryLeaks(controller)
        return controller
    }
}
