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
    func testInit_withSourceRevealTransition_usesCustomPresentationAndTransitioningDelegate() {
        let subject = createSubject(transitionType: .sourceReveal(sourceRect: .zero))

        XCTAssertEqual(subject.modalPresentationStyle, .custom)
        XCTAssertTrue(subject.transitioningDelegate is SourceRevealTransitionAnimator)
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
            configFetcher: nil,
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
            stringsConfiguration: .mock,
            notificationCenter: NotificationCenter.default
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

extension QuickAnswersViewConfiguration {
    static let mock = QuickAnswersViewConfiguration(
        optIn: .init(
            title: "Title",
            description: "Description",
            learnMore: "Learn more",
            continueButton: "Continue"
        ),
        optInRedesign: .mock,
        contentView: .init(
            placeholder: "Ask anything",
            answering: "Answering",
            footerFormat: "Powered by %@",
            sources: "Sources",
            aboutYourPrivacy: "About Your Privacy",
            answerHeader: "Quick Answer"
        ),
        privacyBanner: .init(
            title: "Private by Design",
            description: "Firefox doesn’t store your audio or questions"
        ),
        errors: .mock,
        closeAccessibilityLabel: "Close",
        appName: "Firefox"
    )
}

extension QuickAnswersViewConfiguration.OptInRedesignStrings {
    static let mock = QuickAnswersViewConfiguration.OptInRedesignStrings(
        title: "Try Quick Answers",
        description: "Description",
        nothingGetsSavedTitle: "Nothing Gets Saved",
        nothingGetsSavedDescription: "Nothing Gets Saved Description",
        privateByDesignTitle: "Private By Design",
        privateByDesignDescription: "Private By Design Description",
        noTrainingTitle: "No Training",
        noTrainingDescription: "No Training Description",
        learnMore: "Learn more",
        continueButton: "Continue"
    )
}
