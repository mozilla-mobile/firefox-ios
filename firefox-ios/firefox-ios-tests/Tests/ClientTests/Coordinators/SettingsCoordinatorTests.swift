// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client
import SwiftUI

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

    func testEmptyChildren_whenCreated() {
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

        subject.start(with: .browser)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is BrowsingSettingsViewController)
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

    func testAppIconSettingsRoute_showsAppIconSelectionPage() throws {
        let subject = createSubject()

        subject.start(with: .appIcon)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is UIHostingController<AppIconSelectionView>)
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

    func testParentCoordinatorDelegate_calledOpen50Tabs() {
        let subject = createSubject()
        subject.parentCoordinator = delegate

        subject.openDebugTestTabs(count: 50)

        XCTAssertEqual(delegate.openDebugTestTabsCalled, 1)
    }

    // MARK: - Settings VC
    func testDelegatesAreSet() {
        let subject = createSubject()

        XCTAssertNotNil(subject.settingsViewController?.settingsDelegate)
        XCTAssertNotNil(subject.settingsViewController?.parentCoordinator)
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

        subject.showPasswordManager(shouldShowOnboarding: false)

        XCTAssertTrue(subject.childCoordinators.first is PasswordManagerCoordinator)
    }

    func testShowQRCode_addsQRCodeChildCoordinator() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is QRCodeCoordinator)
    }

    func testShowQRCode_presentsQRCodeNavigationController() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()

        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is QRCodeNavigationController)
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

        let result = testCanHandleAndHandle(subject, route: .settings(section: .general))

        XCTAssertTrue(result)
    }

    func testHandleRouteOther_notHandled() {
        let subject = createSubject()

        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .downloads))

        XCTAssertFalse(result)
    }

    // MARK: - GeneralSettingsDelegate

    func testGeneralSettingsDelegate_pushedHome() {
        let subject = createSubject()

        subject.pressedHome()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is HomePageSettingViewController)
    }

    func testGeneralSettingsDelegate_pushedNewTab() {
        let subject = createSubject()

        subject.pressedNewTab()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is NewTabContentSettingsViewController)
    }

    func testGeneralSettingsDelegate_pushedSearchEngine() {
        let subject = createSubject()

        subject.pressedSearchEngine()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is SearchSettingsTableViewController)
    }

    func testGeneralSettingsDelegate_pushedSiri() {
        let subject = createSubject()

        subject.pressedSiri()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is SiriSettingsViewController)
    }

    func testGeneralSettingsDelegate_pushedToolbar() {
        let subject = createSubject()

        subject.pressedToolbar()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is SearchBarSettingsViewController)
    }

    func testGeneralSettingsDelegate_pushedTheme() {
        let subject = createSubject()

        subject.pressedTheme()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is ThemeSettingsController)
    }

    // MARK: - BrowsingSettingsDelegate

    func testBrowsingSettingsDelegate_pushedMailApp() {
        let subject = createSubject()

        subject.pressedMailApp()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is OpenWithSettingsViewController)
    }

    // MARK: - PrivacySettingsDelegate

    func testAutofillPasswordSettingsRoute_pushAutofillPassword() throws {
        let subject = createSubject()

        subject.pressedAutoFillsPasswords()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is AutoFillPasswordSettingsViewController)
    }

    func testPrivacySettingsDelegate_handleCreditCardRoute() {
        let subject = createSubject()
        subject.settingsViewController = mockSettingsVC

        subject.pressedCreditCard()

        XCTAssertEqual(mockSettingsVC.handleRouteCalled, 1)
        XCTAssertEqual(mockSettingsVC.savedRoute, .creditCard)
    }

    func testPrivacySettingsDelegate_pushedClearPrivateData() {
        let subject = createSubject()

        subject.pressedClearPrivateData()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is ClearPrivateDataTableViewController)
    }

    func testPrivacySettingsDelegate_pushedContentBlocked() {
        let subject = createSubject()

        subject.pressedContentBlocker()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is ContentBlockerSettingViewController)
    }

    func testPrivacySettingsDelegate_handlePasswordRoute() {
        let subject = createSubject()
        subject.settingsViewController = mockSettingsVC

        subject.pressedPasswords()

        XCTAssertEqual(mockSettingsVC.handleRouteCalled, 1)
        XCTAssertEqual(mockSettingsVC.savedRoute, .password)
    }

    func testPrivacySettingsDelegate_pushedNotifications() {
        let subject = createSubject()

        subject.pressedNotifications()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is NotificationsSettingsViewController)
    }

    func testPrivacySettingsDelegate_pushedContentWithURL() {
        let subject = createSubject()

        subject.askedToOpen(url: URL(string: "www.mozilla.com")!, withTitle: nil)

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is SettingsContentViewController)
    }

    func testPrivacySettingsDelegate_pressedAddressAutofill() {
        let subject = createSubject()

        subject.pressedAddressAutofill()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is AddressAutofillSettingsViewController)
    }

    // MARK: AccountSettingsDelegate

    func testAccountSettingsDelegate_pushedConnectSetting() {
        let subject = createSubject()

        subject.pressedConnectSetting()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is FirefoxAccountSignInViewController)
    }

    func testAccountSettingsDelegate_pushedAdvancedAccountSetting() {
        let subject = createSubject()

        subject.pressedAdvancedAccountSetting()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is AdvancedAccountSettingViewController)
    }

    func testAccountSettingsDelegate_pushedToShowSyncContent() {
        let subject = createSubject()

        subject.pressedToShowSyncContent()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is SyncContentSettingsViewController)
    }

    func testAccountSettingsDelegate_pushedToShowFirefoxAccount() {
        let subject = createSubject()

        subject.pressedToShowFirefoxAccount()

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is FirefoxAccountSignInViewController)
    }

    // MARK: SupportSettingsDelegate

    func testSupportSettingsDelegate_openSupportPageInNewTab() {
        let subject = createSubject()
        let expectedURL = URL(string: "www.mozilla.com")!
        subject.parentCoordinator = delegate

        subject.pressedOpenSupportPage(url: expectedURL)

        XCTAssertEqual(delegate.didFinishSettingsCalled, 1)
        XCTAssertEqual(delegate.openURLinNewTabCalled, 1)
        XCTAssertEqual(delegate.savedURL, expectedURL)
    }

    // MARK: - AboutSettingsDelegate

    func testPressedLicense() {
        let subject = createSubject()

        subject.pressedLicense(url: URL(string: "https://firefox.com")!,
                               title: NSAttributedString(string: "Firefox"))

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is SettingsContentViewController)
    }

    func testPressedYourRights() {
        let subject = createSubject()

        subject.pressedYourRights(url: URL(string: "https://firefox.com")!,
                                  title: NSAttributedString(string: "Firefox"))

        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(mockRouter.pushedViewController is SettingsContentViewController)
    }

    // MARK: - Helper
    func createSubject() -> SettingsCoordinator {
        let subject = SettingsCoordinator(
            router: mockRouter,
            wallpaperManager: wallpaperManager,
            tabManager: MockTabManager(),
            gleanUsageReportingMetricsService: MockGleanUsageReportingMetricsService(
                profile: MockProfile()
            )
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func testCanHandleAndHandle(_ subject: Coordinator, route: Route) -> Bool {
        let result = subject.canHandle(route: route)
        subject.handle(route: route)
        return result
    }
}

// MARK: - MockSettingsCoordinatorDelegate
class MockSettingsCoordinatorDelegate: SettingsCoordinatorDelegate {
    var savedURL: URL?
    var openURLinNewTabCalled = 0
    var didFinishSettingsCalled = 0
    var openDebugTestTabsCalled = 0

    func openURLinNewTab(_ url: URL) {
        savedURL = url
        openURLinNewTabCalled += 1
    }

    func didFinishSettings(from coordinator: SettingsCoordinator) {
        didFinishSettingsCalled += 1
    }

    func openDebugTestTabs(count: Int) {
        openDebugTestTabsCalled += 1
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
