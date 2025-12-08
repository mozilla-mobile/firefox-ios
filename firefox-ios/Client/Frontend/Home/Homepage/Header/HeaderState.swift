// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

/// State for the header cell that is used in the homepage header section
struct HeaderState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var isPrivate: Bool
    var showiPadSetup: Bool

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            isPrivate: false,
            showiPadSetup: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        isPrivate: Bool,
        showiPadSetup: Bool
    ) {
        self.windowUUID = windowUUID
        self.isPrivate = isPrivate
        self.showiPadSetup = showiPadSetup
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case HomepageActionType.initialize:
            return handleInitializeAction(for: state, with: action)
        case HomepageActionType.traitCollectionDidChange:
            return handleTraitCollectionDidChangeAction(for: state, with: action)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleInitializeAction(for state: HeaderState, with action: Action) -> HeaderState {
        guard let homepageAction = action as? HomepageAction,
              let showiPadSetup = homepageAction.showiPadSetup
        else {
            return defaultState(from: state)
        }
        return HeaderState(
            windowUUID: state.windowUUID,
            isPrivate: false,
            showiPadSetup: showiPadSetup
        )
    }

    private static func handleTraitCollectionDidChangeAction(for state: HeaderState, with action: Action) -> HeaderState {
        guard let homepageAction = action as? HomepageAction,
              let showiPadSetup = homepageAction.showiPadSetup
        else {
            return defaultState(from: state)
        }
        return HeaderState(
            windowUUID: state.windowUUID,
            isPrivate: state.isPrivate,
            showiPadSetup: showiPadSetup
        )
    }

    static func defaultState(from state: HeaderState) -> HeaderState {
        return HeaderState(
            windowUUID: state.windowUUID,
            isPrivate: state.isPrivate,
            showiPadSetup: state.showiPadSetup
        )
    }
}
