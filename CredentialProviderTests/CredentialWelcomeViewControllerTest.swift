// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import CredentialProvider

final class CredentialWelcomeViewControllerTest: XCTestCase {
    var delegate: MockCredentialWelcomeViewControllerDelegate!
    override func setUp() {
        super.setUp()
        delegate = MockCredentialWelcomeViewControllerDelegate!
    }

    override func tearDown() {
        super.tearDown()
        delegate = nil
    }

    func testDelegateCancelButtonTapped_calledWhenTapped() {
        let subject = CredentialWelcomeViewController()
        subject.delegate = delegate
        subject.cancelButtonTapped(UIButton())

        XCTAssertEqual(delegate.didCancelCallCount, 1)
    }

    func testDelegateCancelButtonTapped_calledWhenTapped() {
        let subject = CredentialWelcomeViewController()
        subject.delegate = delegate
        subject.proceedButtonTapped(UIButton())

        XCTAssertEqual(delegate.didCancelCallCount, 1)
    }
}

// MARK: - CredentialWelcomeViewControllerDelegate
class MockCredentialWelcomeViewControllerDelegate: CredentialWelcomeViewControllerDelegate {
    var didCancelCallCount = 0
    var didProceedCallCount = 0

    func credentialWelcomeViewControllerDidCancel() {
        didCancelCallCount += 1
    }

    func credentialWelcomeViewControllerDidProceed() {
        didProceedCallCount += 1
    }
}
