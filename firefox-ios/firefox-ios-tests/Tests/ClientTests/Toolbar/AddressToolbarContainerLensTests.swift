// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common
import ToolbarKit
@testable import Client

@MainActor
final class AddressToolbarContainerLensTests: XCTestCase {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private let url = URL(string: "https://example.com")

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: MockTabManager())
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testInit_withoutToolbarState_returnsEmptyLeadingPageActions() {
        let appState = AppState(presentedComponents: PresentedComponentsState(components: []))
        let subject = AddressToolbarContainerLens(appState: appState, uuid: windowUUID)

        XCTAssertTrue(subject.leadingPageActions.isEmpty)
        XCTAssertTrue(subject.navigationActions.isEmpty)
    }

    // MARK: - navigationActions, derived straight from ToolbarState (no action involved)

    func testInit_showingNavigationToolbar_returnsEmptyNavigationActions() {
        let subject = createSubject(isShowingNavigationToolbar: true, canGoBack: true, canGoForward: true)

        XCTAssertTrue(subject.navigationActions.isEmpty)
    }

    func testInit_notShowingNavigationToolbar_returnsBackAndForwardActions() {
        let subject = createSubject(isShowingNavigationToolbar: false, canGoBack: true, canGoForward: false)

        XCTAssertEqual(subject.navigationActions.count, 2)
        XCTAssertEqual(subject.navigationActions[0].actionType, .back)
        XCTAssertEqual(subject.navigationActions[0].isEnabled, true)
        XCTAssertEqual(subject.navigationActions[1].actionType, .forward)
        XCTAssertEqual(subject.navigationActions[1].isEnabled, false)
    }

    func testInit_onRealWebsite_returnsShareAction() {
        let subject = createSubject(url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.actionType, .share)
    }

    // MARK: - trailingPageActions, derived straight from ToolbarState (no action involved)

    func testInit_withEmptySearch_returnsEmptyTrailingPageActions() {
        let subject = createSubject(isEmptySearch: true, url: url)

        XCTAssertTrue(subject.trailingPageActions.isEmpty)
    }

    func testInit_notLoading_returnsTrailingReloadAction() {
        let subject = createSubject(isEmptySearch: false, isLoading: false, url: url)

        XCTAssertEqual(subject.trailingPageActions.last?.actionType, .reload)
    }

    func testInit_loading_returnsTrailingStopLoadingAction() {
        let subject = createSubject(isEmptySearch: false, isLoading: true, url: url)

        XCTAssertEqual(subject.trailingPageActions.last?.actionType, .stopLoading)
    }

    // MARK: - hasAlternativeLocationColor, derived straight from ToolbarState (no action involved)

    func testInit_withTopPosition_noTopTabs_showingNavToolbar_disablesCustomColor() {
        let subject = createSubject(toolbarPosition: .top,
                                    isShowingTopTabs: false,
                                    isShowingNavigationToolbar: true,
                                    url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.hasCustomColor, false)
    }

    func testInit_withTopPosition_topTabsShown_enablesCustomColor() {
        let subject = createSubject(toolbarPosition: .top,
                                    isShowingTopTabs: true,
                                    isShowingNavigationToolbar: true,
                                    url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.hasCustomColor, true)
    }

    func testInit_withTopPosition_navToolbarHidden_enablesCustomColor() {
        let subject = createSubject(toolbarPosition: .top,
                                    isShowingTopTabs: false,
                                    isShowingNavigationToolbar: false,
                                    url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.hasCustomColor, true)
    }

    func testInit_withBottomPosition_enablesCustomColor() {
        let subject = createSubject(toolbarPosition: .bottom,
                                    isShowingTopTabs: false,
                                    isShowingNavigationToolbar: true,
                                    url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.hasCustomColor, true)
    }

    // MARK: - browserActions, derived straight from ToolbarState (no action involved)

    func testInit_whenEditing_returnsOnlyCancelEditBrowserAction() {
        let subject = createSubject(isShowingNavigationToolbar: true, isEditing: true)

        XCTAssertEqual(subject.browserActions.count, 1)
        XCTAssertEqual(subject.browserActions[0].actionType, .cancelEdit)
    }

    func testInit_notEditing_showingNavigationToolbar_returnsEmptyBrowserActions() {
        let subject = createSubject(isShowingNavigationToolbar: true, isEditing: false)

        XCTAssertTrue(subject.browserActions.isEmpty)
    }

    func testInit_notEditing_notShowingNavToolbar_notShowingTopTabs_returnsNewTabMenuAndTabsActions() {
        let subject = createSubject(isShowingTopTabs: false,
                                    isShowingNavigationToolbar: false,
                                    numberOfTabs: 2,
                                    url: url)

        XCTAssertEqual(subject.browserActions.count, 3)
        XCTAssertEqual(subject.browserActions[0].actionType, .newTab)
        XCTAssertEqual(subject.browserActions[1].actionType, .menu)
        XCTAssertEqual(subject.browserActions[2].actionType, .tabs)
        XCTAssertEqual(subject.browserActions[2].numberOfTabs, 2)
    }

    // MARK: - navigationToolbarActions, derived straight from ToolbarState (no action involved)

    func testInit_navigationToolbarActions_onHomepage_returnsSearchMiddleAction() {
        let subject = createSubject(url: nil, middleButton: .home)

        XCTAssertEqual(subject.navigationToolbarActions.map(\.actionType), [.back, .forward, .search, .menu, .tabs])
    }

    func testInit_navigationToolbarActions_onWebsite_returnsConfiguredMiddleAction() {
        let subjectHomeButton = createSubject(url: url, middleButton: .home)
        XCTAssertEqual(subjectHomeButton.navigationToolbarActions[2].actionType, .home)

        let subjectNewTab = createSubject(url: url, middleButton: .newTab)
        XCTAssertEqual(subjectNewTab.navigationToolbarActions[2].actionType, .newTab)
    }

    func testInit_navigationToolbarActions_returnsBackAndForwardEnabledState() {
        let subject = createSubject(canGoBack: true, canGoForward: false)

        XCTAssertEqual(subject.navigationToolbarActions[0].isEnabled, true)
        XCTAssertEqual(subject.navigationToolbarActions[1].isEnabled, false)
    }

    func testInit_navigationToolbarActions_returnsNumberOfTabs() {
        let subject = createSubject(numberOfTabs: 2)

        XCTAssertEqual(subject.navigationToolbarActions[4].actionType, .tabs)
        XCTAssertEqual(subject.navigationToolbarActions[4].numberOfTabs, 2)
    }

    func testInit_navigationToolbarActions_withMenuWarningBadge_returnsBadgedMenuAction() {
        let subject = createSubject(showMenuWarningBadge: true)

        XCTAssertEqual(subject.navigationToolbarActions[3].actionType, .menu)
        XCTAssertNotNil(subject.navigationToolbarActions[3].badgeImageName)
        XCTAssertNotNil(subject.navigationToolbarActions[3].maskImageName)
    }

    func testInit_navigationToolbarActions_versionTwoLayout_returnsTabsBeforeMenu() {
        let subject = createSubject(toolbarLayout: .version2)

        XCTAssertEqual(subject.navigationToolbarActions.map(\.actionType), [.back, .forward, .search, .tabs, .menu])
    }

    // MARK: - borders, derived from position, private mode, scroll and microsurvey

    func testInit_withoutToolbarState_returnsNoBorders() {
        let appState = AppState(presentedComponents: PresentedComponentsState(components: []))
        let subject = AddressToolbarContainerLens(appState: appState, uuid: windowUUID)

        XCTAssertEqual(subject.addressBorderPosition, AddressToolbarBorderPosition.none)
        XCTAssertFalse(subject.displayNavBorder)
    }

    func testInit_topPosition_notScrolled_returnsNoAddressBorderAndNavBorder() {
        let subject = createSubject(toolbarPosition: .top)

        XCTAssertEqual(subject.addressBorderPosition, AddressToolbarBorderPosition.none)
        XCTAssertTrue(subject.displayNavBorder)
    }

    func testInit_topPosition_scrolled_returnsBottomAddressBorder() {
        let subject = createSubject(toolbarPosition: .top, isScrolled: true)

        XCTAssertEqual(subject.addressBorderPosition, .bottom)
        XCTAssertTrue(subject.displayNavBorder)
    }

    func testInit_topPosition_privateMode_returnsBottomAddressBorder() {
        let subject = createSubject(toolbarPosition: .top, isPrivateMode: true)

        XCTAssertEqual(subject.addressBorderPosition, .bottom)
    }

    func testInit_bottomPosition_returnsTopAddressBorderAndNoNavBorder() {
        let subject = createSubject(toolbarPosition: .bottom)

        XCTAssertEqual(subject.addressBorderPosition, .top)
        XCTAssertFalse(subject.displayNavBorder)
    }

    func testInit_bottomPosition_microsurveyShown_returnsNoBorders() {
        let subject = createSubject(toolbarPosition: .bottom, isMicrosurveyShown: true)

        XCTAssertEqual(subject.addressBorderPosition, AddressToolbarBorderPosition.none)
        XCTAssertFalse(subject.displayNavBorder)
    }

    func testInit_topPosition_microsurveyShown_scrolled_keepsAddressBorderAndHidesNavBorder() {
        let subject = createSubject(toolbarPosition: .top, isScrolled: true, isMicrosurveyShown: true)

        XCTAssertEqual(subject.addressBorderPosition, .bottom)
        XCTAssertFalse(subject.displayNavBorder)
    }

    func testInit_usesTheInjectedManager() {
        let manager = StubToolbarManager(addressBorderPosition: .bottom, displayNavBorder: true)
        let toolbarState = ToolbarState(windowUUID: windowUUID).copy(toolbarPosition: .bottom)
        let appState = AppState(presentedComponents: PresentedComponentsState(components: [.toolbar(toolbarState)]))

        let subject = AddressToolbarContainerLens(appState: appState, uuid: windowUUID, manager: manager)

        XCTAssertEqual(subject.addressBorderPosition, .bottom)
        XCTAssertTrue(subject.displayNavBorder)
    }

    // MARK: - Helpers

    // MARK: - lockIconState, derived from hasOnlySecureContent, isWebsiteMode and readerModeState

    func testInit_withoutToolbarState_returnsNoLockIcon() {
        let appState = AppState(presentedComponents: PresentedComponentsState(components: []))
        let subject = AddressToolbarContainerLens(appState: appState, uuid: windowUUID)

        XCTAssertNil(subject.lockIconState.imageName)
        XCTAssertNil(subject.lockIconState.a11yId)
        XCTAssertTrue(subject.lockIconState.needsTheming)
    }

    func testInit_withoutSecureContentInfo_returnsNoLockIcon() {
        let subject = createSubject(hasOnlySecureContent: nil)

        XCTAssertNil(subject.lockIconState.imageName)
        XCTAssertNil(subject.lockIconState.a11yId)
        XCTAssertTrue(subject.lockIconState.needsTheming)
    }

    func testInit_secureWebsite_returnsSecureLockIcon() {
        let subject = createSubject(hasOnlySecureContent: true, isWebsiteMode: true)

        XCTAssertEqual(subject.lockIconState.imageName, StandardImageIdentifiers.Small.shieldCheckmarkFill)
        XCTAssertEqual(subject.lockIconState.a11yId, AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon)
        XCTAssertTrue(subject.lockIconState.needsTheming)
    }

    func testInit_insecureWebsite_returnsInsecureLockIcon() {
        let subject = createSubject(hasOnlySecureContent: false, isWebsiteMode: true)

        XCTAssertEqual(subject.lockIconState.imageName, StandardImageIdentifiers.Small.shieldSlashFillMulticolor)
        XCTAssertEqual(subject.lockIconState.a11yId, AccessibilityIdentifiers.Browser.AddressToolbar.lockIconOff)
        XCTAssertFalse(subject.lockIconState.needsTheming)
    }

    func testInit_notWebsiteMode_hidesLockIconButKeepsA11yId() {
        let subject = createSubject(hasOnlySecureContent: true, isWebsiteMode: false)

        XCTAssertNil(subject.lockIconState.imageName)
        XCTAssertEqual(subject.lockIconState.a11yId, AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon)
    }

    func testInit_readerModeActive_hidesLockIcon() {
        let subject = createSubject(hasOnlySecureContent: true, isWebsiteMode: true, readerModeState: .active)

        XCTAssertNil(subject.lockIconState.imageName)
    }

    func testInit_readerModeNoLongerActive_restoresLockIcon() {
        let subject = createSubject(hasOnlySecureContent: true, isWebsiteMode: true, readerModeState: .available)

        XCTAssertEqual(subject.lockIconState.imageName, StandardImageIdentifiers.Small.shieldCheckmarkFill)
    }

    private func createSubject(
        toolbarPosition: AddressToolbarPosition = .top,
        isShowingTopTabs: Bool = true,
        isShowingNavigationToolbar: Bool = true,
        canGoBack: Bool = false,
        canGoForward: Bool = false,
        isEditing: Bool = false,
        isEmptySearch: Bool = true,
        isLoading: Bool = false,
        numberOfTabs: Int = 1,
        url: URL? = nil,
        middleButton: NavigationBarMiddleButtonType = .newTab,
        showMenuWarningBadge: Bool = false,
        toolbarLayout: ToolbarLayoutStyle = .version1,
        hasOnlySecureContent: Bool? = nil,
        isWebsiteMode: Bool = true,
        readerModeState: ReaderModeState? = nil,
        isPrivateMode: Bool = false,
        isScrolled: Bool = false,
        isMicrosurveyShown: Bool = false
    ) -> AddressToolbarContainerLens {
        let addressToolbar = AddressBarState(windowUUID: windowUUID)
            .copy(url: url)
            .copy(isEditing: isEditing)
            .copy(isLoading: isLoading)
            .copy(isEmptySearch: isEmptySearch)
            .copy(hasOnlySecureContent: hasOnlySecureContent)
            .copy(isWebsiteMode: isWebsiteMode)
            .copy(readerModeState: readerModeState)

        let toolbarState = ToolbarState(windowUUID: windowUUID)
            .copy(toolbarPosition: toolbarPosition)
            .copy(addressToolbar: addressToolbar)
            .copy(isShowingNavigationToolbar: isShowingNavigationToolbar)
            .copy(isShowingTopTabs: isShowingTopTabs)
            .copy(canGoBack: canGoBack)
            .copy(canGoForward: canGoForward)
            .copy(numberOfTabs: numberOfTabs)
            .copy(showMenuWarningBadge: showMenuWarningBadge)
            .copy(toolbarLayout: toolbarLayout)
            .copy(navigationToolbar: NavigationBarState(windowUUID: windowUUID).copy(middleButton: middleButton))
            .copy(isPrivateMode: isPrivateMode)
            .copy(isScrolled: isScrolled)

        let microsurveyState = MicrosurveyPromptState(windowUUID: windowUUID,
                                                      showPrompt: isMicrosurveyShown,
                                                      showSurvey: false,
                                                      model: nil)
        let browserViewControllerState = BrowserViewControllerState(windowUUID: windowUUID)
            .copy(microsurveyState: microsurveyState)
        let appState = AppState(presentedComponents: PresentedComponentsState(components: [
            .toolbar(toolbarState),
            .browserViewController(browserViewControllerState)
        ]))
        return AddressToolbarContainerLens(appState: appState, uuid: windowUUID)
    }
}

private struct StubToolbarManager: ToolbarManager {
    let addressBorderPosition: AddressToolbarBorderPosition
    let displayNavBorder: Bool

    func getAddressBorderPosition(for toolbarPosition: AddressToolbarPosition,
                                  isPrivate: Bool,
                                  isScrolled: Bool,
                                  isMicrosurveyShown: Bool) -> AddressToolbarBorderPosition {
        return addressBorderPosition
    }

    func shouldDisplayNavigationBorder(toolbarPosition: AddressToolbarPosition,
                                       isMicrosurveyShown: Bool) -> Bool {
        return displayNavBorder
    }
}
