// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class SettingsCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var wallpaperManager: WallpaperManagerMock!
    private var delegate: MockSettingsCoordinatorDelegate!
    private var mockSettingsVC: MockAppSettingsScreen!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        self.wallpaperManager = WallpaperManagerMock()
        self.delegate = MockSettingsCoordinatorDelegate()
        self.mockSettingsVC = MockAppSettingsScreen()
    }

    override func tearDown() {
        super.tearDown()
        self.mockRouter = nil
        self.wallpaperManager = nil
        self.delegate = nil
        self.mockSettingsVC = nil
        DependencyHelperMock().reset()
    }

    func testEmptyChilds_whenCreated() {
        let subject = createSubject()

        XCTAssertEqual(subject.childCoordinators.count, 0)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertNotNil(mockRouter.rootViewController as? AppSettingsTableViewController)
    }

    func testGeneralSettingsRoute_showsGeneralSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .general)

        XCTAssertEqual(mockRouter.pushCalled, 0)
        XCTAssertNil(mockRouter.pushedViewController)
    }

    func testNewTabSettingsRoute_showsNewTabSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .newTab)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is NewTabContentSettingsViewController)
    }

    func testHomepageSettingsRoute_showsHomepageSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .homePage)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is HomePageSettingViewController)
    }

    func testMailtoSettingsRoute_showsMailtoSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .mailto)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is OpenWithSettingsViewController)
    }

    func testSearchSettingsRoute_showsSearchSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .search)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is SearchSettingsTableViewController)
    }

    func testClearPrivateDataSettingsRoute_showsClearPrivateDataSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .clearPrivateData)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is ClearPrivateDataTableViewController)
    }

    func testFxaSettingsRoute_showsFxaSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .fxa)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is FirefoxAccountSignInViewController)
    }

    func testThemeSettingsRoute_showsThemeSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .theme)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is ThemeSettingsController)
    }

    func testWallpaperSettingsRoute_cannotBeShown_showsWallpaperSettingsPage() throws {
        wallpaperManager.canSettingsBeShown = false
        let subject = createSubject()

        subject.start(with: .wallpaper)

        XCTAssertEqual(mockRouter.pushCalled, 0)
        XCTAssertNil(mockRouter.pushedViewController)
    }

    func testWallpaperSettingsRoute_canBeShown_showsWallpaperSettingsPage() throws {
        wallpaperManager.canSettingsBeShown = true
        let subject = createSubject()

        subject.start(with: .wallpaper)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is WallpaperSettingsViewController)
    }

    func testContentBlockerSettingsRoute_showsContentBlockerSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .contentBlocker)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is ContentBlockerSettingViewController)
    }

    func testTabsSettingsRoute_showsTabsSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .tabs)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is TabsSettingsViewController)
    }

    func testToolbarSettingsRoute_showsToolbarSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .toolbar)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is SearchBarSettingsViewController)
    }

    func testTopSitesSettingsRoute_showsTopSitesSettingsPage() throws {
        let subject = createSubject()

        subject.start(with: .topSites)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is TopSitesSettingsViewController)
    }

    func testCreditCardSettingsRoute_showsGeneralSettingsPageForNow() throws {
        let subject = createSubject()

        subject.start(with: .creditCard)

        XCTAssertEqual(mockRouter.pushCalled, 0)
        XCTAssertNil(mockRouter.pushedViewController)
    }

    // MARK: - Delegate
    func testParentCoordinatorDelegate_calledWithURL() {
        let subject = createSubject()
        subject.parentCoordinator = delegate

        let expectedURL = URL(string: "www.mozilla.com")!
        subject.settingsOpenURLInNewTab(expectedURL)

        XCTAssertEqual(delegate.openURLinNewTabCalled, 1)
        XCTAssertEqual(delegate.savedURL, expectedURL)
    }

    func testParentCoordinatorDelegate_calledDidFinish() {
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.didFinish()

        XCTAssertEqual(delegate.didFinishSettingsCalled, 1)
    }

    // MARK: - Settings VC
    func testDelegatesAreSet() {
        let subject = createSubject()

        XCTAssertNotNil(subject.settingsViewController.settingsDelegate)
        XCTAssertNotNil(subject.settingsViewController.parentCoordinator)
    }

    func testHandleRouteCalled_whenCreditCardRouteIsSet() {
        let subject = createSubject()
        subject.settingsViewController = mockSettingsVC

        subject.start(with: .creditCard)

        XCTAssertEqual(mockSettingsVC.handleRouteCalled, 1)
        XCTAssertEqual(mockSettingsVC.savedRoute, .creditCard)
    }

    func testHandleRouteCalled_whenPasswordRouteIsSet() {
        let subject = createSubject()
        subject.settingsViewController = mockSettingsVC

        subject.start(with: .password)

        XCTAssertEqual(mockSettingsVC.handleRouteCalled, 1)
        XCTAssertEqual(mockSettingsVC.savedRoute, .password)
    }

    // MARK: - SettingsFlowDelegate
    func testShowDevicePasscode_showDevicePasscodeVC() {
        let subject = createSubject()

        subject.showDevicePassCode()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is DevicePasscodeRequiredViewController)
    }

    func testCreditCardSettings_showsCreditCardVC() {
        let subject = createSubject()

        subject.showCreditCardSettings()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is CreditCardSettingsViewController)
    }

    func testShowExperimentSettings_showsExperimentVC() {
        let subject = createSubject()

        subject.showExperiments()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is ExperimentsViewController)
    }

    func testPasswordSettings_showsPasswordListVC() {
        let subject = createSubject()

        subject.showPasswordList()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is PasswordManagerListViewController)
    }

    func testPasswordSettings_showsPasswordOnboardingVC() {
        let subject = createSubject()

        subject.showPasswordOnboarding()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is LoginOnboardingViewController)
    }

    func testDidFinishShowingSettings_callsDidFinish() {
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.didFinishShowingSettings()

        XCTAssertEqual(delegate.didFinishSettingsCalled, 1)
    }

    // MARK: - Handle route
    func testHandleRouteSettings_generalIsHandled() {
        let subject = createSubject()

        let result = subject.handle(route: .settings(section: .general))

        XCTAssertTrue(result)
    }

    func testHandleRouteOther_notHandled() {
        let subject = createSubject()

        let result = subject.handle(route: .homepanel(section: .downloads))

        XCTAssertFalse(result)
    }

    // MARK: - Helper
    func createSubject() -> SettingsCoordinator {
        let subject = SettingsCoordinator(router: mockRouter,
                                          wallpaperManager: wallpaperManager)
        trackForMemoryLeaks(subject)
        return subject
    }
}

// MARK: - MockSettingsCoordinatorDelegate
class MockSettingsCoordinatorDelegate: SettingsCoordinatorDelegate {
    var savedURL: URL?
    var openURLinNewTabCalled = 0
    var didFinishSettingsCalled = 0

    func openURLinNewTab(_ url: URL) {
        savedURL = url
        openURLinNewTabCalled += 1
    }

    func didFinishSettings(from coordinator: SettingsCoordinator) {
        didFinishSettingsCalled += 1
    }
}

// MARK: - MockAppSettingsScreen
class MockAppSettingsScreen: UIViewController, AppSettingsScreen {
    var settingsDelegate: SettingsDelegate?
    var parentCoordinator: SettingsFlowDelegate?

    var handleRouteCalled = 0
    var savedRoute: Route.SettingsSection?

    func handle(route: Route.SettingsSection) {
        handleRouteCalled += 1
        savedRoute = route
    }
}
