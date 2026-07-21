// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class NativeErrorRegularContentViewTests: XCTestCase {
    func test_configure_hidesWaybackButtonByDefault() {
        let subject = createSubject()
        subject.configure(showWaybackButton: false)
        XCTAssertTrue(subject.waybackButton.isHidden)
    }

    func test_configure_showsWaybackButtonWhenRequested() {
        let subject = createSubject()
        subject.configure(showWaybackButton: true)
        XCTAssertFalse(subject.waybackButton.isHidden)
    }

    func test_configureWaybackButton_idleState_showsButtonHidesCard() {
        let subject = createSubject()
        subject.configure(showWaybackButton: true)
        subject.configureWaybackButton(state: .idle)
        XCTAssertFalse(subject.waybackButton.isHidden)
        XCTAssertTrue(subject.waybackErrorCard.isHidden)
        XCTAssertTrue(subject.waybackButton.isEnabled)
    }

    func test_configureWaybackButton_loadingState_disablesButton() {
        let subject = createSubject()
        subject.configure(showWaybackButton: true)
        subject.configureWaybackButton(state: .loading)
        XCTAssertFalse(subject.waybackButton.isHidden)
        XCTAssertTrue(subject.waybackErrorCard.isHidden)
        XCTAssertFalse(subject.waybackButton.isEnabled)
    }

    func test_configureWaybackButton_failedState_hidesButtonShowsCard() {
        let subject = createSubject()
        subject.configure(showWaybackButton: true)
        subject.configureWaybackButton(state: .failed)
        XCTAssertTrue(subject.waybackButton.isHidden)
        XCTAssertFalse(subject.waybackErrorCard.isHidden)
    }

    func test_configureWaybackButton_whenNotShowingWayback_staysHiddenRegardlessOfState() {
        let subject = createSubject()
        subject.configure(showWaybackButton: false)
        subject.configureWaybackButton(state: .idle)
        XCTAssertTrue(subject.waybackButton.isHidden)
        XCTAssertTrue(subject.waybackErrorCard.isHidden)
    }

    private func createSubject() -> NativeErrorRegularContentView {
        let view = NativeErrorRegularContentView()
        trackForMemoryLeaks(view)
        return view
    }
}
