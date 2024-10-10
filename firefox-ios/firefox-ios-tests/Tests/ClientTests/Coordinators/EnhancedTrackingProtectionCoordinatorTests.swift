// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class EnhancedTrackingProtectionCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var profile: MockProfile!
    private var routeBuilder: RouteBuilder!
    private var tabManager: MockTabManager!
    private var glean: MockGleanWrapper!
    private var delegate: MockEnhancedTrackingProtectionCoordinatorDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        self.profile = MockProfile()
        self.routeBuilder = RouteBuilder()
        self.tabManager = MockTabManager()
        self.glean = MockGleanWrapper()
        self.delegate = MockEnhancedTrackingProtectionCoordinatorDelegate()
    }

    override func tearDown() {
        self.routeBuilder = nil
        self.mockRouter = nil
        self.profile = nil
        self.tabManager = nil
        self.glean = nil
        self.delegate = nil
        AppContainer.shared.reset()
        super.tearDown()
    }

    func testParentCoordinatorDelegate_calledWithPage() {
        let subject = createSubject()
        subject.parentCoordinator = delegate
        subject.settingsOpenPage(settings: .contentBlocker)

        XCTAssertEqual(delegate.settingsOpenPageCalled, 1)
        XCTAssertEqual(delegate.didFinishEnhancedTrackingProtectionCalled, 1)
    }

    func testParentCoordinatorDelegate_calledDidFinish() {
        let subject = createSubject()
        subject.parentCoordinator = delegate
        subject.didFinish()

        XCTAssertEqual(delegate.didFinishEnhancedTrackingProtectionCalled, 1)
    }

    func testEmptyChildren_whenCreated() {
        let subject = createSubject()
        XCTAssertEqual(subject.childCoordinators.count, 0)
    }

    func createSubject() -> EnhancedTrackingProtectionCoordinator {
        let subject = EnhancedTrackingProtectionCoordinator(router: mockRouter, tabManager: MockTabManager())
        trackForMemoryLeaks(subject)
        return subject
    }
}

// MARK: - MockSettingsCoordinatorDelegate
class MockEnhancedTrackingProtectionCoordinatorDelegate: EnhancedTrackingProtectionCoordinatorDelegate {
    var settingsOpenPageCalled = 0
    var didFinishEnhancedTrackingProtectionCalled = 0

    func settingsOpenPage(settings: Route.SettingsSection) {
        settingsOpenPageCalled += 1
    }

    func didFinishEnhancedTrackingProtection(from coordinator: EnhancedTrackingProtectionCoordinator) {
        didFinishEnhancedTrackingProtectionCalled += 1
    }
}
