// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import SnowplowTracker
import Common
@testable import Client
@testable import Ecosia

// MARK: - AnalyticsSpy

final class AnalyticsSpy: Analytics {

    // MARK: - AnalyticsSpy Properties to Capture Calls

    var installCalled = false
    override func install() {
        installCalled = true
    }

    var activityActionCalled: Analytics.Action.Activity?
    override func activity(_ action: Analytics.Action.Activity) {
        activityActionCalled = action
    }

    var bookmarksImportExportPropertyCalled: Analytics.Property.Bookmarks?
    override func bookmarksPerformImportExport(_ property: Analytics.Property.Bookmarks) {
        bookmarksImportExportPropertyCalled = property
    }

    var bookmarksEmptyLearnMoreClickedCalled = false
    override func bookmarksEmptyLearnMoreClicked() {
        bookmarksEmptyLearnMoreClickedCalled = true
    }

    var bookmarksImportEndedPropertyCalled: Analytics.Property.Bookmarks?
    override func bookmarksImportEnded(_ property: Analytics.Property.Bookmarks) {
        bookmarksImportEndedPropertyCalled = property
    }

    var menuClickItemCalled: Analytics.Label.Menu?
    var menuClickExpectation: XCTestExpectation?
    override func menuClick(_ item: Analytics.Label.Menu) {
        menuClickItemCalled = item
        DispatchQueue.main.async {
            self.menuClickExpectation?.fulfill()
        }
    }

    var menuShareContentCalled: Analytics.Property.ShareContent?
    override func menuShare(_ content: Analytics.Property.ShareContent) {
        menuShareContentCalled = content
    }

    var menuStatusItemCalled: Analytics.Label.MenuStatus?
    var menuStatusItemChangedTo: Bool?
    var menuStatusExpectation: XCTestExpectation?
    override func menuStatus(changed item: Analytics.Label.MenuStatus, to: Bool) {
        menuStatusItemCalled = item
        menuStatusItemChangedTo = to
        DispatchQueue.main.async {
            self.menuStatusExpectation?.fulfill()
        }
    }

    var introDisplayingPageCalled: Property.OnboardingPage?
    var introDisplayingIndexCalled: Int?
    override func introDisplaying(page: Property.OnboardingPage?, at index: Int) {
        introDisplayingPageCalled = page
        introDisplayingIndexCalled = index
    }

    var introClickLabelCalled: Label.Onboarding?
    var introClickPageCalled: Property.OnboardingPage?
    var introClickIndexCalled: Int?
    override func introClick(_ label: Label.Onboarding, page: Property.OnboardingPage?, index: Int) {
        introClickLabelCalled = label
        introClickPageCalled = page
        introClickIndexCalled = index
    }

    var navigationActionCalled: Action?
    var navigationLabelCalled: Label.Navigation?
    override func navigation(_ action: Action, label: Label.Navigation) {
        navigationActionCalled = action
        navigationLabelCalled = label
    }

    var navigationOpenNewsIdCalled: String?
    override func navigationOpenNews(_ id: String) {
        navigationOpenNewsIdCalled = id
    }

    var referralActionCalled: Action.Referral?
    var referralLabelCalled: Label.Referral?

    // Separate expectations for different referral actions
    var referralClickExpectation: XCTestExpectation?
    var referralSendExpectation: XCTestExpectation?

    override func referral(action: Action.Referral, label: Label.Referral? = nil) {
        referralActionCalled = action
        referralLabelCalled = label
        DispatchQueue.main.async {
            switch action {
            case .click:
                self.referralClickExpectation?.fulfill()
            case .send:
                self.referralSendExpectation?.fulfill()
            default:
                break
            }
        }
    }

    var ntpTopSiteActionCalled: Action.TopSite?
    var ntpTopSitePropertyCalled: Property.TopSite?
    var ntpTopSitePositionCalled: NSNumber?
    override func ntpTopSite(_ action: Action.TopSite, property: Property.TopSite, position: NSNumber? = nil) {
        ntpTopSiteActionCalled = action
        ntpTopSitePropertyCalled = property
        ntpTopSitePositionCalled = position
    }

