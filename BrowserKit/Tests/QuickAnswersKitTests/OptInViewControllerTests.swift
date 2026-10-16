// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import Common
import SwiftUI
import TestKit
import UIKit
import XCTest

@MainActor
final class OptInViewControllerTests: XCTestCase {
    private var dismissCallCount = 0

    override func setUp() {
        super.setUp()
        dismissCallCount = 0
    }

    override func tearDown() {
        dismissCallCount = 0
        super.tearDown()
    }

    // MARK: - init
    func test_init_isPresentedAsNonDismissableSheet() {
        let subject = createSubject()

        XCTAssertEqual(subject.modalPresentationStyle, .pageSheet)
        XCTAssertTrue(subject.isModalInPresentation)
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_embedsOptInSheetView() {
        let subject = createSubject()

        subject.loadViewIfNeeded()

        let hostingController = subject.children.first as? UIHostingController<OptInSheetView>
        XCTAssertNotNil(hostingController)
        XCTAssertEqual(hostingController?.view.superview, subject.view)
    }

    // MARK: - presentationControllerDidDismiss
    func test_presentationControllerDidDismiss_whenSwipedAway_reportsDismissal() {
        let subject = createSubject()

        subject.presentationControllerDidDismiss(
            UIPresentationController(presentedViewController: subject, presenting: nil)
        )

        XCTAssertEqual(dismissCallCount, 1)
    }

    // MARK: - Helpers
    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OptInViewController {
        let subject = OptInViewController(
            windowUUID: .XCTestDefaultUUID,
            themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
            strings: .mock,
            closeAccessibilityLabel: "Close",
            onContinue: {},
            onLearnMore: {},
            onDismiss: { [weak self] in self?.dismissCallCount += 1 }
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
