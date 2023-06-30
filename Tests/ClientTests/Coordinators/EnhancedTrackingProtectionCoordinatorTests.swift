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

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        self.profile = MockProfile()
        self.routeBuilder = RouteBuilder()
        self.tabManager = MockTabManager()
        self.glean = MockGleanWrapper()
    }

    override func tearDown() {
        super.tearDown()
        self.routeBuilder = nil
        self.mockRouter = nil
        self.profile = nil
        self.tabManager = nil
        self.glean = nil
        AppContainer.shared.reset()
    }

    func testEmptyChilds_whenCreated() {
        let subject = createSubject()
        XCTAssertEqual(subject.childCoordinators.count, 0)
    }

    func createSubject() -> EnhancedTrackingProtectionCoordinator {
        let subject = EnhancedTrackingProtectionCoordinator(router: mockRouter)
        trackForMemoryLeaks(subject)
        return subject
    }
}
