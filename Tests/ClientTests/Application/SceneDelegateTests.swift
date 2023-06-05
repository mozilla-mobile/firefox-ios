// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client

final class SceneDelegateTests: XCTestCase {
    var logger: MockLogger!
    var router: MockRouter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        self.logger = MockLogger()
        self.router = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        self.logger = nil
        self.router = nil
        UserDefaults.standard.set(false, forKey: PrefsKeys.NimbusFeatureTestsOverride)
    }

    func testCoordinatorBVC_notFound_logsAndNotNil() {
        let subject = SceneDelegate()
        subject.logger = logger

        XCTAssertNotNil(subject.coordinatorBrowserViewController)
        XCTAssertEqual(logger.savedLevel, .fatal)
        XCTAssertEqual(logger.savedMessage, "BrowserViewController couldn't be retrieved")
        XCTAssertEqual(logger.savedCategory, .lifecycle)
    }

    func testCoordinatorBVC_found_returnsProperInstance() throws {
        UserDefaults.standard.set(true, forKey: PrefsKeys.NimbusFeatureTestsOverride)
        let subject = SceneDelegate()
        subject.logger = logger
        let scene = UIApplication.shared.windows.first?.windowScene
        let sceneCoordinator = SceneCoordinator(scene: scene!)
        sceneCoordinator.router = router
        sceneCoordinator.launchBrowser()
        subject.sceneCoordinator = sceneCoordinator

        let expectedBVC = try XCTUnwrap(sceneCoordinator.childCoordinators[0] as? BrowserCoordinator).browserViewController
        XCTAssertEqual(subject.coordinatorBrowserViewController, expectedBVC)
    }
}
