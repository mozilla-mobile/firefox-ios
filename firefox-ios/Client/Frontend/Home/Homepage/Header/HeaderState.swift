// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Foundation
import Redux

/// State for the header cell that is used in the homepage header section
@Copyable
struct HeaderState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var isPrivate: Bool
    var showQuickAnswersButton: Bool
    var isWorldCupSectionEnabled: Bool

    init(
        windowUUID: WindowUUID,
        isPrivate: Bool = false,
        worldCupStore: WorldCupStoreProtocol = WorldCupStore(),
        quickAnswersStore: QuickAnswersStore = QuickAnswersMiddleware()
    ) {
        let isWorldCupSectionEnabled = isPrivate ? false : worldCupStore.isFeatureEnabledAndSectionEnabled
        let showQuickAnswersButton = isPrivate ? false : quickAnswersStore.isQuickAnswersEnabled
        self.init(
            windowUUID: windowUUID,
            isPrivate: isPrivate,
            showQuickAnswersButton: showQuickAnswersButton,
            isWorldCupSectionEnabled: isWorldCupSectionEnabled
        )
    }

    private init(
        windowUUID: WindowUUID,
        isPrivate: Bool,
        showQuickAnswersButton: Bool,
        isWorldCupSectionEnabled: Bool
    ) {
        self.windowUUID = windowUUID
        self.isPrivate = isPrivate
        self.showQuickAnswersButton = showQuickAnswersButton
        self.isWorldCupSectionEnabled = isWorldCupSectionEnabled
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case HomepageActionType.initialize:
            return handleInitializeAction(for: state, with: action)
        case QuickAnswersMiddlewareActionType.didInitialize, QuickAnswersMiddlewareActionType.didUpdateSettings:
            return handleQuickAnswersAction(for: state, with: action)
        case WorldCupMiddlewareActionType.didUpdate:
            return handleWorldCupAction(for: state, with: action)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleInitializeAction(for state: HeaderState, with action: Action) -> HeaderState {
        guard action is HomepageAction else {
            return defaultState(from: state)
        }
        return state.copy(isPrivate: false)
    }

    private static func handleQuickAnswersAction(for state: HeaderState, with action: Action) -> HeaderState {
        guard let quickAnswersAction = action as? QuickAnswersMiddlewareAction,
              let showQuickAnswers = quickAnswersAction.isQuickAnswersEnabled
        else {
            return defaultState(from: state)
        }
        return state.copy(
            showQuickAnswersButton: showQuickAnswers && !state.isPrivate
        )
    }

    private static func handleWorldCupAction(for state: HeaderState, with action: Action) -> HeaderState {
        guard let worldCupAction = action as? WorldCupAction else {
            return defaultState(from: state)
        }
        return state.copy(
            isWorldCupSectionEnabled: worldCupAction.shouldShowHomepageWorldCupSection
        )
    }

    static func defaultState(from state: HeaderState) -> HeaderState {
        return HeaderState(
            windowUUID: state.windowUUID,
            isPrivate: state.isPrivate,
            showQuickAnswersButton: state.showQuickAnswersButton,
            isWorldCupSectionEnabled: state.isWorldCupSectionEnabled
        )
    }
}
