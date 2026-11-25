// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

@MainActor
final class HomepageLensTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: Test direct initialization

    func testHomepageLens_usesProvidedStates() {
        let homepageState = createPopulatedHomepageState()

        let initialAppState = setupAppState(
            homepageState: .hasState(homepageState)
        )

        let subject = HomepageLens(appState: initialAppState, uuid: .XCTestDefaultUUID)

        XCTAssertEqual(subject.homepageState, homepageState)
    }

    func testHomepageLensTests_withMissingHomepageState_ProvidesEmptyState() {
        let initialAppState = setupAppState(
            homepageState: .noState
        )

        let subject = HomepageLens(appState: initialAppState, uuid: .XCTestDefaultUUID)

        XCTAssertEqual(subject.homepageState, HomepageState(windowUUID: .XCTestDefaultUUID))
    }

    // MARK: - Private

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
        homepageState: StateArgument<HomepageState>
    ) -> AppState {
        var componentState: [ComponentState] = []

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
