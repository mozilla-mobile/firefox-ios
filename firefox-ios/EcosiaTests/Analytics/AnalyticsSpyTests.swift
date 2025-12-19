// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import SnowplowTracker
import Common
import SwiftUI
import ViewInspector
import WebKit
@testable import Client
@testable import Ecosia

// MARK: - AnalyticsSpy

final class AnalyticsSpy: Analytics {

    // MARK: - AnalyticsSpy Properties to Capture Calls

    var trackedEvents: [SnowplowTracker.Event] = []

    override func track(_ event: SnowplowTracker.Event) {
        super.track(event)
        trackedEvents.append(event)
    }

    var installCalled = false
    override func install() {
        installCalled = true
    }

    var activityActionCalled: Analytics.Action.Activity?
    override func activity(_ action: Analytics.Action.Activity) {
        activityActionCalled = action
        super.activity(action)
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
    override func introDisplaying(page: Property.OnboardingPage?) {
        introDisplayingPageCalled = page
    }

    var introClickLabelCalled: Label.Onboarding?
    var introClickPageCalled: Property.OnboardingPage?
    override func introClick(_ label: Label.Onboarding, page: Property.OnboardingPage?) {
        introClickLabelCalled = label
        introClickPageCalled = page
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

    var inappSearchUrlCalled: URL?
    override func inappSearch(url: URL) {
        inappSearchUrlCalled = url
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

    var defaultBrowserSettingsShowsDetailViewLabelCalled: Analytics.Label.DefaultBrowser?
    override func defaultBrowserSettingsShowsDetailViewVia(_ label: Analytics.Label.DefaultBrowser) {
        defaultBrowserSettingsShowsDetailViewLabelCalled = label
    }

    var defaultBrowserSettingsViaNudgeCardDismissCalled = false
    override func defaultBrowserSettingsViaNudgeCardDismiss() {
        defaultBrowserSettingsViaNudgeCardDismissCalled = true
    }

    var defaultBrowserSettingsOpenNativeSettingsLabelCalled: Analytics.Label.DefaultBrowser?
    override func defaultBrowserSettingsOpenNativeSettingsVia(_ label: Analytics.Label.DefaultBrowser) {
        defaultBrowserSettingsOpenNativeSettingsLabelCalled = label
    }

    var defaultBrowserSettingsDismissDetailViewLabelCalled: Analytics.Label.DefaultBrowser?
    override func defaultBrowserSettingsDismissDetailViewVia(_ label: Analytics.Label.DefaultBrowser) {
        defaultBrowserSettingsDismissDetailViewLabelCalled = label
    }
}

// MARK: - AnalyticsSpyTests

final class AnalyticsSpyTests: XCTestCase {

    // MARK: - Properties and Setup

    var analyticsSpy: AnalyticsSpy!
    var profileMock: MockProfile { MockProfile() }
    var tabManagerMock: TabManager {
        let mock = MockTabManager()
        let tab = Tab(profile: profileMock, windowUUID: .XCTestDefaultUUID)
        mock.selectedTab = tab
        mock.selectedTab?.url = URL(string: "https://example.com")
        mock.subscriptedTab = tab
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
            .init(label: .readingList, value: true, title: .ShareAddToReadingList),
            .init(label: .readingList, value: false, title: .LegacyAppMenu.RemoveReadingList),
            .init(label: .bookmark, value: true, title: .KeyboardShortcuts.AddBookmark),
            .init(label: .shortcut, value: true, title: .AddToShortcutsActionTitle),
            .init(label: .shortcut, value: false, title: .LegacyAppMenu.RemoveFromShortcuts)
        ]

        for testCase in testCases {
            XCTContext.runActivity(named: "Track menu status change \(testCase.label.rawValue) to \(testCase.value)") { _ in
                // Reset state
                analyticsSpy = AnalyticsSpy()
                Analytics.shared = analyticsSpy
                tabManagerMock.selectedTab?.url = URL(string: "https://example.com")

                let semaphore = DispatchSemaphore(value: 0)
                let expectation = self.expectation(description: "menuStatus called for \(testCase.label.rawValue) to \(testCase.value)")
                analyticsSpy.menuStatusExpectation = expectation

                // Act
                menuHelper.getToolbarActions(navigationController: .init()) { actions in
                    let flatItems = actions.flatMap { $0 }.flatMap { $0.items }
                    guard let action = flatItems.first(where: { $0.title == testCase.title }) else {
                        XCTFail("No action with title \(testCase.title) found")
                        semaphore.signal()
                        return
                    }

                    action.tapHandler?(action)
                    semaphore.signal()
                }

                // Wait for async completion
                _ = semaphore.wait(timeout: .now() + 2)
                wait(for: [expectation], timeout: 2)

                XCTAssertEqual(analyticsSpy.menuStatusItemCalled, testCase.label, "Expected menu status label to be \(testCase.label.rawValue)")
                XCTAssertEqual(analyticsSpy.menuStatusItemChangedTo, testCase.value, "Expected menu status value to be \(testCase.value)")
            }
        }
    }

    // MARK: - Onboarding / Welcome Tests

    func testWelcomeViewDidAppearTracksIntroDisplayingAndIntroClickStart() {
        // Arrange
        let welcome = makeWelcome()
        XCTAssertNil(analyticsSpy.introDisplayingPageCalled)

        // Act
        welcome.loadViewIfNeeded()
        welcome.viewDidAppear(false)

        // Assert
        XCTAssertEqual(analyticsSpy.introDisplayingPageCalled, .start, "Analytics should track intro displaying page as .start.")
    }

    func testWelcomeGetStartedTracksIntroClickNext() {
        // Arrange
        let welcome = makeWelcome()
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)

        // Act
        welcome.getStarted()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next, "Analytics should track intro click label as .next.")
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .start, "Analytics should track intro click page as .start.")
    }

    func testWelcomeSkipTracksIntroClickSkip() {
        // Arrange
        let welcome = makeWelcome()
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)

        // Act
        welcome.skip()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .skip, "Analytics should track intro click label as .skip.")
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .start, "Analytics should track intro click page as .start.")
    }

    // MARK: - Onboarding / Welcome Tour Tests

    func testWelcomeTourViewDidAppearTracksIntroDisplaying() {
        // Arrange
        let welcomeTour = makeWelcomeTour()
        XCTAssertNil(analyticsSpy.introDisplayingPageCalled)

        // Act
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)

        // Assert
        XCTAssertEqual(analyticsSpy.introDisplayingPageCalled, .greenSearch, "Analytics should track intro displaying page as .greenSearch.")
    }

    func testWelcomeTourNextTracksIntroClickNext() {
        // Arrange
        let welcomeTour = makeWelcomeTour()
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)

        // Act
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)
        welcomeTour.forward()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next, "Analytics should track intro click label as .next.")
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .greenSearch, "Analytics should track intro click page as .greenSearch.")
    }

    func testWelcomeTourSkipTracksIntroClickSkip() {
        // Arrange
        let welcomeTour = makeWelcomeTour()
        XCTAssertNil(analyticsSpy.introClickLabelCalled)
        XCTAssertNil(analyticsSpy.introClickPageCalled)

        // Act
        welcomeTour.loadViewIfNeeded()
        welcomeTour.viewDidAppear(false)
        welcomeTour.skip()

        // Assert
        XCTAssertEqual(analyticsSpy.introClickLabelCalled, .skip, "Analytics should track intro click label as .skip.")
        XCTAssertEqual(analyticsSpy.introClickPageCalled, .greenSearch, "Analytics should track intro click page as .greenSearch.")
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

            if index < pages.count - 1 {
                // Act
                welcomeTour.forward()

                // Assert
                XCTAssertEqual(analyticsSpy.introClickLabelCalled, .next, "Analytics should track intro click label as .next.")
                XCTAssertEqual(analyticsSpy.introClickPageCalled, page, "Analytics should track intro click page as \(page).")
            }

            // Reset analyticsSpy properties
            analyticsSpy.introClickLabelCalled = nil
            analyticsSpy.introClickPageCalled = nil
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

    // MARK: - WebView delegate Search Event

    func testWebViewDelegateTracksSearchEventOnEcosiaVerticalURLChange() {
        let browser = BrowserViewController(profile: profileMock, tabManager: tabManagerMock)

        let rootURL = EcosiaEnvironment.current.urlProvider.root
        let testCases = [
            ("https://www.example.org", false, "Does not track external URLs"),
            ("\(rootURL)", false, "Does not track index page"),
            ("\(rootURL)/search?q=test", true, "Tracks search query"),
            ("\(rootURL)/search?q=test", false, "Does not track if url did not change"),
            ("\(rootURL)/images?q=test1", true, "Tracks images query"),
            ("\(rootURL)/news?q=test2&p=1", true, "Tracks news query"),
            ("\(rootURL)/videos?q=test3", true, "Tracks videos query"),
            ("\(rootURL)/settings", false, "Does not track non-search pages"),
            ("https://blog.ecosia.org/", false, "Does not track on other Ecosia urls"),
        ]

        for (urlString, shouldTrack, message) in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            let url = URL(string: urlString)!
            var action = FakeNavigationAction(url: url,
                                              navigationType: .other)
            browser.webView(makeWebView(),
                            decidePolicyFor: action) { policy in
                XCTAssertEqual(policy, .allow, "Should allow independent of tracking behavior")
            }

            if shouldTrack {
                XCTAssertEqual(analyticsSpy.inappSearchUrlCalled?.absoluteString,
                               url.absoluteString,
                               "Failure on: \(message)")
            } else {
                XCTAssertNil(analyticsSpy.inappSearchUrlCalled, "Failure on: \(message)")
            }
            analyticsSpy = nil
            Analytics.shared = Analytics()
        }
    }

    func testWebViewDelegateTracksSearchEventBasedOnNavigationType() {
        let browser = BrowserViewController(profile: profileMock, tabManager: tabManagerMock)

        let rootURL = EcosiaEnvironment.current.urlProvider.root
        let testCases = [
            (WKNavigationType.other, "\(rootURL)/search?q=test", true, "Tracks regular navigation"),
            (WKNavigationType.reload, "\(rootURL)/search?q=test", true, "Tracks reload (with unchanged url)"),
            (WKNavigationType.backForward, "\(rootURL)/search?q=test1", false, "Does not track back forward"),
        ]

        for (type, urlString, shouldTrack, message) in testCases {
            analyticsSpy = AnalyticsSpy()
            Analytics.shared = analyticsSpy
            let url = URL(string: urlString)!
            var action = FakeNavigationAction(url: url,
                                              navigationType: type)
            browser.webView(makeWebView(),
                            decidePolicyFor: action) { policy in
                XCTAssertEqual(policy, .allow, "Should allow independent of tracking behavior")
            }

            if shouldTrack {
                XCTAssertEqual(analyticsSpy.inappSearchUrlCalled?.absoluteString,
                               url.absoluteString,
                               "Failure on: \(message)")
            } else {
                XCTAssertNil(analyticsSpy.inappSearchUrlCalled, "Failure on: \(message)")
            }
            analyticsSpy = nil
            Analytics.shared = Analytics()
        }
    }

    // MARK: - Analytics Context Tests

    func testAddUserStateContextOnResumeEvent() {
        // Arrange
        let analyticsSpy = makeAnalyticsSpyContextSUT(status: .ephemeral)
        let expectation = self.expectation(description: "Event tracked")
        let event = Structured(category: "",
                               action: Analytics.Action.Activity.resume.rawValue)

        // Act
        analyticsSpy.appendActivityContextIfNeeded(.resume, event) {
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
        analyticsSpy.appendActivityContextIfNeeded(.resume, event) {
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

    func testAddUserSeedCountContextToAllEvents() {
        // Arrange
        let analyticsSpy = makeAnalyticsSpyContextSUT()
        User.shared.sendAnonymousUsageData = true
        let event = Structured(category: Analytics.Category.bookmarks.rawValue,
                               action: Analytics.Action.click.rawValue)

        // Act
        analyticsSpy.track(event)

        // Assert
        XCTAssertEqual(analyticsSpy.trackedEvents.count, 1, "Should have tracked one event")
        let seedCountContext = event.entities.first { $0.schema == Analytics.impactBalanceSchema }
        XCTAssertNotNil(seedCountContext, "User seed count context must be added to the structured event")
        if let seedCountContext = seedCountContext {
            XCTAssertEqual(seedCountContext.data["amount"] as? Int, User.shared.seedCount)
        }
    }

    func testAddUserSeedCountContextToResumeEventOnDidBecomeActive() async {
        // Arrange
        User.shared.sendAnonymousUsageData = true
        XCTAssertNil(analyticsSpy.activityActionCalled)
        let application = await UIApplication.shared

        // Act
        _ = await appDelegate.applicationDidBecomeActive(application)

        waitForCondition(timeout: 2) {
            !analyticsSpy.trackedEvents.isEmpty && analyticsSpy.activityActionCalled == .resume
        }

        // Assert
        XCTAssertEqual(analyticsSpy.activityActionCalled, .resume)
        XCTAssertEqual(analyticsSpy.trackedEvents.count, 1)

        if let structuredEvent = analyticsSpy.trackedEvents.first(where: { ($0 as? Structured)?.action == Analytics.Action.Activity.resume.rawValue }) {
            let seedCountContext = structuredEvent.entities.first { $0.schema == Analytics.impactBalanceSchema }
            XCTAssertNotNil(seedCountContext)
            if let seedCountContext = seedCountContext {
                XCTAssertEqual(seedCountContext.data["amount"] as? Int, User.shared.seedCount)
            }
        } else {
            XCTFail("Tracked event should be a Structured event")
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

    // MARK: Analytics Default Browser

    func testShowInstructionStepsTriggersAnalyticsEvent() throws {
        User.shared.showDefaultBrowserSettingNudgeCard()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())

        let view = makeInstructionsViewSUT()
            .onAppear {
                Analytics.shared.defaultBrowserSettingsDismissDetailViewVia(.settingsNudgeCard)
            }

        try view.inspect().callOnAppear()

        XCTAssertEqual(analyticsSpy.defaultBrowserSettingsDismissDetailViewLabelCalled, .settingsNudgeCard)
    }

    func testTappingDismissButtonOnNudgeCardTriggersAnalyticsEvent() {
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        User.shared.showDefaultBrowserSettingNudgeCard()
        let vc = AppSettingsTableViewController(with: profileMock,
                                                and: tabManagerMock)
        vc.loadViewIfNeeded()
        vc.viewWillAppear(false)

        guard let header = vc.tableView(vc.tableView, viewForHeaderInSection: 0) as? DefaultBrowserSettingsNudgeCardHeaderView else {
            XCTFail("Expected nudge card header")
            return
        }

        header.onDismiss?()

        XCTAssertTrue(analyticsSpy.defaultBrowserSettingsViaNudgeCardDismissCalled)
    }

    func testDismissInstructionStepsTriggersAnalyticsEvent() throws {
        User.shared.showDefaultBrowserSettingNudgeCard()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())

        let view = makeInstructionsViewSUT()
            .onDisappear {
                Analytics.shared.defaultBrowserSettingsDismissDetailViewVia(.settingsNudgeCard)
            }

        try view.inspect().callOnDisappear()

        XCTAssertEqual(analyticsSpy.defaultBrowserSettingsDismissDetailViewLabelCalled, .settingsNudgeCard)
    }

    func testDefaultBrowserSettingsOpenNativeSettingsTracksLabelAndProperty() throws {
        User.shared.showDefaultBrowserSettingNudgeCard()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())

        let view = makeInstructionsViewSUT(onButtonTap: {
            Analytics.shared.defaultBrowserSettingsOpenNativeSettingsVia(.settings)
        })

        try view.inspect().find(button: String.Key.defaultBrowserCardDetailButton.rawValue).tap()

        analyticsSpy.defaultBrowserSettingsOpenNativeSettingsVia(.settings)
        XCTAssertEqual(analyticsSpy.defaultBrowserSettingsOpenNativeSettingsLabelCalled, .settings, "Expected label 'default_browser_settings' to be tracked.")
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

    func makeInstructionsViewSUT(onButtonTap: @escaping () -> Void = {}) -> InstructionStepsView<some View> {
        let style = InstructionStepsViewStyle(
            backgroundPrimaryColor: .blue,

            topContentBackgroundColor: .blue,
            stepsBackgroundColor: .blue,
            textPrimaryColor: .blue,
            textSecondaryColor: .blue,
            buttonBackgroundColor: .blue,
            buttonTextColor: .blue,
            stepRowStyle: StepRowStyle(stepNumberColor: .blue, stepTextColor: .blue)
        )

        return InstructionStepsView(
            title: .defaultBrowserCardDetailTitle,
            steps: [InstructionStep(text: .defaultBrowserCardDetailInstructionStep1)],
            buttonTitle: .defaultBrowserCardDetailButton,
            onButtonTap: onButtonTap,
            style: style
        ) {
            EmptyView()
        }
    }

    func makeWebView() -> WKWebView {
        return WKWebView(frame: CGRect(width: 100, height: 100))
    }
}

// MARK: - Helper Classes

class MultiplyImpactTestable: MultiplyImpact {
    var capturedPresentedViewController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        capturedPresentedViewController = viewControllerToPresent
    }
}

final class FakeNavigationAction: WKNavigationAction {
    let urlRequest: URLRequest
    let type: WKNavigationType

    override var request: URLRequest { urlRequest }

    override var navigationType: WKNavigationType { type }

    init(url: URL, navigationType: WKNavigationType) {
        self.urlRequest = URLRequest(url: url)
        self.type = navigationType
        super.init()
    }
}
