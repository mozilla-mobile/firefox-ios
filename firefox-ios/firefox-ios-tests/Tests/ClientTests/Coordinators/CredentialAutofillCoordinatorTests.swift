// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import MozillaAppServices
import Storage
import SwiftUI
import XCTest

@testable import Client

final class CredentialAutofillCoordinatorTests: XCTestCase {
    private var profile: MockProfile!
    private var router: MockRouter!
    private var parentCoordinator: MockBrowserCoordinator!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        router = MockRouter(navigationController: UINavigationController())
        parentCoordinator = MockBrowserCoordinator()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
        router = nil
        parentCoordinator = nil
        DependencyHelperMock().reset()
    }

    func testShowPassCodeController() {
        let subject = createSubject()

        subject.showPassCodeController()

        XCTAssertTrue(router.presentedViewController is DevicePasscodeRequiredViewController)
        XCTAssertEqual(router.presentCalled, 1)
    }

    func testShowCreditCardAutofill() {
        let subject = createSubject()

        subject.showCreditCardAutofill(
            creditCard: nil,
            decryptedCard: nil,
            viewType: .save,
            frame: nil,
            alertContainer: UIView()
        )

        XCTAssertTrue(router.presentedViewController is BottomSheetViewController)
        XCTAssertEqual(router.presentCalled, 1)
    }

    @MainActor
    func testShowSavedLoginAutofill_PresentsLoginAutofillView() {
        let subject = createSubject()

        let testURL = URL(string: "https://example.com")!
        let currentRequestId = "testRequestID"
        let field = FocusFieldType.password

        subject.showSavedLoginAutofill(tabURL: testURL, currentRequestId: currentRequestId, field: field)

        XCTAssertTrue(router.presentedViewController is BottomSheetViewController)
        XCTAssertEqual(router.presentCalled, 1)
    }

    @MainActor
    func testShowSavedLoginAutofill_didTapManageLogins_callDidFinish() {
        let subject = createSubject()

        let testURL = URL(string: "https://example.com")!
        let currentRequestId = "testRequestID"
        let field = FocusFieldType.password

        subject.showSavedLoginAutofill(tabURL: testURL, currentRequestId: currentRequestId, field: field)

        if let bottomSheetViewController = router.presentedViewController as? BottomSheetViewController {
            bottomSheetViewController.loadViewIfNeeded()
            if let hostingViewController = bottomSheetViewController.children.first(where: {
                $0 is UIHostingController<LoginAutofillView>
            }) as? UIHostingController<LoginAutofillView> {
                hostingViewController.rootView.viewModel.manageLoginInfoAction()
                XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
            } else {
                XCTFail("The BottomSheetViewController has to contains a UIHostingController as child")
            }
        } else {
            XCTFail("A BottomSheetViewController has to be presented")
        }
    }

    @MainActor
    func testShowSavedLoginAutofill_didTapLoginFill_callDidFinish() {
        let subject = createSubject()

        let testURL = URL(string: "https://example.com")!
        let currentRequestId = "testRequestID"
        let field = FocusFieldType.password

        subject.showSavedLoginAutofill(tabURL: testURL, currentRequestId: currentRequestId, field: field)

        if let bottomSheetViewController = router.presentedViewController as? BottomSheetViewController {
            bottomSheetViewController.loadViewIfNeeded()
            if let hostingViewController = bottomSheetViewController.children.first(where: {
                $0 is UIHostingController<LoginAutofillView>
            }) as? UIHostingController<LoginAutofillView> {
                hostingViewController.rootView.viewModel.onLoginCellTap(
                    EncryptedLogin(
                        credentials: URLCredential(
                            user: "test",
                            password: "doubletest",
                            persistence: .permanent
                        ),
                        protectionSpace: URLProtectionSpace.fromOrigin("https://test.com")
                    )
                )
                XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
            } else {
                XCTFail("The BottomSheetViewController has to contains a UIHostingController as child")
            }
        } else {
            XCTFail("A BottomSheetViewController has to be presented")
        }
    }

    func testShowCreditCardAutofill_didTapYesButton_callDidFinish() {
        let subject = createSubject()

        subject.showCreditCardAutofill(
            creditCard: nil,
            decryptedCard: nil,
            viewType: .save,
            frame: nil,
            alertContainer: UIView()
        )

        if let bottomSheetViewController = router.presentedViewController as? BottomSheetViewController {
            bottomSheetViewController.loadViewIfNeeded()
            if let creditCardViewController = bottomSheetViewController.children.first(where: {
                $0 is CreditCardBottomSheetViewController
            }) as? CreditCardBottomSheetViewController {
                creditCardViewController.didTapYesClosure?(nil)
                XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
            } else {
                XCTFail("The BottomSheetViewController has to contains a CreditCardBottomSheetViewController as child")
            }
        } else {
            XCTFail("A BottomSheetViewController has to be presented")
        }
    }

    func testShowCreditCardAutofill_didTapCreditCardFill_callDidFinish() {
        let subject = createSubject()

        subject.showCreditCardAutofill(
            creditCard: nil,
            decryptedCard: nil,
            viewType: .save,
            frame: nil,
            alertContainer: UIView()
        )

        if let bottomSheetViewController = router.presentedViewController as? BottomSheetViewController {
            bottomSheetViewController.loadViewIfNeeded()
            if let creditCardViewController = bottomSheetViewController.children.first(where: {
                $0 is CreditCardBottomSheetViewController
            }) as? CreditCardBottomSheetViewController {
                creditCardViewController.didSelectCreditCardToFill?(UnencryptedCreditCardFields())
                XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
            } else {
                XCTFail("The BottomSheetViewController has to contains a CreditCardBottomSheetViewController as child")
            }
        } else {
            XCTFail("A BottomSheetViewController has to be presented")
        }
    }

    func testShowCreditCardAutofill_didTapManageCards_callDidFinish() {
        let subject = createSubject()

        subject.showCreditCardAutofill(
            creditCard: nil,
            decryptedCard: nil,
            viewType: .save,
            frame: nil,
            alertContainer: UIView()
        )

        if let bottomSheetViewController = router.presentedViewController as? BottomSheetViewController {
            bottomSheetViewController.loadViewIfNeeded()
            if let creditCardViewController = bottomSheetViewController.children.first(where: {
                $0 is CreditCardBottomSheetViewController
            }) as? CreditCardBottomSheetViewController {
                creditCardViewController.didTapManageCardsClosure?()
                XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
            } else {
                XCTFail("The BottomSheetViewController has to contains a CreditCardBottomSheetViewController as child")
            }
        } else {
            XCTFail("A BottomSheetViewController has to be presented")
        }
    }

    private func createSubject() -> CredentialAutofillCoordinator {
        let subject = CredentialAutofillCoordinator(
            profile: profile,
            router: router,
            parentCoordinator: parentCoordinator,
            tabManager: MockTabManager()
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
