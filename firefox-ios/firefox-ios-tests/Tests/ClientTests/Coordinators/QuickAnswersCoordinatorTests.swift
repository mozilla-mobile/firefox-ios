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
    private let testURL = URL(string: "https://example.com")!
    private let testQuery = "test search query"

    override func setUp() async throws {
        try await super.setUp()
        router = MockRouter(navigationController: MockNavigationController())
        parentCoordinator = MockParentCoordinator()
        themeManager = MockThemeManager()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        router = nil
        parentCoordinator = nil
        themeManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_start_presentsViewController() {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is QuickAnswersViewController)
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

    // MARK: - Helper Methods
    private func setupNimbus(model: Client.QuickAnswersModel) {
        FxNimbus.shared.features.quickAnswersFeature.with { _, _ in
            QuickAnswersFeature(enabled: true, model: model)
        }
    }

    private func createSubject(
        prefs: Prefs = MockProfilePrefs(),
        onNavigate: @escaping (QuickAnswersNavigationType) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuickAnswersCoordinator {
        let subject = QuickAnswersCoordinator(
            parentCoordinatorDelegate: parentCoordinator,
            prefs: prefs,
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            router: router,
            transitionType: .crossDissolve(sourceRect: .zero),
            onNavigate: onNavigate
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
