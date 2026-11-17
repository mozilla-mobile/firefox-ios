// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import UIKit
import XCTest

@testable import Client

@MainActor
final class NotificationCardCellTests: XCTestCase {
    func test_configure_embedsHostViewInContentView() throws {
        let subject = createSubject()

        configure(subject)

        let host = try XCTUnwrap(subject.host)
        XCTAssertTrue(subject.contentView.subviews.first === host.view)
    }

    func test_configure_calledTwice_embedsHostOnce() {
        let subject = createSubject()

        configure(subject)
        configure(subject)

        XCTAssertEqual(subject.contentView.subviews.count, 1)
    }

    func test_onEnable_callsEnableButtonAction() throws {
        let subject = createSubject()
        var enableCallCount = 0
        configure(subject, enableButtonAction: { enableCallCount += 1 })

        try XCTUnwrap(subject.host).rootView.onEnable()

        XCTAssertEqual(enableCallCount, 1)
    }

    func test_onClose_callsCloseButtonAction() throws {
        let subject = createSubject()
        var closeCallCount = 0
        configure(subject, closeButtonAction: { closeCallCount += 1 })

        try XCTUnwrap(subject.host).rootView.onClose()

        XCTAssertEqual(closeCallCount, 1)
    }

    // MARK: - Helpers

    private func createSubject() -> NotificationCardCell {
        let subject = NotificationCardCell(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
        trackForMemoryLeaks(subject)
        return subject
    }

    private func configure(_ subject: NotificationCardCell,
                           enableButtonAction: (() -> Void)? = nil,
                           closeButtonAction: (() -> Void)? = nil) {
        subject.configure(
            windowUUID: .XCTestDefaultUUID,
            themeManager: MockThemeManager(),
            enableButtonAction: enableButtonAction,
            closeButtonAction: closeButtonAction
        )
    }
}
