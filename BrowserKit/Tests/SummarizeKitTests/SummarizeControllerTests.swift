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
    private let viewModel = SummarizeViewModel(
        titleLabelA11yId: "",
        compactTitleLabelA11yId: "",
        summaryFootnote: "Footnote",
        summarizeViewA11yId: "",
        tabSnapshotViewModel: TabSnapshotViewModel(
            tabSnapshotA11yLabel: "",
            tabSnapshotA11yId: "",
            tabSnapshot: .add,
            tabSnapshotTopOffset: 0
        ),
        loadingLabelViewModel: LoadingLabelViewModel(
            loadingLabel: "loading",
            loadingA11yLabel: "",
            loadingA11yId: ""
        ),
        brandViewModel: BrandViewModel(
            brandLabel: "",
            brandLabelA11yId: "",
            brandImage: nil,
            brandImageA11yId: ""
        ),
        closeButtonModel: CloseButtonViewModel(a11yLabel: "", a11yIdentifier: ""),
        errorMessages: LocalizedErrorsViewModel(
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
        tosViewModel: ToSBottomSheetViewModel(
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
        AppContainer.shared.register(service: DefaultThemeManager(sharedContainerIdentifier: "") as ThemeManager)
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        summarizer = nil
        navigationHandler = nil
        webView = nil
        AppContainer.shared.reset()
        super.tearDown()
    }

    func test_dismiss_callsNavigationHandler() {
        let subject = createSubject()

        subject.dismiss(animated: false)

        XCTAssertEqual(navigationHandler.dismissSummaryCalled, 1)
        XCTAssertEqual(navigationHandler.denyToSConsentCalled, 0)
    }

    func test_dismiss_denyTos_whenTosIsShown() {
        let expectation = XCTestExpectation(description: "ToS should be displayed")
        let subject = createSubject {
            expectation.fulfill()
        }

        subject.viewDidLoad()
        subject.viewWillAppear(false)

        wait(for: [expectation], timeout: 0.5)

        subject.dismiss(animated: false)

        XCTAssertEqual(navigationHandler.denyToSConsentCalled, 1)
        XCTAssertEqual(navigationHandler.acceptToSConsentCalled, 0)
        XCTAssertEqual(navigationHandler.dismissSummaryCalled, 1)
    }

    private func createSubject(
        isTosAccepted: Bool = false,
        onSummaryDisplayed: @escaping () -> Void = {}
    ) -> SummarizeController {
        let service = SummarizerService(summarizer: summarizer, maxWords: maxWords)
        let controller = SummarizeController(
            windowUUID: .XCTestDefaultUUID,
            viewModel: viewModel,
            summarizerService: service,
            navigationHandler: navigationHandler,
            webView: webView,
            isTosAccepted: isTosAccepted,
            onSummaryDisplayed: onSummaryDisplayed
        )
        return controller
    }
}
