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
    private var navigationHandler: MockNavigationHandler!
    private var service: MockTestQuickAnswersService!
    private var sessionStorage: QuickAnswersSessionStorage!
    private var pasteboardURLs: [URL]!
    private let citationURL = URL(string: "https://example.com")!

    override func setUp() async throws {
        try await super.setUp()
        navigationHandler = MockNavigationHandler()
        service = MockTestQuickAnswersService()
        sessionStorage = QuickAnswersSessionStorage()
        pasteboardURLs = []
    }

    override func tearDown() async throws {
        navigationHandler = nil
        service = nil
        sessionStorage = nil
        pasteboardURLs = nil
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
        subject.loadViewIfNeeded()
        try tapCitation(in: subject)
        let transitionDelegate = try XCTUnwrap(subject.transitioningDelegate)

        let dismissal = transitionDelegate.animationController?(forDismissed: subject)

        XCTAssertTrue(dismissal is ReturnToBrowserTransitionAnimator)
    }

    // MARK: - Return To Answer
    func test_viewWillAppear_withRestoredSession_doesNotStartFlow() {
        sessionStorage.latestSession = makeSnapshot()
        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)

        subject.loadViewIfNeeded()
        subject.beginAppearanceTransition(true, animated: false)
        subject.endAppearanceTransition()

        XCTAssertNil(findSubview(of: OptInView.self, in: subject.view))
    }

    func test_citationTap_withRestoredSessionAndFlagOn_parksInsteadOfDismissing() throws {
        sessionStorage.latestSession = makeSnapshot()
        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)
        subject.loadViewIfNeeded()

        try tapCitation(in: subject)

        XCTAssertEqual(navigationHandler.parkCallCount, 1)
        XCTAssertEqual(navigationHandler.lastParkedNavigationType, .url(citationURL))
        XCTAssertEqual(navigationHandler.dismissCallCount, 0)
    }

    func test_citationTap_withFlagOff_dismissesInsteadOfParking() throws {
        service.speechResults = [SpeechResult(text: "Question", isFinal: true)]
        service.searchResult = .success(makeSnapshot().result)
        let subject = createSubject(prefs: optInCompletedPrefs(), isReturnToAnswerEnabled: false)
        waitForResult(in: subject)

        try tapCitation(in: subject)

        XCTAssertEqual(navigationHandler.dismissCallCount, 1)
        XCTAssertEqual(navigationHandler.lastNavigationType, .url(citationURL))
        XCTAssertEqual(navigationHandler.parkCallCount, 0)
    }

    // MARK: - Citation menu
    func test_openInNewTabMenuAction_withFlagOn_parksWithNewTab() throws {
        sessionStorage.latestSession = makeSnapshot()
        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)
        subject.loadViewIfNeeded()

        try performMenuAction(at: 0, in: subject)

        XCTAssertEqual(navigationHandler.parkCallCount, 1)
        XCTAssertEqual(navigationHandler.lastParkedNavigationType, .newTab(citationURL, isPrivate: false))
        XCTAssertEqual(navigationHandler.dismissCallCount, 0)
        XCTAssertNotNil(sessionStorage.latestSession)
    }

    func test_openInNewTabMenuAction_withFlagOff_dismissesWithNewTab() throws {
        service.speechResults = [SpeechResult(text: "Question", isFinal: true)]
        service.searchResult = .success(makeSnapshot().result)
        let subject = createSubject(prefs: optInCompletedPrefs(), isReturnToAnswerEnabled: false)
        waitForResult(in: subject)

        try performMenuAction(at: 0, in: subject)

        XCTAssertEqual(navigationHandler.dismissCallCount, 1)
        XCTAssertEqual(navigationHandler.lastNavigationType, .newTab(citationURL, isPrivate: false))
        XCTAssertEqual(navigationHandler.parkCallCount, 0)
    }

    func test_openInNewPrivateTabMenuAction_withFlagOn_dismissesWithoutSavingSession() throws {
        sessionStorage.latestSession = makeSnapshot()
        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)
        subject.loadViewIfNeeded()

        try performMenuAction(at: 1, in: subject)

        XCTAssertEqual(navigationHandler.dismissCallCount, 1)
        XCTAssertEqual(navigationHandler.lastNavigationType, .newTab(citationURL, isPrivate: true))
        XCTAssertEqual(navigationHandler.parkCallCount, 0)
        XCTAssertNil(sessionStorage.latestSession)
    }

    func test_bookmarkMenuAction_bookmarksCitationWithoutLeavingQuickAnswers() throws {
        sessionStorage.latestSession = makeSnapshot()
        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)
        subject.loadViewIfNeeded()

        try performMenuAction(at: 2, in: subject)

        XCTAssertEqual(navigationHandler.bookmarkCallCount, 1)
        XCTAssertEqual(navigationHandler.lastBookmarkedURL, citationURL)
        XCTAssertEqual(navigationHandler.lastBookmarkedTitle, "Source")
        XCTAssertEqual(navigationHandler.dismissCallCount, 0)
        XCTAssertEqual(navigationHandler.parkCallCount, 0)
    }

    func test_copyLinkMenuAction_writesURLToPasteboardWithoutLeavingQuickAnswers() throws {
        sessionStorage.latestSession = makeSnapshot()
        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)
        subject.loadViewIfNeeded()

        try performMenuAction(at: 3, in: subject)

        XCTAssertEqual(pasteboardURLs, [citationURL])
        XCTAssertEqual(navigationHandler.dismissCallCount, 0)
        XCTAssertEqual(navigationHandler.parkCallCount, 0)
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
            notificationCenter: NotificationCenter.default,
            writeToPasteboard: { [weak self] in
                self?.pasteboardURLs.append($0)
            }
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

    private func optInCompletedPrefs() -> MockProfilePrefs {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.QuickAnswers.optInCompleted)
        return prefs
    }

    private func tapCitation(in subject: QuickAnswersViewController) throws {
        let sourceView = try XCTUnwrap(findSubview(of: QuickAnswersSourceView.self, in: subject.view))
        let row = try XCTUnwrap(findSubview(of: QuickAnswersSourceRow.self, in: sourceView))
        let tapGesture = try XCTUnwrap(row.gestureRecognizers?.first { $0 is UITapGestureRecognizer })
        _ = sourceView.perform(NSSelectorFromString("didTapRow:"), with: tapGesture)
    }

    private func waitForResult(in subject: QuickAnswersViewController) {
        subject.loadViewIfNeeded()
        subject.beginAppearanceTransition(true, animated: false)
        subject.endAppearanceTransition()
        let resultShown = expectation(for: NSPredicate { [weak subject] _, _ in
            guard let subject else { return false }
            return self.findSubview(of: QuickAnswersSourceRow.self, in: subject.view) != nil
        }, evaluatedWith: nil)
        wait(for: [resultShown], timeout: 2.0)
    }

    private func performMenuAction(at index: Int, in subject: QuickAnswersViewController) throws {
        let sourceView = try XCTUnwrap(findSubview(of: QuickAnswersSourceView.self, in: subject.view))
        let row = try XCTUnwrap(findSubview(of: QuickAnswersSourceRow.self, in: sourceView))
        let interaction = try XCTUnwrap(row.interactions.first as? UIContextMenuInteraction)
        let configuration = try XCTUnwrap(
            sourceView.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero)
        )
        let menu = try XCTUnwrap(configuration.actionProvider?([]))
        let action = try XCTUnwrap(menu.children[index] as? UIAction)
        UIButton().sendAction(action)
    }

    private func findSubview<T: UIView>(of type: T.Type, in view: UIView) -> T? {
        if let match = view as? T { return match }
        for subview in view.subviews {
            if let match = findSubview(of: type, in: subview) { return match }
        }
        return nil
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
        citationMenu: .mock,
        closeAccessibilityLabel: "Close",
        appName: "Firefox"
    )
}

extension QuickAnswersViewConfiguration.CitationMenuStrings {
    static let mock = QuickAnswersViewConfiguration.CitationMenuStrings(
        openInNewTab: "Open in New Tab",
        openInNewPrivateTab: "Open in New Private Tab",
        bookmarkLink: "Bookmark Link",
        copyLink: "Copy Link",
        shareLink: "Share Link"
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
