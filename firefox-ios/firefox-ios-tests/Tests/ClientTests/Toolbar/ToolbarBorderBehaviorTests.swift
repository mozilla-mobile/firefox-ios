// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit
import XCTest

@testable import Client

/// End-to-end baseline for the address and navigation toolbar borders. Input actions go through the real store,
/// middleware and reducers. The borders are read from the `AddressToolbarContainerLens`, which is what the
/// toolbar views consume, so the assertions survive refactors of where the border is computed.
@MainActor
final class ToolbarBorderBehaviorTests: XCTestCase {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var middleware: ToolbarMiddleware!
    private var windowManager: MockWindowManager!
    private var tabManager: MockTabManager!
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        tabManager = MockTabManager()
        profile = makeProfile()
        windowManager = MockWindowManager(wrappedManager: WindowManagerImplementation(), tabManager: tabManager)
        DependencyHelperMock().bootstrapDependencies(injectedWindowManager: windowManager,
                                                     injectedTabManager: tabManager)
        middleware = ToolbarMiddleware(
            toolbarTelemetry: ToolbarTelemetry(gleanWrapper: MockGleanWrapper()),
            profile: profile,
            summarizerConfigFactory: MockSummarizerConfigFactory(),
            recentSearchProvider: MockRecentSearchProvider(),
            featureFlagsProvider: MockNimbusFeatureFlags(),
            userPreferences: MockUserFeaturePreferences(),
            searchEnginesManager: MockSearchEnginesManager(),
            windowManager: windowManager
        )
        StoreTestUtilityHelper.setupStore(with: makeAppState(), middlewares: [middleware.toolbarProvider])
    }

    override func tearDown() async throws {
        middleware = nil
        tabManager = nil
        profile = nil
        windowManager = nil
        DependencyHelperMock().reset()
        StoreTestUtilityHelper.resetStore()
        try await super.tearDown()
    }

    // MARK: - Initial load

    func testLoad_atBottom_showsTopAddressBorderAndNoNavBorder() {
        loadBrowser(at: .bottom)

        assertBorders(position: .bottom, address: .top, nav: false)
    }

    func testLoad_atTop_showsNoAddressBorderAndNavBorder() {
        loadBrowser(at: .top)

        assertBorders(position: .top, address: AddressToolbarBorderPosition.none, nav: true)
    }

    // MARK: - Scroll

    func testScroll_atTop_showsBottomAddressBorderWhenScrolled() {
        loadBrowser(at: .top)

        scroll(toY: 100)

        assertBorders(position: .top, address: .bottom, nav: true)
    }

    func testScroll_atTop_hidesAddressBorderWhenBackToTopOfPage() {
        loadBrowser(at: .top)
        scroll(toY: 100)

        scroll(toY: 0)

        assertBorders(position: .top, address: AddressToolbarBorderPosition.none, nav: true)
    }

    func testScroll_atBottom_keepsTopAddressBorder() {
        loadBrowser(at: .bottom)

        scroll(toY: 100)

        assertBorders(position: .bottom, address: .top, nav: false)
    }

    // MARK: - URL change

    func testUrlDidChange_atTop_followsScrollOffsetOfNewPage() {
        loadBrowser(at: .top)

        urlDidChange(isPrivate: false, scrollY: 100)

        assertBorders(position: .top, address: .bottom, nav: true)
    }

    func testUrlDidChange_atTop_inPrivateMode_showsBottomAddressBorder() {
        loadBrowser(at: .top)

        urlDidChange(isPrivate: true, scrollY: 0)

        assertBorders(position: .top, address: .bottom, nav: true)
    }

    func testUrlDidChange_atBottom_inPrivateMode_keepsTopAddressBorder() {
        loadBrowser(at: .bottom)

        urlDidChange(isPrivate: true, scrollY: 0)

        assertBorders(position: .bottom, address: .top, nav: false)
    }

    func testPrivateModeAlone_atTop_showsBottomAddressBorder() {
        loadBrowser(at: .top)

        store.dispatch(ToolbarAction(url: URL(string: "https://example.com"),
                                     isPrivate: true,
                                     windowUUID: windowUUID,
                                     actionType: ToolbarActionType.urlDidChange))

        assertBorders(position: .top, address: .bottom, nav: true)
    }

    // MARK: - Position change

    func testPositionChange_topToBottom_showsTopAddressBorderAndNoNavBorder() {
        loadBrowser(at: .top)

        changePosition(to: .bottom, scrollY: 0)

        assertBorders(position: .bottom, address: .top, nav: false)
    }

    func testPositionChange_bottomToTop_whenScrolled_showsBottomAddressBorderAndNavBorder() {
        loadBrowser(at: .bottom)
        scroll(toY: 100)

        changePosition(to: .top, scrollY: 100)

        assertBorders(position: .top, address: .bottom, nav: true)
    }

    func testPositionChange_bottomToTop_atTopOfPage_showsNoAddressBorderAndNavBorder() {
        loadBrowser(at: .bottom)

        changePosition(to: .top, scrollY: 0)

        assertBorders(position: .top, address: AddressToolbarBorderPosition.none, nav: true)
    }

    func testPositionChange_atTop_inPrivateMode_showsBottomAddressBorder() {
        loadBrowser(at: .top)
        urlDidChange(isPrivate: true, scrollY: 0)

        changePosition(to: .top, scrollY: 0)

        assertBorders(position: .top, address: .bottom, nav: true)
    }

    // MARK: - Microsurvey, address bar at the bottom

    func testMicrosurveyShown_atBottom_hidesAddressAndNavBorders() {
        loadBrowser(at: .bottom)

        showMicrosurvey()

        assertBorders(position: .bottom, address: AddressToolbarBorderPosition.none, nav: false)
    }

    func testMicrosurveyClosed_atBottom_restoresTopAddressBorder() {
        loadBrowser(at: .bottom)
        showMicrosurvey()

        closeMicrosurvey()

        assertBorders(position: .bottom, address: .top, nav: false)
    }

    func testPositionChange_toBottom_whileMicrosurveyShown_hidesAddressAndNavBorders() {
        loadBrowser(at: .top)
        showMicrosurvey()

        changePosition(to: .bottom, scrollY: 0)

        assertBorders(position: .bottom, address: AddressToolbarBorderPosition.none, nav: false)
    }

    // MARK: - Microsurvey, address bar at the top

    func testMicrosurveyShown_atTop_hidesNavBorder() {
        loadBrowser(at: .top)

        showMicrosurvey()

        XCTAssertFalse(lens.displayNavBorder)
    }

    func testMicrosurveyClosed_atTop_restoresNavBorder() {
        loadBrowser(at: .top)
        showMicrosurvey()

        closeMicrosurvey()

        XCTAssertTrue(lens.displayNavBorder)
    }

    func testPositionChange_toTop_whileMicrosurveyShown_whenScrolled_keepsAddressBorderAndHidesNavBorder() {
        loadBrowser(at: .bottom)
        scroll(toY: 100)
        showMicrosurvey()

        changePosition(to: .top, scrollY: 100)

        assertBorders(position: .top, address: .bottom, nav: false)
    }

    func testMicrosurveyShown_atTop_whenScrolled_keepsAddressBorder() {
        loadBrowser(at: .top)
        scroll(toY: 100)

        showMicrosurvey()

        assertBorders(position: .top, address: .bottom, nav: false)
    }

    func testMicrosurveyClosed_atTop_whenScrolled_keepsAddressBorder() {
        loadBrowser(at: .top)
        scroll(toY: 100)
        showMicrosurvey()

        closeMicrosurvey()

        assertBorders(position: .top, address: .bottom, nav: true)
    }

    // MARK: - Helpers

    private var toolbarState: ToolbarState {
        guard let state = store.state.componentState(ToolbarState.self, for: .toolbar, window: windowUUID) else {
            XCTFail("ToolbarState is missing from the store")
            return ToolbarState(windowUUID: windowUUID)
        }
        return state
    }

    private var lens: AddressToolbarContainerLens {
        return AddressToolbarContainerLens(appState: store.state, uuid: windowUUID)
    }

    private func assertBorders(
        position: AddressToolbarPosition,
        address: AddressToolbarBorderPosition,
        nav: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let lens = lens
        XCTAssertEqual(toolbarState.toolbarPosition, position, "toolbar position", file: file, line: line)
        XCTAssertEqual(lens.addressBorderPosition, address, "address border", file: file, line: line)
        XCTAssertEqual(lens.displayNavBorder, nav, "navigation border", file: file, line: line)
    }

    private func loadBrowser(at position: SearchBarPosition) {
        store.dispatch(GeneralBrowserMiddlewareAction(
            toolbarPosition: position,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.browserDidLoad))
    }

    private func scroll(toY y: CGFloat) {
        store.dispatch(GeneralBrowserMiddlewareAction(
            scrollOffset: CGPoint(x: 0, y: y),
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.websiteDidScroll))
    }

    private func urlDidChange(isPrivate: Bool, scrollY: CGFloat) {
        store.dispatch(ToolbarAction(url: URL(string: "https://example.com"),
                                     isPrivate: isPrivate,
                                     windowUUID: windowUUID,
                                     actionType: ToolbarActionType.urlDidChange))
        store.dispatch(ToolbarMiddlewareAction(scrollOffset: CGPoint(x: 0, y: scrollY),
                                               windowUUID: windowUUID,
                                               actionType: ToolbarMiddlewareActionType.urlDidChange))
    }

    private func changePosition(to position: SearchBarPosition, scrollY: CGFloat) {
        store.dispatch(GeneralBrowserMiddlewareAction(
            scrollOffset: CGPoint(x: 0, y: scrollY),
            toolbarPosition: position,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.toolbarPositionChanged))
    }

    private func showMicrosurvey() {
        store.dispatch(MicrosurveyPromptMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.initialize))
    }

    private func closeMicrosurvey() {
        store.dispatch(MicrosurveyPromptAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptActionType.closePrompt))
    }

    private func makeAppState() -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .browserViewController(BrowserViewControllerState(windowUUID: windowUUID)),
                    .toolbar(ToolbarState(windowUUID: windowUUID))
                ]
            )
        )
    }
}
