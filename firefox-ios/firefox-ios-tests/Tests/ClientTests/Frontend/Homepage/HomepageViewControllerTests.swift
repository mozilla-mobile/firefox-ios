// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class HomepageViewControllerTests: XCTestCase, StoreTestUtility {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    var mockNotificationCenter: MockNotificationCenter?
    var mockThemeManager: MockThemeManager?
    var mockStore: MockStoreForMiddleware<AppState>!
    var mockThrottler: MockThrottler!

    override func setUp() async throws {
        try await super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        mockThrottler = nil
        mockNotificationCenter = nil
        mockThemeManager = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    // MARK: - Initial State
    func testInitialCreation_hasCorrectContentType() {
        let sut = createSubject()

        XCTAssertEqual(sut.contentType, .homepage)
    }

    func testInitialCreation_hasCorrectWindowUUID() {
        let sut = createSubject()

        XCTAssertEqual(sut.currentWindowUUID, .XCTestDefaultUUID)
    }

    func test_viewDidLoad_setsUpThemingAndNotifications() {
        let sut = createSubject()

        XCTAssertEqual(mockThemeManager?.getCurrentThemeCallCount, 0)
        XCTAssertEqual(mockNotificationCenter?.addPublisherCount, 0)

        sut.loadViewIfNeeded()

        XCTAssertEqual(mockThemeManager?.getCurrentThemeCallCount, 1)
        XCTAssertEqual(mockNotificationCenter?.addPublisherCount, 1)
        XCTAssertEqual(mockNotificationCenter?.observers, [.ThemeDidChange])
    }

    func test_scrollViewDidScroll_updatesStatusBarScrollDelegate() {
        let mockStatusBarScrollDelegate = MockStatusBarScrollDelegate()
        let homepageVC = createSubject(statusBarScrollDelegate: mockStatusBarScrollDelegate)
        let wallpaperConfiguration = WallpaperConfiguration(hasImage: true)
        let newState = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            WallpaperAction(
                wallpaperConfiguration: wallpaperConfiguration,
                windowUUID: .XCTestDefaultUUID,
                actionType: WallpaperMiddlewareActionType.wallpaperDidInitialize
            )
        )
        homepageVC.newState(state: newState)
        let scrollView = UIScrollView()

        XCTAssertNil(mockStatusBarScrollDelegate.savedScrollView)

        homepageVC.scrollViewDidScroll(scrollView)

        XCTAssertEqual(mockStatusBarScrollDelegate.savedScrollView, scrollView)
    }

    func test_scrollToTop_updatesStatusBarScrollDelegate_andSetsCollectionViewOffset() {
        let mockStatusBarScrollDelegate = MockStatusBarScrollDelegate()
        let homepageVC = createSubject(statusBarScrollDelegate: mockStatusBarScrollDelegate)
        let wallpaperConfiguration = WallpaperConfiguration(hasImage: true)
        let newState = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            WallpaperAction(
                wallpaperConfiguration: wallpaperConfiguration,
                windowUUID: .XCTestDefaultUUID,
                actionType: WallpaperMiddlewareActionType.wallpaperDidInitialize
            )
        )

        guard let collectionView = homepageVC.view.subviews.first(where: {
            $0 is UICollectionView
        }) as? UICollectionView else {
            XCTFail()
            return
        }

        homepageVC.newState(state: newState)
        homepageVC.scrollToTop()

        XCTAssertEqual(collectionView.contentOffset, CGPoint(x: 0, y: -collectionView.adjustedContentInset.top))
        XCTAssertEqual(mockStatusBarScrollDelegate.savedScrollView, collectionView)
    }

    func test_scrollViewDidScroll_withoutScrollableContent_doesNotTriggerGeneralBrowserMiddlewareAction() throws {
        let mockStatusBarScrollDelegate = MockStatusBarScrollDelegate()
        let homepageVC = createSubject(statusBarScrollDelegate: mockStatusBarScrollDelegate)
        let scrollView = UIScrollView()
        scrollView.contentSize = CGSize(width: 320, height: 500)
        scrollView.frame = CGRect(x: 0, y: 0, width: 320, height: 600)
        scrollView.contentOffset.y = 10

        homepageVC.scrollViewDidScroll(scrollView)

        let actionCalled = mockStore.dispatchedActions.first(where: {
            $0 is GeneralBrowserMiddlewareAction
        })
        XCTAssertNil(actionCalled)
    }

    func test_scrollViewDidScroll_withScrollableContent_TriggersGeneralBrowserMiddlewareAction() throws {
        let mockStatusBarScrollDelegate = MockStatusBarScrollDelegate()
        let homepageVC = createSubject(statusBarScrollDelegate: mockStatusBarScrollDelegate)
        let scrollView = UIScrollView()
        scrollView.contentSize = CGSize(width: 320, height: 900)
        scrollView.frame = CGRect(x: 0, y: 0, width: 320, height: 600)
        scrollView.contentOffset.y = 10

        homepageVC.scrollViewDidScroll(scrollView)

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.first(where: {
                $0 is GeneralBrowserMiddlewareAction
            }) as? GeneralBrowserMiddlewareAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserMiddlewareActionType)
        XCTAssertEqual(actionType, GeneralBrowserMiddlewareActionType.websiteDidScroll)
    }

    func test_scrollViewWillBeginDragging_triggersToolbarAction() throws {
        let homepageVC = createSubject()
        let scrollView = UIScrollView()
        scrollView.contentOffset.y = 10
        setupNimbusToolbarRefactorTesting(isEnabled: true)

        homepageVC.scrollViewWillBeginDragging(scrollView)

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.first(where: {
                $0 is ToolbarAction
            }) as? ToolbarAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        XCTAssertEqual(actionType, ToolbarActionType.cancelEditOnHomepage)
    }

    func test_traitCollectionDidChange_triggersHomepageAction() throws {
        let subject = createSubject()
        subject.traitCollectionDidChange(nil)

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.first(where: { $0 is HomepageAction }) as? HomepageAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? HomepageActionType)
        XCTAssertEqual(actionType, HomepageActionType.traitCollectionDidChange)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(actionCalled.showiPadSetup ?? true)
    }

    func test_viewWillAppear_triggersHomepageAction() throws {
        let subject = createSubject()

        subject.viewWillAppear(false)

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.first(where: { $0 is HomepageAction }) as? HomepageAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? HomepageActionType)
        XCTAssertEqual(actionType, HomepageActionType.viewWillAppear)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_viewDidAppear_triggersHomepageAction() throws {
        let subject = createSubject()

        subject.viewDidAppear(false)

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.first(where: { $0 is HomepageAction }) as? HomepageAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? HomepageActionType)
        XCTAssertEqual(actionType, HomepageActionType.viewDidAppear)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_viewDidLayoutSubviews_withTopSitesChange_triggersHomepageAction() throws {
        let subject = createSubject()

        let newState = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            HomepageAction(
                numberOfTopSitesPerRow: 10,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.viewDidLayoutSubviews
            )
        )
        subject.newState(state: newState)

        subject.viewDidLayoutSubviews()
        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is HomepageAction }) as? HomepageAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? HomepageActionType)
        XCTAssertEqual(actionType, HomepageActionType.viewDidLayoutSubviews)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_viewDidLayoutSubviews_withoutTopSitesChange_triggersNothing() throws {
        let subject = createSubject()

        subject.viewDidLayoutSubviews()
        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is HomepageAction }) as? HomepageAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? HomepageActionType)
        XCTAssertNotEqual(actionType, HomepageActionType.viewDidLayoutSubviews)
    }

    func test_viewDidAppear_triggersHomepageAction() async throws {
        let subject = createSubject()
        let initialState = HomepageState(windowUUID: .XCTestDefaultUUID)

        // Add some visible sections in the collection view to trigger impression telemetry
        let populatedState = await getPopulatedCollectionViewState(from: initialState)

        // Need to call loadViewIfNeeded to load the view, newState to populate the datasource, and layoutIfNeeded to
        // reload the collectionView so that it's content is visible
        subject.loadViewIfNeeded()
        subject.newState(state: populatedState)
        subject.view.layoutIfNeeded()

        subject.viewDidAppear(false)

        XCTAssertTrue(mockThrottler.didCallThrottle)
        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is HomepageAction }) as? HomepageAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? HomepageActionType)
        XCTAssertEqual(actionType, HomepageActionType.sectionSeen)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_scrollViewDidEndDecelerating_triggersHomepageAction() async throws {
        let subject = createSubject()
        let initialState = HomepageState(windowUUID: .XCTestDefaultUUID)

        // Add some visible sections in the collection view to trigger impression telemetry
        let populatedState = await getPopulatedCollectionViewState(from: initialState)

        // Need to call loadViewIfNeeded to load the view, newState to populate the datasource, and layoutIfNeeded to
        // reload the collectionView so that it's content is visible
        subject.loadViewIfNeeded()
        subject.newState(state: populatedState)
        subject.view.layoutIfNeeded()

        subject.scrollViewDidEndDecelerating(UIScrollView())

        XCTAssertTrue(mockThrottler.didCallThrottle)
        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is HomepageAction }) as? HomepageAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? HomepageActionType)
        XCTAssertEqual(actionType, HomepageActionType.sectionSeen)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_newState_forTriggeringImpression_triggersHomepageAction() async throws {
        let subject = createSubject()
        let initialState = HomepageState(windowUUID: .XCTestDefaultUUID)

        // Add some visible sections in the collection view to trigger impression telemetry
        let populatedState = await getPopulatedCollectionViewState(from: initialState)
        let newState = HomepageState.reducer(
            populatedState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )

        // Need to call loadViewIfNeeded to load the view, newState to populate the datasource, and layoutIfNeeded to
        // reload the collectionView so that it's content is visible
        subject.loadViewIfNeeded()
        subject.newState(state: newState)
        subject.view.layoutIfNeeded()

        subject.newState(state: newState)

        XCTAssertTrue(newState.shouldTriggerImpression)
        XCTAssertTrue(mockThrottler.didCallThrottle)
        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is HomepageAction }) as? HomepageAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? HomepageActionType)
        XCTAssertEqual(actionType, HomepageActionType.sectionSeen)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_newState_forTriggeringImpression_withNoVisibleSections_doesNotTriggersHomepageAction() throws {
        let subject = createSubject()
        let initialState = HomepageState(windowUUID: .XCTestDefaultUUID)

        subject.loadViewIfNeeded()

        let newState = HomepageState.reducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )
        subject.newState(state: newState)

        XCTAssertTrue(newState.shouldTriggerImpression)
        XCTAssertTrue(mockThrottler.didCallThrottle)
        let homepageActions = mockStore.dispatchedActions.compactMap { $0 as? HomepageAction }
        let sectionSeenAction = homepageActions.first(where: {
            ($0.actionType as? HomepageActionType) == .sectionSeen
        })
        XCTAssertNil(sectionSeenAction)
    }

    func test_newState_didSelectedTabChangeToHomepageAction_forScrollToTop_setsCollectionViewOffsetToZero() {
        let mockStatusBarScrollDelegate = MockStatusBarScrollDelegate()
        let subject = createSubject(statusBarScrollDelegate: mockStatusBarScrollDelegate)
        let newState = HomepageState.reducer(
            HomepageState(windowUUID: .XCTestDefaultUUID),
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )

        guard let collectionView = subject.view.subviews.first(where: {
            $0 is UICollectionView
        }) as? UICollectionView else {
            XCTFail()
            return
        }

        subject.newState(state: newState)

        XCTAssertEqual(collectionView.contentOffset, CGPoint(x: 0, y: -collectionView.adjustedContentInset.top))
    }

    func test_restoreContentOffset_withStoredOffset_setsCollectionViewOffset() {
        setupNimbusStoriesScrollDirectionTesting(scrollDirection: .vertical)
        let tabManager = HomepageRestoreContentOffsetTabManager()
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tab.homepageScrollOffset = 180
        tabManager.tabs = [tab]
        tabManager.selectedTab = tab
        let subject = createSubject(tabManager: tabManager)

        subject.loadViewIfNeeded()

        guard let collectionView = subject.view.subviews.first(where: {
            $0 is UICollectionView
        }) as? UICollectionView else {
            XCTFail()
            return
        }

        collectionView.contentOffset = CGPoint(x: 0, y: 0)

        subject.restoreVerticalScrollOffset()

        XCTAssertEqual(collectionView.contentOffset.y, 180)
    }

    func test_restoreContentOffset_withoutStoredOffset_scrollsToTop() {
        let tabManager = HomepageRestoreContentOffsetTabManager()
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tabManager.tabs = [tab]
        tabManager.selectedTab = tab
        let subject = createSubject(tabManager: tabManager)

        subject.loadViewIfNeeded()

        guard let collectionView = subject.view.subviews.first(where: {
            $0 is UICollectionView
        }) as? UICollectionView else {
            XCTFail()
            return
        }

        collectionView.contentOffset = CGPoint(x: 0, y: 75)

        subject.restoreVerticalScrollOffset()

        XCTAssertEqual(collectionView.contentOffset, CGPoint(x: 0, y: -collectionView.adjustedContentInset.top))
    }

    func test_viewDidDisappear_savesVerticalScrollOffset() {
        let tabManager = HomepageRestoreContentOffsetTabManager()
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tabManager.tabs = [tab]
        tabManager.selectedTab = tab
        let subject = createSubject(tabManager: tabManager)

        subject.loadViewIfNeeded()
        subject.viewWillAppear(false)

        guard let collectionView = subject.view.subviews.first(where: {
            $0 is UICollectionView
        }) as? UICollectionView else {
            XCTFail()
            return
        }

        collectionView.contentOffset = CGPoint(x: 0, y: 140)

        subject.viewWillDisappear(false)

        XCTAssertEqual(tab.homepageScrollOffset, 140)
    }

    func test_scrollViewDidEndDragging_savesVerticalScrollOffset() {
        let tabManager = HomepageRestoreContentOffsetTabManager()
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tabManager.tabs = [tab]
        tabManager.selectedTab = tab
        let subject = createSubject(tabManager: tabManager)

        subject.loadViewIfNeeded()
        subject.viewWillAppear(false)

        guard let collectionView = subject.view.subviews.first(where: {
            $0 is UICollectionView
        }) as? UICollectionView else {
            XCTFail()
            return
        }

        collectionView.contentOffset = CGPoint(x: 0, y: 140)

        subject.scrollViewDidEndDragging(UIScrollView(), willDecelerate: false)

        XCTAssertEqual(tab.homepageScrollOffset, 140)
    }

    func test_scrollViewDidEndDecelerating_savesVerticalScrollOffset() {
        let tabManager = HomepageRestoreContentOffsetTabManager()
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tabManager.tabs = [tab]
        tabManager.selectedTab = tab
        let subject = createSubject(tabManager: tabManager)

        subject.loadViewIfNeeded()
        subject.viewWillAppear(false)

        guard let collectionView = subject.view.subviews.first(where: {
            $0 is UICollectionView
        }) as? UICollectionView else {
            XCTFail()
            return
        }

        collectionView.contentOffset = CGPoint(x: 0, y: 140)

        subject.scrollViewDidEndDecelerating(UIScrollView())

        XCTAssertEqual(tab.homepageScrollOffset, 140)
    }

    private func createSubject(
        tabManager: TabManager = MockTabManager(),
        statusBarScrollDelegate: StatusBarScrollDelegate? = nil
    ) -> HomepageViewController {
        let notificationCenter = MockNotificationCenter()
        let themeManager = MockThemeManager()
        let mockOverlayManager = MockOverlayModeManager()
        let throttler = MockThrottler()
        mockNotificationCenter = notificationCenter
        mockThemeManager = themeManager
        mockThrottler = throttler
        let homepageViewController = HomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            themeManager: themeManager,
            tabManager: tabManager,
            overlayManager: mockOverlayManager,
            statusBarScrollDelegate: statusBarScrollDelegate,
            toastContainer: UIView(),
            notificationCenter: notificationCenter,
            throttler: mockThrottler
        )
        trackForMemoryLeaks(homepageViewController)
        return homepageViewController
    }

    func setupAppState() -> Client.AppState {
        return AppState()
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }

    private func setupNimbusToolbarRefactorTesting(isEnabled: Bool) {
        FxNimbus.shared.features.toolbarRefactorFeature.with { _, _ in
            return ToolbarRefactorFeature(
                enabled: isEnabled
            )
        }
    }

    private func setupNimbusStoriesScrollDirectionTesting(scrollDirection: ScrollDirection) {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            return HomepageRedesignFeature(storiesScrollDirection: scrollDirection)
        }
    }

    private func getPopulatedCollectionViewState(from currentState: HomepageState) async -> HomepageState {
        let merinoManager = MockMerinoManager()
        let merinoStories = await merinoManager.getMerinoItems(source: .homepage)
        return HomepageState.reducer(
            currentState,
            MerinoAction(
                merinoStories: merinoStories,
                windowUUID: windowUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedHomepageStories
            )
        )
    }
}

// FXIOS-13346 / FXIOS-13343 - needed to update tests since we added a bandaid fix to not call
@MainActor
private func changeInitialStateToTriggerUpdateInSnapshot() -> HomepageState {
   return HomepageState.reducer(
        HomepageState(windowUUID: .XCTestDefaultUUID),
        GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
        )
    )
}

private final class HomepageRestoreContentOffsetTabManager: MockTabManager {
    override func getTabForUUID(uuid: TabUUID) -> Tab? {
        return tabs.first(where: { $0.tabUUID == uuid })
    }
}
