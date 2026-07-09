// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import XCTest
import Common
import Shared
import TestKit

@MainActor
final class QuickAnswersViewControllerTests: XCTestCase {
    func testInit_withCrossDissolveTransition_usesCustomPresentationAndTransitioningDelegate() {
        let subject = createSubject(transitionType: .crossDissolve(sourceRect: .zero))

        XCTAssertEqual(subject.modalPresentationStyle, .custom)
        XCTAssertTrue(subject.transitioningDelegate is CrossDissolveTransitionAnimator)
    }

    func testInit_withFormSheetTransition_usesFormSheetPresentationAndNoTransitioningDelegate() {
        let subject = createSubject(transitionType: .formSheet)

        XCTAssertEqual(subject.modalPresentationStyle, .formSheet)
        XCTAssertNil(subject.transitioningDelegate)
    }

    // MARK: - Helper
    private func createSubject(
        transitionType: QuickAnswersTransitionType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuickAnswersViewController {
        let viewModel = QuickAnswersViewModel(
            prefs: MockProfilePrefs(),
            telemetry: MockQuickAnswersTelemetry(),
            makeService: { _, _ in
                MockTestQuickAnswersService()
            }
        )
        let subject = QuickAnswersViewController(
            navigationHandler: MockNavigationHandler(),
            viewModel: viewModel,
            transitionType: transitionType,
            windowUUID: .XCTestDefaultUUID,
            themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
            learnMoreURL: nil,
            notificationCenter: NotificationCenter.default
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
