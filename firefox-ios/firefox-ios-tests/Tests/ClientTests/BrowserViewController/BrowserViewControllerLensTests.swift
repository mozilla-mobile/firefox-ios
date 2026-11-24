// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

@MainActor
final class BrowserViewControllerLensTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: Test direct initialization

    func testBrowserViewControllerLens_usesProvidedStates() {
        let browserViewControllerState = createPopulatedBrowserViewControllerState()
        let homepageState = createPopulatedHomepageState()

        let initialAppState = setupAppState(
            bvcState: .hasState(browserViewControllerState),
            homepageState: .hasState(homepageState)
        )

        let subject = BrowserViewControllerLens(appState: initialAppState, uuid: .XCTestDefaultUUID)

        XCTAssertEqual(subject.browserViewControllerState, browserViewControllerState)
        XCTAssertEqual(subject.homepageSearchBarState, homepageState.searchBarState)
    }

    func testBrowserViewControllerLens_withMissingHomepageState_usesProvidedBrowserViewControllerState() {
        let browserViewControllerState = createPopulatedBrowserViewControllerState()

        // It is possible that the BrowserViewController is initialized before the HomepageViewController adds its
        // HomepageState to the Redux store. When that happens, we need to ensure that we do not wipe the preexisting
        // BrowserViewControllerState.
        let initialAppState = setupAppState(
            bvcState: .hasState(browserViewControllerState),
            homepageState: .noState
        )

        let subject = BrowserViewControllerLens(appState: initialAppState, uuid: .XCTestDefaultUUID)

        XCTAssertEqual(subject.browserViewControllerState, browserViewControllerState)
    }

    func testBrowserViewControllerLens_withMissingBrowserViewControllerState_usesProvidedHomepageState() {
        let homepageState = createPopulatedHomepageState()

        // If the store is not fully initialized, it is possible that one of the two states the Lens needs is not yet
        // initialized.
        let initialAppState = setupAppState(
            bvcState: .noState,
            homepageState: .hasState(homepageState)
        )

        let subject = BrowserViewControllerLens(appState: initialAppState, uuid: .XCTestDefaultUUID)

        XCTAssertEqual(subject.homepageSearchBarState, homepageState.searchBarState)
    }

    // MARK: - Private
    private func createPopulatedBrowserViewControllerState() -> BrowserViewControllerState {
        return BrowserViewControllerState(
            windowUUID: .XCTestDefaultUUID,
            searchScreenState: SearchScreenState(inPrivateMode: true),
            toast: .addBookmark(urlString: "testurl"),
            showOverlay: true,
            reloadWebView: true,
            shouldStartAtHome: false,
            shouldShowReaderModeBarSummarizerButton: false,
            browserViewType: .normalHomepage,
            navigateTo: .home,
            displayView: .backForwardList,
            buttonTapped: nil,
            frameContext: nil,
            microsurveyState: MicrosurveyPromptState(windowUUID: .XCTestDefaultUUID),
            autoTranslatePromptState: AutoTranslatePromptState(windowUUID: .XCTestDefaultUUID),
            navigationDestination: NavigationDestination(.bookmarksPanel)
        )
    }

    private func createPopulatedHomepageState() -> HomepageState {
        return HomepageState(
            windowUUID: .XCTestDefaultUUID,
            headerState: HeaderState(
                windowUUID: .XCTestDefaultUUID,
                isPrivate: true,
                quickAnswersStore: MockQuickAnswersStore()
            ),
            privacyNoticeState: PrivacyNoticeState(windowUUID: .XCTestDefaultUUID),
            notificationCardState: NotificationCardState(windowUUID: .XCTestDefaultUUID),
            messageState: MessageCardState(windowUUID: .XCTestDefaultUUID),
            topSitesState: TopSitesSectionState(windowUUID: .XCTestDefaultUUID),
            searchBarState: SearchBarState(
                windowUUID: .XCTestDefaultUUID,
                isShowingCenterSearchBar: true,
                isHomepageVisible: true
            ),
            jumpBackInState: JumpBackInSectionState(windowUUID: .XCTestDefaultUUID),
            trackerBlockerModuleState: TrackerBlockerModuleState(windowUUID: .XCTestDefaultUUID),
            bookmarkState: BookmarksSectionState(windowUUID: .XCTestDefaultUUID),
            merinoState: MerinoState(windowUUID: .XCTestDefaultUUID),
            wallpaperState: WallpaperState(windowUUID: .XCTestDefaultUUID),
            telemetryState: HomepageTelemetryState(
                windowUUID: .XCTestDefaultUUID,
                isZeroSearch: true,
                shouldTriggerImpression: true
            )
        )
    }

    private enum StateArgument<T> {
        case hasState(T)
        case noState
    }

    private func setupAppState(
        bvcState: StateArgument<BrowserViewControllerState>,
        homepageState: StateArgument<HomepageState>
    ) -> AppState {
        var componentState: [ComponentState] = []

        switch bvcState {
        case .hasState(let state):
            componentState.append(.browserViewController(state))
        case .noState:
            break
        }

        switch homepageState {
        case .hasState(let state):
            componentState.append(.homepage(state))
        case .noState:
            break
        }

        return AppState(
            presentedComponents: PresentedComponentsState(
                components: componentState
            )
        )
    }
}
