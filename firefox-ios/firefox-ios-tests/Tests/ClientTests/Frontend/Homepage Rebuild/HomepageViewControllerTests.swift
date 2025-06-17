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

    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        mockThrottler = nil
        mockNotificationCenter = nil
        mockThemeManager = nil
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
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
        XCTAssertEqual(mockNotificationCenter?.addObserverCallCount, 0)

        sut.loadViewIfNeeded()

        XCTAssertEqual(mockThemeManager?.getCurrentThemeCallCount, 1)
        XCTAssertEqual(mockNotificationCenter?.addObserverCallCount, 1)
        XCTAssertEqual(mockNotificationCenter?.observers, [.ThemeDidChange])
    }

    // MARK: - Deinit State
    func testDeinit_callsAppropriateNotificationCenterMethods() {
        var sut: HomepageViewController? = createSubject()

        XCTAssertNotNil(sut)
        XCTAssertEqual(mockNotificationCenter?.removeObserverCallCount, 0)

        sut = nil

        XCTAssertNil(sut)
        XCTAssertEqual(mockNotificationCenter?.removeObserverCallCount, 1)
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

        XCTAssertEqual(collectionView.contentOffset, .zero)
        XCTAssertEqual(mockStatusBarScrollDelegate.savedScrollView, collectionView)
    }

    func test_scrollViewDidScroll_TriggersGeneralBrowserMiddlewareAction() throws {
        let mockStatusBarScrollDelegate = MockStatusBarScrollDelegate()
        let homepageVC = createSubject(statusBarScrollDelegate: mockStatusBarScrollDelegate)
        let scrollView = UIScrollView()
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

    func test_viewDidLayoutSubviews_triggersHomepageAction() throws {
        let subject = createSubject()

        subject.viewDidLayoutSubviews()
        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is HomepageAction }) as? HomepageAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? HomepageActionType)
        XCTAssertEqual(actionType, HomepageActionType.viewDidLayoutSubviews)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_viewDidAppear_triggersHomepageAction() throws {
        let subject = createSubject()
        // Need to call loadViewIfNeeded and newState to populate the datasource
        // used to check whether we should send dispatch action or not
        // layoutIfNeeded() recalculates the collection view to have items
        subject.loadViewIfNeeded()
        subject.newState(state: HomepageState(windowUUID: .XCTestDefaultUUID))
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

    func test_scrollViewDidEndDecelerating_triggersHomepageAction() throws {
        let subject = createSubject()
        // Need to call loadViewIfNeeded and newState to populate the datasource
        // used to check whether we should send dispatch action or not
        // layoutIfNeeded() recalculates the collection view to have items
        subject.loadViewIfNeeded()
        subject.newState(state: HomepageState(windowUUID: .XCTestDefaultUUID))
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

    func test_newState_forTriggeringImpression_triggersHomepageAction() throws {
        let subject = createSubject()
        let initialState = HomepageState(windowUUID: .XCTestDefaultUUID)
        let newState = HomepageState.reducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )

        // Need to call loadViewIfNeeded and newState to populate the datasource
        // layoutIfNeeded() recalculates the collection view to have items
        subject.loadViewIfNeeded()
        subject.newState(state: initialState)
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

        XCTAssertEqual(collectionView.contentOffset, .zero)
    }

    private func createSubject(statusBarScrollDelegate: StatusBarScrollDelegate? = nil) -> HomepageViewController {
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
}
