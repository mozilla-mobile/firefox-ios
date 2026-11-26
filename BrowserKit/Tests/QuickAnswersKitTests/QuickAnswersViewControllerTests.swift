// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import XCTest
import Common
import ComponentLibrary
import Shared
import TestKit

@MainActor
final class QuickAnswersViewControllerTests: XCTestCase {
    private var navigationHandler: MockNavigationHandler!
    private var service: MockTestQuickAnswersService!
    private var sessionStorage: QuickAnswersSessionStorage!
    private let citationURL = URL(string: "https://example.com")!

    override func setUp() async throws {
        try await super.setUp()
        navigationHandler = MockNavigationHandler()
        service = MockTestQuickAnswersService()
        sessionStorage = QuickAnswersSessionStorage()
    }

    override func tearDown() async throws {
        navigationHandler = nil
        service = nil
        sessionStorage = nil
        try await super.tearDown()
    }

    func testInit_withSourceRevealTransition_usesCustomPresentationAndOptInTransitionAnimator() {
        let subject = createSubject(transitionType: .sourceReveal(sourceRect: .zero))

        XCTAssertEqual(subject.modalPresentationStyle, .custom)
        XCTAssertTrue(subject.transitioningDelegate is OptInTransitionAnimator)
    }

    func testInit_withSourceRevealTransition_fallsBackToReturnToBrowserTransitionAnimator() {
        let subject = createSubject(transitionType: .sourceReveal(sourceRect: .zero))

        let transitionAnimator = subject.transitioningDelegate as? OptInTransitionAnimator
        let returnAnimator = transitionAnimator?.fallback as? ReturnToBrowserTransitionAnimator
        XCTAssertNotNil(returnAnimator)
        XCTAssertTrue(returnAnimator?.fallback is SourceRevealTransitionAnimator)
    }

    func testInit_withReturnToAnswerTransition_usesCustomPresentationAndOptInTransitionAnimator() {
        let subject = createSubject(transitionType: .returnToAnswer)

        XCTAssertEqual(subject.modalPresentationStyle, .custom)
        XCTAssertTrue(subject.transitioningDelegate is OptInTransitionAnimator)
    }

    func testInit_withReturnToAnswerTransition_fallsBackToReturnToBrowserTransitionAnimatorWithoutFallback() {
        let subject = createSubject(transitionType: .returnToAnswer)

        let transitionAnimator = subject.transitioningDelegate as? OptInTransitionAnimator
        let returnAnimator = transitionAnimator?.fallback as? ReturnToBrowserTransitionAnimator
        XCTAssertNotNil(returnAnimator)
        XCTAssertNil(returnAnimator?.fallback)
    }

    func testInit_withReturnToAnswerTransition_returnsReturnAnimatorForPresentationAndDismissal() throws {
        let subject = createSubject(transitionType: .returnToAnswer)
        let transitionDelegate = try XCTUnwrap(subject.transitioningDelegate)

        let presentation = transitionDelegate.animationController?(
            forPresented: subject,
            presenting: subject,
            source: subject
        )
        let dismissal = transitionDelegate.animationController?(forDismissed: subject)

        XCTAssertTrue(presentation is ReturnToBrowserTransitionAnimator)
        XCTAssertTrue(dismissal is ReturnToBrowserTransitionAnimator)
    }

    // MARK: - Dismissal animator
    func test_dismissalAnimator_withSourceRevealAndNoParkedSession_isSourceRevealTransitionAnimator() throws {
        let subject = createSubject(transitionType: .sourceReveal(sourceRect: .zero))
        let transitionDelegate = try XCTUnwrap(subject.transitioningDelegate)

        let dismissal = transitionDelegate.animationController?(forDismissed: subject)

        XCTAssertTrue(dismissal is SourceRevealTransitionAnimator)
    }

    func test_dismissalAnimator_withSourceRevealAndParkedSession_isReturnToBrowserTransitionAnimator() throws {
        sessionStorage.latestSession = makeSnapshot()
        let subject = createSubject(
            transitionType: .sourceReveal(sourceRect: .zero),
            isReturnToAnswerEnabled: true,
            isReturningToAnswer: true
        )
        let transitionDelegate = try XCTUnwrap(subject.transitioningDelegate)

        let dismissal = transitionDelegate.animationController?(forDismissed: subject)

        XCTAssertTrue(dismissal is ReturnToBrowserTransitionAnimator)
    }

    // MARK: - makeOptInController
    func test_makeOptInController_isPresentedAsNonDismissableFormSheet() {
        let subject = createSubject()

        let controller = subject.makeOptInController()

        XCTAssertEqual(controller.modalPresentationStyle, .formSheet)
        XCTAssertTrue(controller.isModalInPresentation)
    }

    // MARK: - Helper
    private func createSubject(
        transitionType: QuickAnswersTransitionType = .sourceReveal(sourceRect: .zero),
        prefs: Prefs = MockProfilePrefs(),
        isReturnToAnswerEnabled: Bool = false,
        isReturningToAnswer: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuickAnswersViewController {
        let viewModel = QuickAnswersViewModel(
            prefs: prefs,
            sessionStorage: sessionStorage,
            isReturningToAnswer: isReturningToAnswer,
            telemetry: MockQuickAnswersTelemetry(),
            configFetcher: DefaultQuickAnswersConfigFetcher(
                feature: QuickAnswersFeature(
                    model: .exa,
                    isOptInRedesignEnabled: false,
                    isFollowUpEnabled: false,
                    isReturnToAnswerEnabled: isReturnToAnswerEnabled
                )
            ),
            makeService: { _, _, _ in
                self.service
            }
        )
        let subject = QuickAnswersViewController(
            navigationHandler: navigationHandler,
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

    private func makeSnapshot() -> QuickAnswersSessionSnapshot {
        return QuickAnswersSessionSnapshot(
            question: "Question",
            result: SearchResult(
                resultText: "Answer",
                sources: [SearchResult.Source(title: "Source", url: citationURL, thumbnailURL: nil, faviconURL: nil)]
            ),
            conversation: MockQuickAnswersConversation()
        )
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
        optInAccessibilityIdentifiers: .init(
            continueButton: "continueButton",
            learnMoreButton: "learnMoreButton",
            closeButton: "closeButton"
        ),
        contentView: .init(
            placeholder: "Listening, ask anything",
            followUpPlaceholder: "Listening, ask a follow-up",
            followUpButton: "Ask a Follow-Up",
            newQuestionButton: "Ask a New Question",
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
