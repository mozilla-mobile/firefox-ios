// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import ComponentLibrary
import XCTest

@testable import Client

@MainActor
final class CredentialAutofillCoordinatorTests: XCTestCase {
    private var profile: MockProfile!
    private var router: MockRouter!
    private var parentCoordinator: MockBrowserCoordinator!
    private var tabManager: MockTabManager!
    private var creditCardProvider: MockCreditCardProvider!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        tabManager = MockTabManager()
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockBrowserCoordinator()
        creditCardProvider = MockCreditCardProvider()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile, injectedTabManager: tabManager)
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        profile.shutdown()
        profile = nil
        router = nil
        parentCoordinator = nil
        tabManager = nil
        creditCardProvider = nil
        super.tearDown()
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
