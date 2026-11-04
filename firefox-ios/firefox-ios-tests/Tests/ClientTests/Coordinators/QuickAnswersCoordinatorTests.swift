// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import QuickAnswersKit
import Shared

@testable import Client

@MainActor
final class QuickAnswersCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var parentCoordinator: MockParentCoordinator!
    private var themeManager: MockThemeManager!
    private var featureFlagsProvider: MockNimbusFeatureFlags!
    private let testURL = URL(string: "https://example.com")!
    private let testQuery = "test search query"
    private let testTitle = "Test title"

    override func setUp() async throws {
        try await super.setUp()
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
        themeManager = MockThemeManager()
        featureFlagsProvider = MockNimbusFeatureFlags()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        router = nil
        parentCoordinator = nil
        themeManager = nil
        featureFlagsProvider = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_start_presentsViewControllerInNavigationController() throws {
        let subject = createSubject()

        subject.start()

        let navigationController = try XCTUnwrap(router.presentedViewController as? UINavigationController)
        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(navigationController.viewControllers.first is QuickAnswersViewController)
    }

    func test_start_withCompletion_passesItToRouterPresent() {
        let subject = createSubject()
        var didCallCompletion = false

        subject.start { didCallCompletion = true }
        router.savedCompletion?()

        XCTAssertTrue(didCallCompletion)
    }

    func test_dismissQuickAnswers_dismissesControllerAndNotifiesParent() {
        let subject = createSubject()

        subject.dismissQuickAnswers(with: nil)

        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_dismissQuickAnswers_withNilNavigationType_doesntCallCallback() {
        var didCallCallback = false
        let subject = createSubject(onNavigate: { _ in
            didCallCallback = true
        })

        subject.dismissQuickAnswers(with: nil)

        XCTAssertFalse(didCallCallback, "The onNavigate closure should not have been called")
    }

    func test_dismissQuickAnswers_withNavigateToURLType_callsCallback() {
        var didCallCallback = false
        let subject = createSubject(onNavigate: { type in
            XCTAssertEqual(type, .url(self.testURL))
            didCallCallback = true
        })

        subject.dismissQuickAnswers(with: .url(testURL))

        XCTAssertTrue(didCallCallback, "The onNavigate closure should have been called")
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_dismissQuickAnswers_withNavigateToSearchResultType_callsCallback() {
        var didCallCallback = false
        let subject = createSubject(onNavigate: { type in
            XCTAssertEqual(type, .searchResult(self.testQuery))
            didCallCallback = true
        })

        subject.dismissQuickAnswers(with: .searchResult(testQuery))

        XCTAssertTrue(didCallCallback, "The onNavigate closure should have been called")
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_dismissQuickAnswers_withNewTabType_callsCallback() {
        var navigationTypes = [QuickAnswersNavigationType]()
        let subject = createSubject(onNavigate: { navigationTypes.append($0) })

        subject.dismissQuickAnswers(with: .newTab(testURL, isPrivate: true))

        XCTAssertEqual(navigationTypes, [.newTab(testURL, isPrivate: true)])
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
        XCTAssertEqual(router.dismissCalled, 1)
    }

    func test_parkQuickAnswers_navigatesCallsOnParkDismissesAndFinishes() {
        var events = [String]()
        router.onDismiss = { events.append("dismiss") }
        let subject = createSubject(
            onNavigate: { type in
                XCTAssertEqual(type, .url(self.testURL))
                events.append("navigate")
            },
            onPark: { events.append("park") }
        )

        subject.parkQuickAnswers(with: .url(testURL))

        XCTAssertEqual(events, ["navigate", "park", "dismiss"])
        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func test_dismissQuickAnswers_doesNotCallOnPark() {
        var didCallOnPark = false
        let subject = createSubject(onPark: { didCallOnPark = true })

        subject.dismissQuickAnswers(with: .url(testURL))

        XCTAssertFalse(didCallOnPark)
    }

    // MARK: - bookmarkCitation
    func test_bookmarkCitation_callsOnBookmarkWithURLAndTitle() {
        var bookmarks = [(url: URL, title: String)]()
        let subject = createSubject(onBookmark: { bookmarks.append(($0, $1)) })

        subject.bookmarkCitation(url: testURL, title: testTitle)

        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks.first?.url, testURL)
        XCTAssertEqual(bookmarks.first?.title, testTitle)
    }

    func test_bookmarkCitation_staysInQuickAnswers() {
        var didNavigate = false
        var didPark = false
        let subject = createSubject(onNavigate: { _ in didNavigate = true }, onPark: { didPark = true })

        subject.bookmarkCitation(url: testURL, title: testTitle)

        XCTAssertFalse(didNavigate)
        XCTAssertFalse(didPark)
        XCTAssertEqual(router.dismissCalled, 0)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 0)
    }

    // MARK: - resolvedModel
    func test_resolvedModel_withoutOverride_returnsNimbusModel() {
        setupNimbus(model: .liner)
        let subject = createSubject()

        XCTAssertEqual(subject.resolvedModel(), QuickAnswersKit.QuickAnswersModel.liner)
    }

    func test_resolvedModel_withOverride_returnsOverriddenModel() {
        setupNimbus(model: .liner)
        let prefs = MockProfilePrefs()
        prefs.setString(QuickAnswersKit.QuickAnswersModel.exa.rawValue,
                        forKey: PrefsKeys.QuickAnswers.modelOverride)
        let subject = createSubject(prefs: prefs)

        XCTAssertEqual(subject.resolvedModel(), QuickAnswersKit.QuickAnswersModel.exa)
    }

    func test_resolvedModel_withUnknownOverride_returnsNimbusModel() {
        setupNimbus(model: .liner)
        let prefs = MockProfilePrefs()
        prefs.setString("unknown-model", forKey: PrefsKeys.QuickAnswers.modelOverride)
        let subject = createSubject(prefs: prefs)

        XCTAssertEqual(subject.resolvedModel(), QuickAnswersKit.QuickAnswersModel.liner)
    }

    func test_resolvedFeature_withOptInRedesignEnabled_returnsFeatureWithResolvedModelAndRedesign() {
        setupNimbus(model: .liner)
        featureFlagsProvider.enabledFlags = [.quickAnswersOptInRedesign]
        let subject = createSubject()

        XCTAssertEqual(
            subject.resolvedFeature(),
            QuickAnswersKit.QuickAnswersFeature(
                model: .liner,
                isOptInRedesignEnabled: true,
                isFollowUpEnabled: false,
                isReturnToAnswerEnabled: false
            )
        )
    }

    func test_resolvedFeature_withOptInRedesignDisabled_returnsFeatureWithoutRedesign() {
        setupNimbus(model: .exa)
        let subject = createSubject()

        XCTAssertEqual(
            subject.resolvedFeature(),
            QuickAnswersKit.QuickAnswersFeature(
                model: .exa,
                isOptInRedesignEnabled: false,
                isFollowUpEnabled: false,
                isReturnToAnswerEnabled: false
            )
        )
    }

    func test_resolvedFeature_withFollowUpEnabled_returnsFeatureWithFollowUp() {
        setupNimbus(model: .exa)
        featureFlagsProvider.enabledFlags = [.quickAnswersFollowUp]
        let subject = createSubject()

        XCTAssertEqual(
            subject.resolvedFeature(),
            QuickAnswersKit.QuickAnswersFeature(
                model: .exa,
                isOptInRedesignEnabled: false,
                isFollowUpEnabled: true,
                isReturnToAnswerEnabled: false
            )
        )
    }

    func test_resolvedFeature_withReturnToAnswerEnabled_setsFlag() {
        setupNimbus(model: .exa)
        featureFlagsProvider.enabledFlags = [.quickAnswersReturnToAnswer]
        let subject = createSubject()

        XCTAssertEqual(
            subject.resolvedFeature(),
            QuickAnswersKit.QuickAnswersFeature(
                model: .exa,
                isOptInRedesignEnabled: false,
                isFollowUpEnabled: false,
                isReturnToAnswerEnabled: true
            )
        )
    }

    func test_resolvedFeature_withReturnToAnswerDisabled_doesNotSetFlag() {
        setupNimbus(model: .exa)
        let subject = createSubject()

        XCTAssertFalse(subject.resolvedFeature().isReturnToAnswerEnabled)
    }

    // MARK: - Helper Methods
    private func setupNimbus(model: Client.QuickAnswersModel) {
        FxNimbus.shared.features.quickAnswersFeature.with { _, _ in
            Client.QuickAnswersFeature(enabled: true, model: model)
        }
    }

    private func createSubject(
        prefs: Prefs = MockProfilePrefs(),
        onNavigate: @escaping (QuickAnswersNavigationType) -> Void = { _ in },
        onPark: @escaping () -> Void = {},
        onBookmark: @escaping (URL, String) -> Void = { _, _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuickAnswersCoordinator {
        let subject = QuickAnswersCoordinator(
            parentCoordinatorDelegate: parentCoordinator,
            prefs: prefs,
            sessionStorage: QuickAnswersSessionStorage(),
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            router: router,
            transitionType: .sourceReveal(sourceRect: .zero),
            featureFlagsProvider: featureFlagsProvider,
            onNavigate: onNavigate,
            onPark: onPark,
            onBookmark: onBookmark
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
