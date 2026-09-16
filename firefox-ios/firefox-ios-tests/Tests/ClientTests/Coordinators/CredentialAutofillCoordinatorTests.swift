// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import ComponentLibrary
import Common
import Glean
import MozillaAppServices
import XCTest

@testable import Client

@MainActor
final class CredentialAutofillCoordinatorTests: XCTestCase {
    private var profile: MockProfile!
    private var router: MockRouter!
    private var parentCoordinator: MockBrowserCoordinator!
    private var tabManager: MockTabManager!
    private var creditCardProvider: MockCreditCardProvider!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        tabManager = MockTabManager()
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockBrowserCoordinator()
        creditCardProvider = MockCreditCardProvider()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile, injectedTabManager: tabManager)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile.shutdown()
        profile = nil
        router = nil
        parentCoordinator = nil
        tabManager = nil
        creditCardProvider = nil
        try await super.tearDown()
    }

    func testShowCreditCardAutofill_withSaveState_presentsImmediatelyWithoutPrefetchingCards() {
        let subject = createSubject()

        subject.showCreditCardAutofill(
            creditCard: nil,
            decryptedCard: nil,
            viewType: .save,
            frame: nil,
            viewController: UIViewController(),
            alertContainer: UIView()
        )

        XCTAssertEqual(creditCardProvider.listCreditCardsCalledCount, 0)
        XCTAssertEqual(router.presentCalled, 1)
        let bottomSheetViewController = router.presentedViewController as? BottomSheetViewController
        XCTAssertNotNil(bottomSheetViewController)
        XCTAssertEqual(bottomSheetViewController?.viewModel.animatesPresentation, true)
    }

    func testShowCreditCardAutofill_withSelectSavedCard_prefetchesCardsBeforePresenting() {
        let subject = createSubject()
        creditCardProvider.shouldDeferListCreditCardsCompletion = true
        let presentExpectation = expectation(description: "wait for bottom sheet to present")
        router.onPresent = {
            presentExpectation.fulfill()
        }

        subject.showCreditCardAutofill(
            creditCard: nil,
            decryptedCard: nil,
            viewType: .selectSavedCard,
            frame: nil,
            viewController: UIViewController(),
            alertContainer: UIView()
        )

        XCTAssertEqual(creditCardProvider.listCreditCardsCalledCount, 1)
        XCTAssertEqual(router.presentCalled, 0)

        creditCardProvider.deferredListCreditCardsCompletion?([creditCardProvider.exampleCreditCard], nil)

        wait(for: [presentExpectation], timeout: 1.0)
        XCTAssertEqual(router.presentCalled, 1)
        let bottomSheetViewController = router.presentedViewController as? BottomSheetViewController
        XCTAssertNotNil(bottomSheetViewController)
        XCTAssertEqual(bottomSheetViewController?.viewModel.animatesPresentation, false)
    }

    func testShowCreditCardAutofill_withSelectSavedCardAndNoCards_finishesWithoutPresenting() {
        let subject = createSubject()
        creditCardProvider.creditCards = []
        let prefetchExpectation = expectation(description: "wait for card prefetch")

        subject.showCreditCardAutofill(
            creditCard: nil,
            decryptedCard: nil,
            viewType: .selectSavedCard,
            frame: nil,
            viewController: UIViewController(),
            alertContainer: UIView()
        )
        DispatchQueue.main.async {
            prefetchExpectation.fulfill()
        }

        wait(for: [prefetchExpectation], timeout: 1.0)
        XCTAssertEqual(creditCardProvider.listCreditCardsCalledCount, 1)
        XCTAssertEqual(router.presentCalled, 0)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func testSavedLoginSelection_whenSelectedTabOriginMatches_fillsCredential() throws {
        Self.setupTelemetry(with: profile)
        defer { Self.tearDownTelemetry() }
        tabManager.selectedTab = makeTab(urlString: "https://httpbin.org/login")
        let subject = createSubject()

        try selectSavedLogin(
            on: subject,
            capturedTabURL: URL(string: "https://httpbin.org")!,
            login: makeLogin(origin: "https://httpbin.org")
        )

        XCTAssertNotNil(GleanMetrics.Logins.autofilled.testGetValue(),
                        "Same-origin selection should inject the credential")
    }

    func testSavedLoginSelection_whenSelectedTabNavigatedToOtherOrigin_doesNotFill() throws {
        Self.setupTelemetry(with: profile)
        defer { Self.tearDownTelemetry() }
        // Sheet opened for httpbin.org, but the named tab was navigated to pie.dev while open.
        tabManager.selectedTab = makeTab(urlString: "https://pie.dev/target")
        let subject = createSubject()

        try selectSavedLogin(
            on: subject,
            capturedTabURL: URL(string: "https://httpbin.org")!,
            login: makeLogin(origin: "https://httpbin.org")
        )

        XCTAssertNil(GleanMetrics.Logins.autofilled.testGetValue(),
                     "Cross-origin selection should not inject the credential")
    }

    func testSavedLoginSelection_whenSelectedTabSameHostDifferentScheme_doesNotFill() throws {
        Self.setupTelemetry(with: profile)
        defer { Self.tearDownTelemetry() }
        tabManager.selectedTab = makeTab(urlString: "http://httpbin.org/login")
        let subject = createSubject()

        try selectSavedLogin(
            on: subject,
            capturedTabURL: URL(string: "https://httpbin.org")!,
            login: makeLogin(origin: "https://httpbin.org")
        )

        XCTAssertNil(GleanMetrics.Logins.autofilled.testGetValue(),
                     "http/https origin mismatch should not inject the credential")
    }

    private func selectSavedLogin(
        on subject: CredentialAutofillCoordinator,
        capturedTabURL: URL,
        login: MozillaAppServices.Login
    ) throws {
        subject.showSavedLoginAutofill(tabURL: capturedTabURL, currentRequestId: "req-1", field: .username)
        let bottomSheet = try XCTUnwrap(router.presentedViewController as? BottomSheetViewController)
        bottomSheet.loadViewIfNeeded()
        let hostingController = try XCTUnwrap(
            bottomSheet.children.first as? SelfSizingHostingController<LoginAutofillView>
        )
        hostingController.rootView.viewModel.onLoginCellTap(login)

        // Loading sheet schedules SwiftUI render that reads Environment(\.themeManager),
        // which resolves ThemeManager from AppContainer. Flush that render while dependencies
        // are still registered, so it can't fire during teardown after container is reset.
        let drained = expectation(description: "main queue finished")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1.0)
    }

    private func makeTab(urlString: String) -> Tab {
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: urlString)
        return tab
    }

    private func makeLogin(origin: String) -> MozillaAppServices.Login {
        return MozillaAppServices.Login(
            id: "test-id",
            timesUsed: 1,
            timeCreated: 0,
            timeLastUsed: 0,
            timePasswordChanged: 0,
            timeLastBreachAlertDismissed: nil,
            origin: origin,
            httpRealm: nil,
            formActionOrigin: nil,
            usernameField: "",
            passwordField: "",
            password: "test",
            username: "test"
        )
    }

    private func createSubject() -> CredentialAutofillCoordinator {
        let subject = CredentialAutofillCoordinator(
            profile: profile,
            router: router,
            parentCoordinator: parentCoordinator,
            creditCardProvider: creditCardProvider,
            tabManager: tabManager
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
