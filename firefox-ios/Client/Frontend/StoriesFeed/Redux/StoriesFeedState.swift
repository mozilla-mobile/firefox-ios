// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct StoriesFeedState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    let storiesData: [MerinoStoryConfiguration]

    init(appState: AppState, uuid: WindowUUID) {
        guard let storiesFeedState = appState.screenState(
            StoriesFeedState.self,
            for: .storiesFeed,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: storiesFeedState.windowUUID,
            storiesData: storiesFeedState.storiesData
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            storiesData: []
        )
    }

    private init(
        windowUUID: WindowUUID,
        storiesData: [MerinoStoryConfiguration]
    ) {
        self.windowUUID = windowUUID
        self.storiesData = storiesData
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case MerinoMiddlewareActionType.retrievedUpdatedStoriesFeedStories:
            return handleRetrievedUpdatedStoriesFeedStoriesAction(action: action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleRetrievedUpdatedStoriesFeedStoriesAction(action: Action, state: Self) -> StoriesFeedState {
        guard let merinoAction = action as? MerinoAction,
              let stories = merinoAction.merinoStories
        else {
            return defaultState(from: state)
        }

        return StoriesFeedState(
            windowUUID: state.windowUUID,
            storiesData: stories
        )
    }

    static func defaultState(from state: StoriesFeedState) -> StoriesFeedState {
        return StoriesFeedState(
            windowUUID: state.windowUUID,
            storiesData: state.storiesData
        )
    }
}