    var clearAllPrivateDataSectionCalled: Property.SettingsPrivateDataSection?
    override func clearsDataFromSection(_ section: Analytics.Property.SettingsPrivateDataSection) {
        clearAllPrivateDataSectionCalled = section
    }
}

// MARK: - AnalyticsSpyTests

final class AnalyticsSpyTests: XCTestCase {

    // MARK: - Properties and Setup

    var analyticsSpy: AnalyticsSpy!
    var profileMock: MockProfile { MockProfile() }
    var tabManagerMock: TabManager {
        let mock = MockTabManager()
        mock.selectedTab = .init(profile: profileMock, windowUUID: .XCTestDefaultUUID)
        mock.selectedTab?.url = URL(string: "https://example.com")
        return mock
    }

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManagerMock, themeManager: EcosiaMockThemeManager())
        analyticsSpy = AnalyticsSpy()
        Analytics.shared = analyticsSpy
    }

    override func tearDown() {
        super.tearDown()
        analyticsSpy = nil
        Analytics.shared = Analytics()
    }

    // MARK: - AppDelegate Tests

    var appDelegate: AppDelegate { AppDelegate() }

    func testTrackLaunchAndInstallOnDidFinishLaunching() async {
        // Arrange
        XCTAssertNil(analyticsSpy.activityActionCalled)
        let application = await UIApplication.shared

        // Act
        _ = await appDelegate.application(application, didFinishLaunchingWithOptions: nil)

        waitForCondition(timeout: 3) { // Wait detached tasks until launch is called
            analyticsSpy.activityActionCalled == .launch
        }

        // Assert
        XCTAssertEqual(analyticsSpy.activityActionCalled, .launch)
        XCTAssertTrue(analyticsSpy.installCalled)
    }

    func testTrackResumeOnDidBecomeActive() async {
        // Arrange
        XCTAssertNil(analyticsSpy.activityActionCalled)
        let application = await UIApplication.shared

        // Act
        _ = await appDelegate.applicationDidBecomeActive(application)

        waitForCondition(timeout: 2) { // Wait detached tasks until resume is called
            analyticsSpy.activityActionCalled == .resume
        }

        // Assert
        XCTAssertEqual(analyticsSpy.activityActionCalled, .resume)
    }

    // MARK: - Bookmarks Tests

    var panel: LegacyBookmarksPanel {
        let viewModel = BookmarksPanelViewModel(profile: profileMock,
                                                bookmarksHandler: profileMock.places,
                                                bookmarkFolderGUID: "TestGuid")
        return LegacyBookmarksPanel(viewModel: viewModel, windowUUID: .XCTestDefaultUUID)
    }

    func testTrackImportClick() {
        // Arrange
        XCTAssertNil(analyticsSpy.bookmarksImportExportPropertyCalled)

        // Act
        panel.importBookmarksActionHandler()

        // Assert
        XCTAssertEqual(analyticsSpy.bookmarksImportExportPropertyCalled, .import, "Analytics should track bookmarks import.")
    }

    func testTrackExportClick() {
        // Arrange
        XCTAssertNil(analyticsSpy.bookmarksImportExportPropertyCalled)

        // Act
        panel.exportBookmarksActionHandler()

        // Assert
        XCTAssertEqual(analyticsSpy.bookmarksImportExportPropertyCalled, .export, "Analytics should track bookmarks export.")
    }

    func testTrackLearnMoreClick() {
        // Arrange
        let view = EmptyBookmarksView(initialBottomMargin: 0)
        XCTAssertFalse(analyticsSpy.bookmarksEmptyLearnMoreClickedCalled, "Analytics should not have tracked learn more click yet.")

        // Act
        view.onLearnMoreTapped()

        // Assert
        XCTAssertTrue(analyticsSpy.bookmarksEmptyLearnMoreClickedCalled, "Analytics should track bookmarks empty learn more click.")
    }

    // MARK: - Menu Tests

    var menuHelper: MainMenuActionHelper {
        MainMenuActionHelper(profile: profileMock,
                             tabManager: tabManagerMock,
                             buttonView: .init(),
                             toastContainer: .init(),
                             themeManager: MockThemeManager())
    }

    func testTrackMenuAction() {
        let testCases: [(Analytics.Label.Menu, String)] = [
            (.openInSafari, .localized(.openInSafari)),
            (.history, .LegacyAppMenu.AppMenuHistory),
            (.downloads, .LegacyAppMenu.AppMenuDownloads),
            (.zoom, String(format: .LegacyAppMenu.ZoomPageTitle, NumberFormatter.localizedString(from: NSNumber(value: 1), number: .percent))),
            (.findInPage, .LegacyAppMenu.AppMenuFindInPageTitleString),
            (.requestDesktopSite, .LegacyAppMenu.AppMenuViewDesktopSiteTitleString),
            (.copyLink, .LegacyAppMenu.AppMenuCopyLinkTitleString),
            (.help, .LegacyAppMenu.Help),
            (.customizeHomepage, .LegacyAppMenu.CustomizeHomePage),
            (.readingList, .LegacyAppMenu.ReadingList),
            (.bookmarks, .LegacyAppMenu.Bookmarks)
        ]

        for (label, title) in testCases {
            XCTContext.runActivity(named: "Menu action \(label.rawValue) is tracked") { _ in
                // Arrange
                analyticsSpy = AnalyticsSpy()
                Analytics.shared = analyticsSpy
                XCTAssertNil(analyticsSpy.menuClickItemCalled, "Analytics menuClickItemCalled should be nil before action.")
                tabManagerMock.selectedTab?.url = URL(string: "https://example.com")

                // Create expectation
                let expectation = self.expectation(description: "Analytics menuClick called with \(label.rawValue)")
                analyticsSpy.menuClickExpectation = expectation

                // Act
                menuHelper.getToolbarActions(navigationController: .init()) { actions in
                    let action = actions
                        .flatMap { $0 } // Flatten sections
                        .flatMap { $0.items } // Flatten items in sections
                        .first { $0.title == title }
                    if let action = action {
                        action.tapHandler!(action)
                    } else {
                        XCTFail("No action title with \(title) found")
                    }
                }

                // Wait for expectation
                wait(for: [expectation], timeout: 2)

                // Assert
                XCTAssertEqual(analyticsSpy.menuClickItemCalled, label, "Analytics should track menu click with label \(label.rawValue).")
            }
        }
    }

    func testTrackMenuShare() {
        let testCases: [(Analytics.Property.ShareContent, URL?)] = [
            (.ntp, URL(string: "file://example.com")),
            (.web, URL(string: "https://example.com")),
            (.ntp, nil)
        ]
        for (label, url) in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            XCTContext.runActivity(named: "Menu share \(label.rawValue) is tracked") { _ in
                XCTAssertNil(analyticsSpy.menuShareContentCalled)

                // Requires valid url to add action
                tabManagerMock.selectedTab?.url = url

                let action = menuHelper.getSharingAction().items.first
                if let action = action {
                    action.tapHandler!(action)
                } else {
                    XCTFail("No sharing action found for url \(url?.absoluteString ?? "nil")")
                }
            }
        }
    }

    func testTrackMenuStatus() {
        struct MenuStatusTestCase {
            let label: Analytics.Label.MenuStatus
            let value: Bool
            let title: String
        }

        let testCases: [MenuStatusTestCase] = [
            MenuStatusTestCase(label: .readingList, value: true, title: .ShareAddToReadingList),
            MenuStatusTestCase(label: .readingList, value: false, title: .LegacyAppMenu.RemoveReadingList),
            MenuStatusTestCase(label: .bookmark, value: true, title: .KeyboardShortcuts.AddBookmark),
            MenuStatusTestCase(label: .shortcut, value: true, title: .AddToShortcutsActionTitle),
            MenuStatusTestCase(label: .shortcut, value: false, title: .LegacyAppMenu.RemoveFromShortcuts)
        ]

        for testCase in testCases {
            XCTContext.runActivity(named: "Menu status change \(testCase.label.rawValue) to \(testCase.value) is tracked") { _ in
                // Arrange
                analyticsSpy = AnalyticsSpy()
                Analytics.shared = analyticsSpy
                XCTAssertNil(analyticsSpy.menuStatusItemCalled, "Analytics menuStatusItemCalled should be nil before action.")
                XCTAssertNil(analyticsSpy.menuStatusItemChangedTo, "Analytics menuStatusItemChangedTo should be nil before action.")
                tabManagerMock.selectedTab?.url = URL(string: "https://example.com")

                // Create expectation
                let expectation = self.expectation(description: "Analytics menuStatus called with \(testCase.label.rawValue) and \(testCase.value)")
                analyticsSpy.menuStatusExpectation = expectation

                // Act
                menuHelper.getToolbarActions(navigationController: .init()) { actions in
                    let action = actions
                        .flatMap { $0 } // Flatten sections
                        .flatMap { $0.items } // Flatten items in sections
                        .first { $0.title == testCase.title }
                    if let action = action {
                        action.tapHandler!(action)
                    } else {
                        XCTFail("No action title with \(testCase.title) found")
                    }
                }

                // Wait for expectation
                wait(for: [expectation], timeout: 2)

                // Assert
                XCTAssertEqual(analyticsSpy.menuStatusItemCalled, testCase.label, "Analytics should track menu status with label \(testCase.label.rawValue).")
                XCTAssertEqual(analyticsSpy.menuStatusItemChangedTo, testCase.value, "Analytics should track menu status changed to \(testCase.value).")
            }
        }
    }

    // MARK: - Onboarding / Welcome Tests

    func testWelcomeViewDidAppearTracksIntroDisplayingAndIntroClickStart() {
        // Arrange
        let welcome = makeWelcome()
        XCTAssertNil(analyticsSpy.introDisplayingPageCalled)
        XCTAssertNil(analyticsSpy.introDisplayingIndexCalled)

        // Act
        welcome.loadViewIfNeeded()
        welcome.viewDidAppear(false)

        // Assert
        XCTAssertEqual(analyticsSpy.introDisplayingPageCalled, .start, "Analytics should track intro displaying page as .start.")
        XCTAssertEqual(analyticsSpy.introDisplayingIndexCalled, 0, "Analytics should track intro displaying index as 0.")
    }

    func testWelcomeGetStartedTracksIntroClickNext() {
        // Arrange
        let welcome = makeWelcome()
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)

        // Act
        welcome.getStarted()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next, "Analytics should track intro click label as .next.")
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .start, "Analytics should track intro click page as .start.")
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 0, "Analytics should track intro click index as 0.")
    }

    func testWelcomeSkipTracksIntroClickSkip() {
        // Arrange
        let welcome = makeWelcome()
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)

        // Act
        welcome.skip()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .skip, "Analytics should track intro click label as .skip.")
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .start, "Analytics should track intro click page as .start.")
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 0, "Analytics should track intro click index as 0.")
    }

    // MARK: - Onboarding / Welcome Tour Tests

    func testWelcomeTourViewDidAppearTracksIntroDisplaying() {
        // Arrange
        let welcomeTour = makeWelcomeTour()
        XCTAssertNil(analyticsSpy.introDisplayingPageCalled)
        XCTAssertNil(analyticsSpy.introDisplayingIndexCalled)

        // Act
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)

        // Assert
        XCTAssertEqual(analyticsSpy.introDisplayingPageCalled, .greenSearch, "Analytics should track intro displaying page as .greenSearch.")
        XCTAssertEqual(analyticsSpy.introDisplayingIndexCalled, 1, "Analytics should track intro displaying index as 1.")
    }

    func testWelcomeTourNextTracksIntroClickNext() {
        // Arrange
        let welcomeTour = makeWelcomeTour()
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)

        // Act
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)
        welcomeTour.forward()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next, "Analytics should track intro click label as .next.")
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .greenSearch, "Analytics should track intro click page as .greenSearch.")
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 1, "Analytics should track intro click index as 1.")
    }

    func testWelcomeTourSkipTracksIntroClickSkip() {
        // Arrange
        let welcomeTour = makeWelcomeTour()
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)
        XCTAssertNil(analyticsSpy.introClickIndexCalled)

        // Act
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)
        welcomeTour.skip()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .skip, "Analytics should track intro click label as .skip.")
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .greenSearch, "Analytics should track intro click page as .greenSearch.")
        XCTAssertEqual(analyticsSpy.introClickIndexCalled, 1, "Analytics should track intro click index as 1.")
    }

    func testWelcomeTourTracksAnalyticsForAllPages() {
        // Arrange
        let welcomeTour = makeWelcomeTour()
        let pages: [Analytics.Property.OnboardingPage] = [
            .greenSearch,
            .profits,
            .action,
            .transparentFinances
        ]
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)

        for (index, page) in pages.enumerated() {
            // Reset analyticsSpy properties
            analyticsSpy.introDisplayingPageCalled = nil
            analyticsSpy.introDisplayingIndexCalled = nil

            if index < pages.count - 1 {
                // Act
                welcomeTour.forward()

                // Assert
                XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next, "Analytics should track intro click label as .next.")
                XCTAssertEqual(analyticsSpy.introClickPageCalled, page, "Analytics should track intro click page as \(page).")
                XCTAssertEqual(analyticsSpy.introClickIndexCalled, index + 1, "Analytics should track intro click index as \(index + 1).")
            }

            // Reset analyticsSpy properties
            analyticsSpy.introClickLabelCalled = nil
            analyticsSpy.introClickPageCalled = nil
            analyticsSpy.introClickIndexCalled = nil
        }
    }

    // MARK: - News Detail Tests

    func testNewsControllerViewDidAppearTracksNavigationViewNews() {
        // Arrange
        do {
            let item = try createMockNewsModel()!
            let items = [item]
            let newsController = NewsController(items: items, windowUUID: .XCTestDefaultUUID)
            XCTAssertNil(analyticsSpy.navigationActionCalled)
            XCTAssertNil(analyticsSpy.navigationLabelCalled)

            // Act
            newsController.loadViewIfNeeded()
            newsController.viewDidAppear(false)

            // Assert
            XCTAssertEqual(analyticsSpy.navigationActionCalled, .view, "Analytics should track navigation action as .view.")
            XCTAssertEqual(analyticsSpy.navigationLabelCalled, .news, "Analytics should track navigation label as .news.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testNewsControllerDidSelectItemTracksNavigationOpenNews() {
        // Arrange
        do {
            let item = try createMockNewsModel()!
            let items = [item]
            let newsController = NewsController(items: items, windowUUID: .XCTestDefaultUUID)
            XCTAssertNil(analyticsSpy.navigationOpenNewsIdCalled)
            newsController.loadView()
            newsController.collection.reloadData()
            let indexPath = IndexPath(row: 0, section: 0)

            // Act
            newsController.collectionView(newsController.collection, didSelectItemAt: indexPath)

            // Assert
            XCTAssertEqual(analyticsSpy.navigationOpenNewsIdCalled, "example_news_tracking", "Analytics should track navigation open news with ID 'example_news_tracking'.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Multiply Impact - Referrals Tests

    func testMultiplyImpactViewDidAppearTracksReferralViewInviteScreen() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals, windowUUID: .XCTestDefaultUUID)
        multiplyImpact.loadViewIfNeeded()

        // Act
        multiplyImpact.viewDidAppear(false)

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .view, "Analytics should track referral action as .view.")
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .inviteScreen, "Analytics should track referral label as .inviteScreen.")
    }

    func testMultiplyImpactLearnMoreButtonTracksReferralClickLearnMore() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals, windowUUID: .XCTestDefaultUUID)
        multiplyImpact.loadViewIfNeeded()

        // Ensure learnMoreButton is not nil
        guard let learnMoreButton = multiplyImpact.learnMoreButton else {
            XCTFail("learnMoreButton should not be nil after view is loaded")
            return
        }

        // Create an expectation
        let expectation = self.expectation(description: "Analytics referral called for Learn More")
        analyticsSpy.referralClickExpectation = expectation

        // Act
        learnMoreButton.sendActions(for: .primaryActionTriggered)

        // Wait for the expectation
        wait(for: [expectation], timeout: 2)

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click, "Analytics should track referral action as .click.")
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .learnMore, "Analytics should track referral label as .learnMore.")
    }

    func testMultiplyImpactInviteFriendsTracksReferralClickInvite() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpact(referrals: referrals, windowUUID: .XCTestDefaultUUID)
        User.shared.referrals.code = "testCode"
        multiplyImpact.loadViewIfNeeded()

        // Ensure inviteButton is not nil
        guard let inviteButton = multiplyImpact.inviteButton else {
            XCTFail("Invite Friends button should not be nil after view is loaded")
            return
        }

        // Create an expectation
        let expectation = self.expectation(description: "Analytics referral called for Invite")
        analyticsSpy.referralClickExpectation = expectation

        // Act
        inviteButton.sendActions(for: .touchUpInside)

        // Wait for the expectation
        wait(for: [expectation], timeout: 2)

        // Assert
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click, "Analytics should track referral action as .click.")
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite, "Analytics should track referral label as .invite.")
    }

    func testMultiplyImpactInviteFriendsCompletionTracksReferralSendInvite() {
        // Arrange
        let referrals = Referrals()
        let multiplyImpact = MultiplyImpactTestable(referrals: referrals, windowUUID: .XCTestDefaultUUID)
        User.shared.referrals.code = "testCode"
        multiplyImpact.loadViewIfNeeded()

        // Ensure inviteButton is not nil
        guard let inviteButton = multiplyImpact.inviteButton else {
            XCTFail("Invite Friends button should not be nil after view is loaded")
            return
        }

        // Create expectations for .click and .send actions
        let clickExpectation = self.expectation(description: "Analytics referral click called")
        let sendExpectation = self.expectation(description: "Analytics referral send called")
        analyticsSpy.referralClickExpectation = clickExpectation
        analyticsSpy.referralSendExpectation = sendExpectation

        // Act
        inviteButton.sendActions(for: .touchUpInside)

        // Wait for the click expectation
        wait(for: [clickExpectation], timeout: 2)

        // Assert initial click analytics
        XCTAssertEqual(analyticsSpy.referralActionCalled, .click, "Analytics should track referral action as .click.")
        XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite, "Analytics should track referral label as .invite.")

        // Reset analyticsSpy properties for the next action
        analyticsSpy.referralActionCalled = nil
        analyticsSpy.referralLabelCalled = nil

        // Assert that the share sheet is intended to be presented
        XCTAssertNotNil(multiplyImpact.capturedPresentedViewController, "Expected a view controller to be presented")
        XCTAssertTrue(multiplyImpact.capturedPresentedViewController is UIActivityViewController, "Expected UIActivityViewController to be presented")

        // Simulate share completion
        if let activityVC = multiplyImpact.capturedPresentedViewController as? UIActivityViewController,
           let completionHandler = activityVC.completionWithItemsHandler {

            // Act: Simulate user completed the share action
            completionHandler(nil, true, nil, nil)

            // Wait for the send expectation
            wait(for: [sendExpectation], timeout: 2)

            // Assert send analytics
            XCTAssertEqual(analyticsSpy.referralActionCalled, .send, "Analytics should track referral action as .send.")
            XCTAssertEqual(analyticsSpy.referralLabelCalled, .invite, "Analytics should track referral label as .invite.")
        } else {
            XCTFail("UIActivityViewController not found or completion handler not set")
        }
    }

    // MARK: - Top Sites Tests

    func testTilePressedTracksAnalyticsForPinnedSite() {
        // Arrange
        let viewModel = TopSitesViewModel(profile: profileMock,
                                          isZeroSearch: false,
                                          theme: EcosiaLightTheme(),
                                          wallpaperManager: WallpaperManager())
        let topSite = TopSite(site: PinnedSite(site: Site(url: "http://www.example.com", title: "Example Site"), faviconResource: nil))
        let position = 1

        // Act
        viewModel.tilePressed(site: topSite, position: position)

        // Assert
        XCTAssertEqual(analyticsSpy.ntpTopSiteActionCalled, .click, "Analytics should track ntpTopSiteActionCalled as .click.")
        XCTAssertEqual(analyticsSpy.ntpTopSitePropertyCalled, .pinned, "Analytics should track ntpTopSitePropertyCalled as .pinned.")
        XCTAssertEqual(analyticsSpy.ntpTopSitePositionCalled, NSNumber(value: position), "Analytics should track ntpTopSitePositionCalled correctly.")
    }

    func testTilePressedTracksAnalyticsForDefaultSite() {
        // Arrange
        let viewModel = TopSitesViewModel(profile: profileMock,
                                          isZeroSearch: false,
                                          theme: EcosiaLightTheme(),
                                          wallpaperManager: WallpaperManager())
        let topSite = TopSite(site: Site(url: Environment.current.urlProvider.financialReports.absoluteString, title: "Example Site"))
        let position = 1

        // Act
        viewModel.tilePressed(site: topSite, position: position)

        // Assert
        XCTAssertEqual(analyticsSpy.ntpTopSiteActionCalled, .click, "Analytics should track ntpTopSiteActionCalled as .click.")
        XCTAssertEqual(analyticsSpy.ntpTopSitePropertyCalled, .default, "Analytics should track ntpTopSitePropertyCalled as .default.")
        XCTAssertEqual(analyticsSpy.ntpTopSitePositionCalled, NSNumber(value: position), "Analytics should track ntpTopSitePositionCalled correctly.")
    }

    func testTilePressedTracksAnalyticsForMostVisitedSite() {
        // Arrange
        let viewModel = TopSitesViewModel(profile: profileMock,
                                          isZeroSearch: false,
                                          theme: EcosiaLightTheme(),
                                          wallpaperManager: WallpaperManager())
        let topSite = TopSite(site: Site(url: "http://www.example.org", title: "Example Site"))
        let position = 1

        // Act
        viewModel.tilePressed(site: topSite, position: position)

        // Assert
        XCTAssertEqual(analyticsSpy.ntpTopSiteActionCalled, .click, "Analytics should track ntpTopSiteActionCalled as .click.")
        XCTAssertEqual(analyticsSpy.ntpTopSitePropertyCalled, .mostVisited, "Analytics should track ntpTopSitePropertyCalled as .mostVisited.")
        XCTAssertEqual(analyticsSpy.ntpTopSitePositionCalled, NSNumber(value: position), "Analytics should track ntpTopSitePositionCalled correctly.")
    }

    func testTrackTopSiteMenuActionTracksAnalytics() {
        // Arrange
        let viewModel = TopSitesViewModel(profile: profileMock,
                                          isZeroSearch: false,
                                          theme: EcosiaLightTheme(),
                                          wallpaperManager: WallpaperManager())
        let action: Analytics.Action.TopSite = .remove
        let site = Site(url: "http://www.example.org", title: "Example Site")

        // Act
        viewModel.trackTopSiteMenuAction(site: site, action: action)

        // Assert
        XCTAssertEqual(analyticsSpy.ntpTopSiteActionCalled, action, "Analytics should track ntpTopSiteActionCalled correctly.")
        XCTAssertEqual(analyticsSpy.ntpTopSitePropertyCalled, .mostVisited, "Analytics should track ntpTopSitePropertyCalled as .mostVisited.")
        XCTAssertNil(analyticsSpy.ntpTopSitePositionCalled, "Analytics ntpTopSitePositionCalled should be nil.")
    }

    func testNTPAboutEcosiaCellLearnMoreActionTracksNavigationOpen() {
        // Arrange

        // Create an instance of the real NTPAboutEcosiaCellViewModel
        let aboutViewModel = NTPAboutEcosiaCellViewModel(theme: EcosiaLightTheme())
        let sections = aboutViewModel.sections

        // Ensure that there are sections available
        guard let testSection = sections.first else {
            XCTFail("No sections available in NTPAboutEcosiaCellViewModel")
            return
        }

        // Create an instance of NTPAboutEcosiaCell
        let aboutCell = NTPAboutEcosiaCell(frame: CGRect(x: 0, y: 0, width: 320, height: 64))

        // Configure the cell with the real section and view model
        aboutCell.configure(section: testSection, viewModel: aboutViewModel)

        // Ensure that the analytics methods have not been called yet
        XCTAssertNil(analyticsSpy.navigationActionCalled, "Analytics navigationActionCalled should be nil before action.")
        XCTAssertNil(analyticsSpy.navigationLabelCalled, "Analytics navigationLabelCalled should be nil before action.")

        // Act

        // Simulate tapping the "Learn More" button by sending the touchUpInside action
        aboutCell.learnMoreButton.sendActions(for: .touchUpInside)

        // Assert

        // Verify that the analytics event was called with the correct action and label
        XCTAssertEqual(analyticsSpy.navigationActionCalled, .open, "Analytics should track navigationActionCalled as .open.")
        XCTAssertEqual(analyticsSpy.navigationLabelCalled, testSection.label, "Analytics should track navigationLabelCalled correctly.")
    }

    // MARK: - Analytics Context Tests

    func testAddUserStateContextOnResumeEvent() {
        // Arrange
        let analyticsSpy = makeAnalyticsSpyContextSUT(status: .ephemeral)
        let expectation = self.expectation(description: "Event tracked")
        let event = Structured(category: "",
                               action: Analytics.Action.Activity.resume.rawValue)

        // Act
        analyticsSpy.appendTestContextIfNeeded(.resume, event) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        // Assert
        let userContext = event.entities.first { $0.schema == Analytics.userSchema }
        XCTAssertNotNil(userContext, "User state context not found in event entities")
        if let userContext = userContext {
            XCTAssertEqual(userContext.data["push_notification_state"] as? String, "enabled")
        }
    }

    func testAddUserStateContextOnLaunchEvent() {
        // Arrange
        let analyticsSpy = makeAnalyticsSpyContextSUT(status: .denied)
        let expectation = self.expectation(description: "Event tracked")
        let event = Structured(category: "",
                               action: Analytics.Action.Activity.launch.rawValue)

        // Act
        analyticsSpy.appendTestContextIfNeeded(.resume, event) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        // Assert
        let userContext = event.entities.first { $0.schema == Analytics.userSchema }
        XCTAssertNotNil(userContext, "User state context not found in event entities")
        if let userContext = userContext {
            XCTAssertEqual(userContext.data["push_notification_state"] as? String, "disabled")
        }
    }

    // MARK: Analytics Private Data clearance

    func testClearPrivateDataTracksEvent() {
        // Arrange
        let vc = ClearPrivateDataTableViewController(profile: profileMock, tabManager: tabManagerMock)
        vc.loadViewIfNeeded()

        // Act
        vc.tableView(vc.tableView, didSelectRowAt: IndexPath(row: 0, section: 2))

        // Assert
        XCTAssertEqual(analyticsSpy.clearAllPrivateDataSectionCalled, .main, "Analytics should track clearAllPrivateDataSectionCalled as .main because we are simulating the click on Clear Private Data")
    }

    func testClearWebsitesDataTracksEvent() {
        // Arrange
        let vc = WebsiteDataManagementViewController(windowUUID: .XCTestDefaultUUID)
        vc.loadViewIfNeeded()

        // Act
        vc.tableView(vc.tableView, didSelectRowAt: IndexPath(row: 0, section: 2))

        // Assert
        XCTAssertEqual(analyticsSpy.clearAllPrivateDataSectionCalled, .websites, "Analytics should track clearAllPrivateDataSectionCalled as .websites because we are simulating the click on Clear Websiste Data")
    }
}

// MARK: - Helper SUTs
extension AnalyticsSpyTests {

    func makeAnalyticsSpyContextSUT(status: UNAuthorizationStatus = .notDetermined) -> AnalyticsSpy {
        let mockSettings = MockUNNotificationSettings(authorizationStatus: status)
        let mockNotificationCenter = MockAnalyticsUserNotificationCenter(mockSettings: mockSettings)
        let analyticsSpy = AnalyticsSpy(notificationCenter: mockNotificationCenter)
        return analyticsSpy
    }

    func makeWelcomeTour() -> WelcomeTour {
        WelcomeTour(delegate: MockWelcomeTourDelegate(), windowUUID: .XCTestDefaultUUID)
    }

    func makeWelcome() -> Welcome {
        Welcome(delegate: MockWelcomeDelegate(), windowUUID: .XCTestDefaultUUID)
    }
}

// MARK: - Helper Classes

class MultiplyImpactTestable: MultiplyImpact {
    var capturedPresentedViewController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        capturedPresentedViewController = viewControllerToPresent
    }
}
