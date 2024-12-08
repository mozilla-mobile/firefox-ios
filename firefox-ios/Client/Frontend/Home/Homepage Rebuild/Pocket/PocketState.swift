// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared

struct SectionHeaderState: Hashable {
    var sectionHeaderTitle: String
    var sectionTitleA11yIdentifier: String
    var isSectionHeaderButtonHidden: Bool
    var sectionButtonA11yIdentifier: String?

    init(
        sectionHeaderTitle: String = .FirefoxHomepage.Pocket.SectionTitle,
        sectionTitleA11yIdentifier: String = AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.pocket,
        isSectionHeaderButtonHidden: Bool = true,
        sectionButtonA11yIdentifier: String? = nil) {
        self.sectionHeaderTitle = sectionHeaderTitle
        self.sectionTitleA11yIdentifier = sectionTitleA11yIdentifier
        self.isSectionHeaderButtonHidden = isSectionHeaderButtonHidden
        self.sectionButtonA11yIdentifier = sectionButtonA11yIdentifier
    }
}

struct PocketDiscoverState: Equatable {
    var title: String
    var url: URL?
}

/// State for the pocket section that is used in the homepage
struct PocketState: StateType, Equatable {
    var windowUUID: WindowUUID
    var pocketData: [PocketStoryState]
    var sectionHeaderState: SectionHeaderState
    let pocketDiscoverItem = PocketDiscoverState(
        title: .FirefoxHomepage.Pocket.DiscoverMore,
        url: PocketProvider.MoreStoriesURL
    )

    let footerURL = SupportUtils.URLForPocketLearnMore

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            pocketData: []
        )
    }

    private init(
        windowUUID: WindowUUID,
        pocketData: [PocketStoryState],
        sectionHeaderState: SectionHeaderState = SectionHeaderState()
    ) {
        self.windowUUID = windowUUID
        self.pocketData = pocketData
        self.sectionHeaderState = sectionHeaderState
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case PocketMiddlewareActionType.retrievedUpdatedStories:
            return handlePocketAction(action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handlePocketAction(_ action: Action, state: PocketState) -> PocketState {
        guard let pocketAction = action as? PocketAction,
              let pocketStories = pocketAction.pocketStories
        else {
            return defaultState(from: state)
        }

        return PocketState(
            windowUUID: state.windowUUID,
            pocketData: pocketStories,
            sectionHeaderState: state.sectionHeaderState
        )
    }

    static func defaultState(from state: PocketState) -> PocketState {
        return PocketState(
            windowUUID: state.windowUUID,
            pocketData: state.pocketData,
            sectionHeaderState: state.sectionHeaderState
        )
    }
}
