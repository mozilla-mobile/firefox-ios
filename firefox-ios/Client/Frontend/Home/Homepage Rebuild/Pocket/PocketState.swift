// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared

struct SectionHeaderState: Equatable {
    var sectionHeaderTitle: String
    var sectionTitleA11yIdentifier: String
    var isSectionHeaderButtonHidden: Bool
    var sectionHeaderColor: UIColor
    var sectionButtonA11yIdentifier: String?
}

struct PocketDiscoverState: Equatable {
    var title: String
    var url: URL?
}

/// State for the pocket section that is used in the homepage
struct PocketState: StateType, Equatable {
    var windowUUID: WindowUUID
    var pocketData: [PocketStoryState]
    let pocketDiscoverItem = PocketDiscoverState(
        title: .FirefoxHomepage.Pocket.DiscoverMore,
        url: PocketProvider.MoreStoriesURL
    )
    // TODO: FXIOS-10312 Update color for section header when wallpaper is configured with redux
    let sectionHeaderState = SectionHeaderState(
        sectionHeaderTitle: .FirefoxHomepage.Pocket.SectionTitle,
        sectionTitleA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.pocket,
        isSectionHeaderButtonHidden: true,
        sectionHeaderColor: .systemRed)

    let footerURL = SupportUtils.URLForPocketLearnMore

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            pocketData: []
        )
    }

    private init(
        windowUUID: WindowUUID,
        pocketData: [PocketStoryState]
    ) {
        self.windowUUID = windowUUID
        self.pocketData = pocketData
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case PocketMiddlewareActionType.retrievedUpdatedStories:
            guard let pocketAction = action as? PocketAction,
                  let stories = pocketAction.pocketStories
            else {
                return defaultState(from: state)
            }

            return PocketState(
                windowUUID: state.windowUUID,
                pocketData: stories
            )
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: PocketState) -> PocketState {
        return PocketState(
            windowUUID: state.windowUUID,
            pocketData: state.pocketData
        )
    }
}
