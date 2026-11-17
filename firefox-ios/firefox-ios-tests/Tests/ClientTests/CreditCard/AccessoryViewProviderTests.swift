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

    // MARK: - Helpers

    private let autofillIdentifiers = [
        AccessibilityIdentifiers.Browser.KeyboardAccessory.creditCardAutofillButton,
        AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton,
        AccessibilityIdentifiers.Browser.KeyboardAccessory.relayMaskAutofillButton,
        AccessibilityIdentifiers.Autofill.footerPrimaryAction,
        AccessibilityIdentifiers.PasswordGenerator.keyboardButton
    ]

    private func createSubject() -> AccessoryViewProvider {
        let subject = AccessoryViewProvider(windowUUID: .XCTestDefaultUUID)
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
