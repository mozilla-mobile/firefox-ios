// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Common

@testable import Client

@MainActor
class AccessoryViewProviderTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AppContainer.shared.reset()
    }

    func testReloadForStandardView_showsNoAutofillButton() {
        let subject = createSubject()
        subject.reloadViewFor(.standard)

        XCTAssertFalse(containsAutofillButton(subject))
    }

    func testReloadForCreditCardView_showsCreditCardButton() {
        let subject = createSubject()
        subject.reloadViewFor(.creditCard)

        XCTAssertTrue(containsIdentifier(
            AccessibilityIdentifiers.Browser.KeyboardAccessory.creditCardAutofillButton,
            in: subject
        ))
    }

    func testReloadForAddressView_showsAddressButton() {
        let subject = createSubject()
        subject.reloadViewFor(.address)

        XCTAssertTrue(containsIdentifier(
            AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton,
            in: subject
        ))
    }

    func testReloadForLoginView_showsLoginButton() {
        let subject = createSubject()
        subject.reloadViewFor(.login)

        XCTAssertTrue(containsIdentifier(
            AccessibilityIdentifiers.Autofill.footerPrimaryAction,
            in: subject
        ))
    }

    func testReloadForPasswordGeneratorView_showsPasswordGeneratorButton() {
        let subject = createSubject()
        subject.reloadViewFor(.passwordGenerator)

        XCTAssertTrue(containsIdentifier(
            AccessibilityIdentifiers.PasswordGenerator.keyboardButton,
            in: subject
        ))
    }

    func testReloadForRelayEmailMaskView_showsRelayMaskButton() {
        let subject = createSubject()
        subject.reloadViewFor(.relayEmailMask)

        XCTAssertTrue(containsIdentifier(
            AccessibilityIdentifiers.Browser.KeyboardAccessory.relayMaskAutofillButton,
            in: subject
        ))
    }

    func testReloadBackToStandardView_hidesPreviousAutofillButton() {
        let subject = createSubject()
        subject.reloadViewFor(.creditCard)
        subject.reloadViewFor(.standard)

        XCTAssertFalse(containsAutofillButton(subject))
    }

    func testHasContent_onPhone_isTrueWithoutAutofillItem() {
        let subject = createSubject(userInterfaceIdiom: .phone)
        subject.reloadViewFor(.standard)

        XCTAssertTrue(subject.hasContent)
    }

    func testHasContent_onPad_dependsOnAutofillItem() {
        let subject = createSubject(userInterfaceIdiom: .pad)

        subject.reloadViewFor(.standard)
        if #available(iOS 26.0, *) {
            XCTAssertFalse(subject.hasContent)
        } else {
            XCTAssertTrue(subject.hasContent)
        }

        subject.reloadViewFor(.login)
        XCTAssertTrue(subject.hasContent)
    }

    func testReloadViewFor_onPad_callsContentAvailabilityChangedOnlyOnChange() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Only iOS 26+ drops the iPad navigation buttons") }
        let subject = createSubject(userInterfaceIdiom: .pad)
        var callCount = 0
        subject.contentAvailabilityChanged = { callCount += 1 }

        subject.reloadViewFor(.standard)
        XCTAssertEqual(callCount, 0)

        subject.reloadViewFor(.relayEmailMask)
        XCTAssertEqual(callCount, 1)

        subject.reloadViewFor(.passwordGenerator)
        XCTAssertEqual(callCount, 1)

        subject.reloadViewFor(.standard)
        XCTAssertEqual(callCount, 2)
    }

    func testReloadViewFor_onPhone_neverCallsContentAvailabilityChanged() {
        let subject = createSubject(userInterfaceIdiom: .phone)
        var callCount = 0
        subject.contentAvailabilityChanged = { callCount += 1 }

        subject.reloadViewFor(.login)
        subject.reloadViewFor(.standard)

        XCTAssertEqual(callCount, 0)
    }

    // MARK: - Helpers

    private let autofillIdentifiers = [
        AccessibilityIdentifiers.Browser.KeyboardAccessory.creditCardAutofillButton,
        AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton,
        AccessibilityIdentifiers.Browser.KeyboardAccessory.relayMaskAutofillButton,
        AccessibilityIdentifiers.Autofill.footerPrimaryAction,
        AccessibilityIdentifiers.PasswordGenerator.keyboardButton
    ]

    private func createSubject(
        userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) -> AccessoryViewProvider {
        let subject = AccessoryViewProvider(windowUUID: .XCTestDefaultUUID, userInterfaceIdiom: userInterfaceIdiom)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func containsIdentifier(_ identifier: String, in subject: AccessoryViewProvider) -> Bool {
        subject.toolbarItems.contains { $0.accessibilityIdentifier == identifier }
    }

    private func containsAutofillButton(_ subject: AccessoryViewProvider) -> Bool {
        let identifiers = Set(subject.toolbarItems.compactMap { $0.accessibilityIdentifier })
        return !identifiers.isDisjoint(with: autofillIdentifiers)
    }
}
